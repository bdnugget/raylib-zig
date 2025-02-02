// Port of https://github.com/raysan5/raylib/blob/master/examples/textures/textures_sprite_anim.c to zig

const std = @import("std");
const rl = @import("raylib");

const MAX_FRAME_SPEED = 15;
const MIN_FRAME_SPEED = 1;

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initAudioDevice(); // Initialize audio device
    rl.initWindow(screenWidth, screenHeight, "raylib [texture] example - sprite anim");

    // NOTE: Textures MUST be loaded after Window initialization (OpenGL context is required)
    const scarfy: rl.Texture = rl.Texture.init("resources/textures/scarfy.png"); // Texture loading

    const position = rl.Vector2{ .x = 350.0, .y = 280.0 };
    var frameRec = rl.Rectangle{ .x = 0.0, .y = 0.0, .width = @as(f32, @floatFromInt(@divFloor(scarfy.width, 6))), .height = @as(f32, @floatFromInt(scarfy.height)) };
    var currentFrame: u8 = 0;

    var framesCounter: u8 = 0;
    var framesSpeed: u8 = 8; // Number of spritesheet frames shown by second

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        framesCounter += 1;

        if (framesCounter >= (60 / framesSpeed)) {
            framesCounter = 0;
            currentFrame += 1;

            if (currentFrame > 5) currentFrame = 0;

            frameRec.x = @as(f32, @floatFromInt(currentFrame)) * @as(f32, @floatFromInt(@divFloor(scarfy.width, 6)));
        }

        // Control frames speed
        if (rl.isKeyPressed(rl.KeyboardKey.key_right)) {
            framesSpeed += 1;
        } else if (rl.isKeyPressed(rl.KeyboardKey.key_left)) {
            framesSpeed -= 1;
        }

        if (framesSpeed > MAX_FRAME_SPEED) {
            framesSpeed = MAX_FRAME_SPEED;
        } else if (framesSpeed < MIN_FRAME_SPEED) {
            framesSpeed = MIN_FRAME_SPEED;
        }

        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();

        rl.clearBackground(rl.Color.ray_white);

        rl.DrawTexture(scarfy, 15, 40, rl.WHITE);
        rl.DrawRectangleLines(15, 40, scarfy.width, scarfy.height, rl.LIME);
        rl.DrawRectangleLines(15 + @as(i32, @intFromFloat(frameRec.x)), 40 + @as(i32, @intFromFloat(frameRec.y)), @as(i32, @intFromFloat(frameRec.width)), @as(i32, @intFromFloat(frameRec.height)), rl.RED);

        rl.drawText("FRAME SPEED: ", 165, 210, 10, rl.Color.dark_gray);
        rl.drawText(rl.textFormat("%02i FPS", .{framesSpeed}), 575, 210, 10, rl.Color.dark_gray);
        rl.drawText("PRESS RIGHT/LEFT KEYS to CHANGE SPEED!", 290, 240, 10, rl.Color.dark_gray);

        for ([_]u32{0} ** MAX_FRAME_SPEED, 0..) |_, i| {
            if (i < framesSpeed) {
                rl.DrawRectangle(250 + 21 * @as(c_int, @intCast(i)), 205, 20, 20, rl.RED);
            }
            rl.DrawRectangleLines(250 + 21 * @as(c_int, @intCast(i)), 205, 20, 20, rl.MAROON);
        }

        scarfy.drawRec(frameRec, position, rl.Color.white); // Draw part of the texture

        rl.drawText("(c) Scarfy sprite by Eiden Marsal", screenWidth - 200, screenHeight - 20, 10, rl.Color.gray);

        rl.endDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    rl.unloadTexture(scarfy); // Texture unloading

    rl.closeWindow(); // Close window and OpenGL context
    //--------------------------------------------------------------------------------------
}
