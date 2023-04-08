const c = @cImport({
    @cInclude("imgui_wrapper.h");
});

pub const sapp = @import("app.zig");

pub fn setup() void {
    c.imgui_wrapper_setup();
}

pub fn newFrame() void {
    c.imgui_wrapper_new_frame();
}

pub fn render() void {
    c.imgui_wrapper_render();
}

pub fn handleEvent(e: [*c]const sapp.Event) void {
    c.imgui_wrapper_handle_event(e);
}

pub fn shutdown() void {
    c.imgui_wrapper_shutdown();
}
