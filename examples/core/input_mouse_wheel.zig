// raylib-zig (c) Nikolas Wipper 2023

const rl = @import("raylib");
const std = @import("std");

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - basic window");

    var boxPositionY: f32 = screenHeight / 2 - 40;
    var scrollSpeed: f32 = 4; // Scrolling speed in pixels

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        boxPositionY -= (rl.getMouseWheelMove() * scrollSpeed);
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();

        rl.clearBackground(rl.Color.white);

        rl.drawRectangle(screenWidth / 2 - 40, @as(i32, @intFromFloat(boxPositionY)), 80, 80, rl.Color.maroon);

        rl.DrawRectangle(screenWidth / 2 - 40, @as(c_int, @intFromFloat(boxPositionY)), 80, 80, rl.MAROON);

        rl.DrawText("Use mouse wheel to move the cube up and down!", 10, 10, 20, rl.GRAY);
        rl.DrawText(rl.TextFormat("Box position Y: %03i", @as(c_int, @intFromFloat(boxPositionY))), 10, 40, 20, rl.LIGHTGRAY);

        rl.endDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    rl.closeWindow(); // Close window and OpenGL context
    //--------------------------------------------------------------------------------------
}
