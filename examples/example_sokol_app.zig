const std = @import("std");
const builtin = @import("builtin");

const sokol = @import("sokol");
const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sgapp = sokol.app_gfx_glue;

const print = @import("std").debug.print;

const imgui = @import("imgui");

var pass_action: sg.PassAction = .{};
var show_another_window = false;
var slider_value: f32 = 0;
var clear_color = imgui.Vec4{ 0.45, 0.55, 0.60, 1.00 };
var counter: u32 = 0;

export fn init() void {
    sg.setup(.{ .context = sgapp.context(), .logger = .{ .func = slog.func } });
    pass_action.colors[0] = .{ .action = .CLEAR, .value = .{ .r = 0, .g = 0, .b = 0, .a = 1 } };
    print("Backend: {}\n", .{sg.queryBackend()});

    sokol.imgui.setup();

    // Setup Dear ImGui style
    imgui.StyleColorsDark();
}

export fn frame() void {
    sokol.imgui.newFrame();
    sg.beginDefaultPass(pass_action, sapp.width(), sapp.height());

    // GUI
    // 2. Show a simple window that we create ourselves. We use a Begin/End pair to created a named window.
    {
        _ = imgui.Begin("Hello, world!"); // Create a window called "Hello, world!" and append into it.

        imgui.Text("This is some useful text."); // Display some text (you can use a format strings too)
        _ = imgui.Checkbox("Another Window", &show_another_window);

        _ = imgui.SliderFloat("float", &slider_value, 0.0, 1.0); // Edit 1 float using a slider from 0.0 to 1.0
        _ = imgui.ColorEdit3("clear color", @ptrCast(*[3]f32, &clear_color)); // Edit 3 floats representing a color

        if (imgui.Button("Button")) { // Buttons return true when clicked (most widgets return true when edited/activated)
            counter += 1;
        }

        imgui.SameLine();
        imgui.Text("counter = %d", counter);

        imgui.Text("Application average %.3f ms/frame (%.1f FPS)", 1000.0 / imgui.GetIO().Framerate, imgui.GetIO().Framerate);
        imgui.End();
    }

    sokol.imgui.render();
    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    sokol.imgui.shutdown();
    sg.shutdown();
}

export fn events(event: [*c]const sapp.Event) void {
    sokol.imgui.handleEvent(event);
}

pub fn main() void {
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = events,
        .width = 640,
        .height = 480,
        .icon = .{
            .sokol_default = true,
        },
        .window_title = "imgui test",
        .logger = .{
            .func = slog.func,
        },
        .win32_console_attach = true,
    });
}
