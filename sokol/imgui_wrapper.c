
#include "imgui_wrapper.h"
#include "c/sokol_defines.h"
#include "c/sokol_app.h"
#include "c/sokol_gfx.h"

#define CIMGUI_DEFINE_ENUMS_AND_STRUCTS
#include "cimgui.h"
#include "c/sokol_imgui.h"

void imgui_wrapper_setup() {
    simgui_setup(&(simgui_desc_t){ 0 });
}

void imgui_wrapper_new_frame() {
    simgui_new_frame(&(simgui_frame_desc_t){
        .width = sapp_width(),
        .height = sapp_height(),
        .delta_time = sapp_frame_duration(),
        .dpi_scale = sapp_dpi_scale(),
    });
}

void imgui_wrapper_render() {
    simgui_render();
}

void imgui_wrapper_handle_event(const void* ev) {
    simgui_handle_event((const sapp_event*)ev);
}

void imgui_wrapper_shutdown() {
    simgui_shutdown();
}
