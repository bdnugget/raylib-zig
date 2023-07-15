// raylib-zig (c) Nikolas Wipper 2023

const rl = @import("raylib");
const rlm = @import("raylib-math");

const MAX_BUILDINGS = 100;

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;

    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - 2d camera");

    var player = rl.Rectangle{ .x = 400, .y = 280, .width = 40, .height = 40 };
    var buildings: [MAX_BUILDINGS]rl.Rectangle = undefined;
    var buildColors: [MAX_BUILDINGS]rl.Color = undefined;

    var spacing: i32 = 0;

    for (buildings, 0..) |_, i| {
        buildings[i].width = @as(f32, @floatFromInt(rl.GetRandomValue(50, 200)));
        buildings[i].height = @as(f32, @floatFromInt(rl.GetRandomValue(100, 800)));
        buildings[i].y = screenHeight - 130 - buildings[i].height;
        buildings[i].x = @as(f32, @floatFromInt(-6000 + spacing));

        spacing += @as(i32, @intFromFloat(buildings[i].width));

        buildColors[i] = rl.Color{ .r = @as(u8, @intCast(rl.GetRandomValue(200, 240))), .g = @as(u8, @intCast(rl.GetRandomValue(200, 240))), .b = @as(u8, @intCast(rl.GetRandomValue(200, 250))), .a = 255 };
    }

    var camera = rl.Camera2D{
        .target = rl.Vector2.init(player.x + 20, player.y + 20),
        .offset = rl.Vector2.init(screenWidth / 2, screenHeight / 2),
        .rotation = 0,
        .zoom = 1,
    };

    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second
    //--------------------------------------------------------------------------------------

    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------

        // Player movement
        if (rl.isKeyDown(rl.KeyboardKey.key_right)) {
            player.x += 2;
        } else if (rl.isKeyDown(rl.KeyboardKey.key_left)) {
            player.x -= 2;
        }

        // Camera target follows player
        camera.target = rl.Vector2.init(player.x + 20, player.y + 20);

        // Camera rotation controls
        if (rl.isKeyDown(rl.KeyboardKey.key_a)) {
            camera.rotation -= 1;
        } else if (rl.isKeyDown(rl.KeyboardKey.key_s)) {
            camera.rotation += 1;
        }

        // Limit camera rotation to 80 degrees (-40 to 40)
        camera.rotation = rlm.clamp(camera.rotation, -40, 40);

        // Camera zoom controls
        camera.zoom += rl.getMouseWheelMove() * 0.05;

        camera.zoom = rlm.clamp(camera.zoom, 0.1, 3.0);

        // Camera reset (zoom and rotation)
        if (rl.isKeyPressed(rl.KeyboardKey.key_r)) {
            camera.zoom = 1.0;
            camera.rotation = 0.0;
        }
        //----------------------------------------------------------------------------------

        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();

        rl.clearBackground(rl.Color.ray_white);

        camera.begin();

        rl.drawRectangle(-6000, 320, 13000, 8000, rl.Color.dark_gray);

        for (buildings, 0..) |building, i| {
            rl.DrawRectangleRec(building, buildColors[i]);
        }

        rl.drawRectangleRec(player, rl.Color.red);

        rl.DrawLine(@as(c_int, @intFromFloat(camera.target.x)), -screenHeight * 10, @as(c_int, @intFromFloat(camera.target.x)), screenHeight * 10, rl.GREEN);
        rl.DrawLine(-screenWidth * 10, @as(c_int, @intFromFloat(camera.target.y)), screenWidth * 10, @as(c_int, @intFromFloat(camera.target.y)), rl.GREEN);

        camera.end();

        rl.drawText("SCREEN AREA", 640, 10, 20, rl.Color.red);

        rl.drawRectangle(0, 0, screenWidth, 5, rl.Color.red);
        rl.drawRectangle(0, 5, 5, screenHeight - 10, rl.Color.red);
        rl.drawRectangle(screenWidth - 5, 5, 5, screenHeight - 10, rl.Color.red);
        rl.drawRectangle(0, screenHeight - 5, screenWidth, 5, rl.Color.red);

        rl.drawRectangle(10, 10, 250, 113, rl.Color.sky_blue.fade(0.5));
        rl.drawRectangleLines(10, 10, 250, 113, rl.Color.blue);

        rl.drawText("Free 2d camera controls:", 20, 20, 10, rl.Color.black);
        rl.drawText("- Right/Left to move Offset", 40, 40, 10, rl.Color.dark_gray);
        rl.drawText("- Mouse Wheel to Zoom in-out", 40, 60, 10, rl.Color.dark_gray);
        rl.drawText("- A / S to Rotate", 40, 80, 10, rl.Color.dark_gray);
        rl.drawText("- R to reset Zoom and Rotation", 40, 100, 10, rl.Color.dark_gray);

        rl.endDrawing();
        //----------------------------------------------------------------------------------
    }

    // De-Initialization
    //--------------------------------------------------------------------------------------
    rl.closeWindow(); // Close window and OpenGL context
    //--------------------------------------------------------------------------------------
}
