// A raylib port of https://github.com/raysan5/raylib/blob/master/examples/shaders/shaders_texture_outline.c

const rl = @import("raylib");
const std = @import("std");

//------------------------------------------------------------------------------------
// Program main entry point
//------------------------------------------------------------------------------------
pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "raylib [shaders] example - Apply an outline to a texture");

    const texture: rl.Texture = rl.Texture.init("resources/textures/fudesumi.png");

    const shdrOutline: rl.Shader = rl.LoadShader(0, rl.TextFormat("resources/shaders/glsl330/outline.fs", @as(c_int, @intCast(330))));

    var outlineSize: f32 = 2.0;
    const outlineColor = [4]f32{ 1.0, 0.0, 0.0, 1.0 }; // Normalized RED color
    const textureSize = rl.Vector2{ .x = @as(f32, @floatFromInt(texture.width)), .y = @as(f32, @floatFromInt(texture.height)) };

    // Get shader locations
    const outlineSizeLoc = rl.getShaderLocation(shdrOutline, "outlineSize");
    const outlineColorLoc = rl.getShaderLocation(shdrOutline, "outlineColor");
    const textureSizeLoc = rl.getShaderLocation(shdrOutline, "textureSize");

    // Set shader values (they can be changed later)
    rl.SetShaderValue(shdrOutline, outlineSizeLoc, &outlineSize, @intFromEnum(rl.ShaderUniformDataType.SHADER_UNIFORM_FLOAT));
    rl.SetShaderValue(shdrOutline, outlineColorLoc, &outlineColor, @intFromEnum(rl.ShaderUniformDataType.SHADER_UNIFORM_VEC4));
    rl.SetShaderValue(shdrOutline, textureSizeLoc, &textureSize, @intFromEnum(rl.ShaderUniformDataType.SHADER_UNIFORM_VEC2));

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        outlineSize += rl.getMouseWheelMove();
        if (outlineSize < 1.0) outlineSize = 1.0;

        rl.SetShaderValue(shdrOutline, outlineSizeLoc, &outlineSize, @intFromEnum(rl.ShaderUniformDataType.SHADER_UNIFORM_FLOAT));
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();

        rl.clearBackground(rl.Color.ray_white);

        rl.beginShaderMode(shdrOutline);

        texture.draw(@divFloor(rl.getScreenWidth(), 2) - @divFloor(texture.width, 2), -30, rl.Color.white);

        rl.endShaderMode();

        rl.drawText("Shader-based\ntexture\noutline", 10, 10, 20, rl.Color.gray);

        rl.DrawText(rl.TextFormat("Outline size: %i px", @as(i32, @intFromFloat(outlineSize))), 10, 120, 20, rl.MAROON);

        rl.drawFPS(710, 10);

        rl.endDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    rl.unloadTexture(texture);
    rl.unloadShader(shdrOutline);

    rl.closeWindow(); // Close window and OpenGL context
    //--------------------------------------------------------------------------------------

}
