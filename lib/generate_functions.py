import re

"""
Automatic utility for generating raylib function headers.
"""

C_TO_ZIG = {
    "bool": "bool",
    "char": "u8",
    "double": "f64",
    "float": "f32",
    "int": "c_int",
    "long": "c_long",
    "unsigned char": "u8",
    "unsigned int": "c_uint",
}

ZIGGIFY = {
    "c_int": "i32",
    "c_long": "i64",
    "c_uint": "u32"
}


# Some c types have a different sizes on different systems
# and zig knows that so we tell it to get the system specific size for us
def c_to_zig_type(c: str) -> str:
    const = "const " if "const " in c else ""
    c = c.replace("const ", "")
    z = C_TO_ZIG.get(c)

    if z is not None:
        return const + z

    return const + c


def ziggify_type(name: str, t: str) -> str:
    NO_STRINGS = ["data", "fileData", "compData"]

    single = ["value", "ptr", "bytesRead", "compDataSize", "dataSize", "outputSize", "camera", "collisionPoint", "image", "colorCount", "dst", "texture", "srcPtr", "dstPtr", "count", "codepointSize", "utf8Size", "position", "mesh", "materialCount", "material", "model", "animCount", "wave", "v1", "v2", "outAxis", "outAngle"]
    multi = ["data", "compData", "points", "frames", "fileData", "colors", "pixels", "fontChars", "chars", "recs", "codepoints", "textList", "transforms", "animations", "samples", "LoadImageColors", "LoadImagePalette", "LoadFontData", "LoadCodepoints", "TextSplit", "LoadMaterials", "LoadModelAnimations", "LoadWaveSamples"]

    if t.startswith("[*c]") and name not in single and name not in multi:
        if (t == "[*c]const u8" or t == "[*c]u8") and name not in NO_STRINGS: # strings are multis
            pass
        else:
            raise ValueError(f"{t} {name} not classified")
    
    pre = ""
    while t.startswith("[*c]"):
        t = t[4:]
        if name in single:
            pre += "*"
        else:
            pre += "[]"
    
    if t in ZIGGIFY:
        t = ZIGGIFY[t]

    return pre + t


def add_namespace_to_type(t: str) -> str:
    pre = ""
    while t.startswith("[*c]"):
        t = t[4:]
        pre += "[*c]"
    
    if t.startswith("const "):
        t = t[6:]
        pre += "const "

    if t[0].isupper():
        t = "rl." + t
    
    if t in ["float3", "float16"]:
        t = "rlm." + t

    return pre + t


def make_return_cast(source_type: str, dest_type: str, inner: str) -> str:
    if source_type == dest_type:
        return inner
    if source_type in ["[*c]const u8", "[*c]u8"]:
        return f"std.mem.span({inner})"
    
    if source_type in ZIGGIFY:
        return f"@as({dest_type}, {inner})"

    # These all have to be done manually because their sizes depend on the function arguments
    if source_type in ["[*c]Color", "[*c]GlyphInfo", "[*c]c_int", "[*c][*c]const u8", "[*c]Material", "[*c]ModelAnimation", "[*c]f32"]:
        return None
    else:
        raise ValueError(f"Don't know what to do {source_type} {dest_type} {inner}")


def fix_pointer(name: str, t: str):
    pre = ""
    while name.startswith("*"):
        name = name[1:]
        pre += "[*c]"
    t = pre + t

    if t == "[*c]const void":
        t = "*const anyopaque"
    elif t == "[*c]void":
        t = "*anyopaque"
    elif len(pre) == 0:
        t = t.replace("const ", "")
    return name, t


def fix_enums(arg_name, arg_type, func_name):
    # Hacking specific enums in here
    # Raylib doesn't use the enums but rather the resulting ints
    if arg_type == "int" or arg_type == "unsigned int":
        if arg_name == "key":
            arg_type = "KeyboardKey"
        elif arg_name == "button":
            if "Gamepad" in func_name:
                arg_type = "GamepadButton"
            else:
                arg_type = "MouseButton"
        elif arg_name == "mode" and func_name == "UpdateCamera":
            arg_type = "CameraMode"
        elif arg_name == "gesture":
            arg_type = "Gesture"
        elif arg_name == "flags" and func_name in ["SetWindowState", "ClearWindowState", "SetConfigFlags"]:
            arg_type = "ConfigFlags"
        elif arg_name == "logLevel":
            arg_type = "TraceLogLevel"
    return arg_type


