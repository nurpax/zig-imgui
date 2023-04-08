#pragma once

#include "c/sokol_defines.h"
#include "c/sokol_app.h"

void imgui_wrapper_setup();
void imgui_wrapper_new_frame();
void imgui_wrapper_render();
void imgui_wrapper_handle_event(const void* ev);
void imgui_wrapper_shutdown();