def convert_name_case(name):
    return name[:1].lower() + name[1:] if name else ''


def parse_header(header_name: str, output_file: str, ext_file: str, prefix: str, *args: str):
    header = open(header_name, mode="r")
    ext_heads = []
    zig_funcs = []
    zig_types = set()

    leftover = ""

    for line in header.readlines():
        if line.startswith("typedef struct"):
            zig_types.add(line.split(" ")[2])
        elif line.startswith("typedef enum"):
            # don't trip the general typedef case
            pass
        elif line.startswith("typedef "):
            zig_types.add(line.split(" ")[2].replace(";", "").strip())

        if not line.startswith(prefix):
            continue

        line = line.split(";", 1)[0]

        if leftover:
            line = leftover + line
            leftover = ""

        line = line.replace("* ", " *")

        line = line.replace(",", ", ")
        line = line.replace("  ", " ")

        # each (.*) is some variable value
        result = re.search(
            prefix + "(.*) (.*)start_arg(.*)end_arg(.*)",
            line.replace("(", "start_arg").replace(")", "end_arg"),
        )

        if result is None:
            leftover += line
            continue

        # get whats in the (.*)'s
        return_type = result.group(1)
        func_name = result.group(2)
        arguments = result.group(3)

        if func_name == "SetTraceLogCallback":
            continue

        return_type = c_to_zig_type(return_type)
        func_name, return_type = fix_pointer(func_name, return_type)

        if func_name == "GetKeyPressed":
            return_type = "KeyboardKey"
        elif func_name == "GetGamepadButtonPressed":
            return_type = "GamepadButton"
        elif func_name == "GetGestureDetected":
            return_type = "Gesture"

        zig_c_arguments = []
        zig_arguments = []
        zig_call_args = []
        for arg in arguments.split(", "):
            if arg == "void":
                break
            if arg == "...":
                zig_c_arguments.append("...")
                continue
            # everything but the last element (for stuff like "const Vector3")
            arg_type = " ".join(arg.split(" ")[0:-1])
            arg_name = arg.split(" ")[-1]  # last element should be the name
            arg_type = fix_enums(arg_name, arg_type, func_name)

            if arg_name == "type": arg_name = "ty"

            arg_type = c_to_zig_type(arg_type)
            arg_name, arg_type = fix_pointer(arg_name, arg_type)
            zig_type = ziggify_type(arg_name, arg_type)

            is_rl_type = arg_type[0].isupper()

            zig_types.add(arg_type)
            zig_c_arguments.append(arg_name + ": " + add_namespace_to_type(arg_type))  # put everything together
            zig_arguments.append(arg_name + ": " + zig_type)
            if arg_type == zig_type:
                zig_call_args.append(arg_name)
            else:
                if arg_type.startswith("[*c]"):
                    zig_call_args.append(f"@ptrCast({arg_type}, {arg_name})")
                else:
                    zig_call_args.append(f"@as({arg_type}, {arg_name})")
        zig_c_arguments = ", ".join(zig_c_arguments)

        ext_ret = add_namespace_to_type(return_type)
        ext_heads.append(f"pub extern \"c\" fn {func_name}({zig_c_arguments}) {ext_ret};")

        zig_name = convert_name_case(func_name)

        # Todo: ziggify return type
        zig_arguments = ", ".join(zig_arguments)
        zig_heads.append(
            "pub extern fn "
            + func_name
            + "("
            + zig_arguments
            + ") "
            + return_type
            + ";"
        )

    prelude = str()

    ext_header = open(ext_file, mode="w")
    print(ext_prelude, file=ext_header)
    print("\n".join(ext_heads), file=ext_header)

    zig_header = open(output_file, mode="w")
    print(prelude, file=zig_header)
    print("\n\n".join(zig_funcs), file=zig_header)


if __name__ == "__main__":
    parse_header(
        "../raylib/src/raylib.h", "raylib-zig.zig", "RLAPI ", "raylib-zig-types.zig"
    )
    parse_header(
        "../raylib/src/raymath.h",
        "raylib-zig-math.zig",
        "RMAPI ",
        "raylib-zig-math-prelude.zig",
    )
