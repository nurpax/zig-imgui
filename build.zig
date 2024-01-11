const std = @import("std");
const builtin = @import("builtin");
const path = std.fs.path;

pub const Backend = enum {
    auto, // Windows: D3D11, macOS/iOS: Metal, otherwise: GL
    d3d11,
    metal,
    gl,
    gles2,
    gles3,
    wgpu,
};

pub fn build(b: *std.Build) void {
    // Remove the default install and uninstall steps
    b.top_level_steps = .{};

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const sokol = b.addModule("sokol", .{ .root_source_file = .{ .path = "sokol/sokol.zig" } });

    const lib_opts = .{
        .name = "sokol",
        .target = target,
        .optimize = optimize,
    };

    const lib = b.addStaticLibrary(lib_opts);

    lib.addIncludePath(.{ .path = "zig-imgui" });
    lib.addIncludePath(.{ .path = "sokol" });
    lib.addIncludePath(.{ .path = "sokol/c" });

    const csources = [_][]const u8{
        "sokol/c/sokol_app.c",
        "sokol/c/sokol_gfx.c",
        "sokol/c/sokol_time.c",
        "sokol/c/sokol_audio.c",
        "sokol/c/sokol_gl.c",
        "sokol/c/sokol_debugtext.c",
        "sokol/c/sokol_shape.c",
        "sokol/c/sokol_log.c",
        "sokol/c/sokol_imgui.cpp",
        "sokol/imgui_wrapper.c",
    };
    const backend: Backend = if (target.result.os.tag == .macos) .metal else if (target.result.os.tag == .windows) .d3d11 else .gl;
    const backend_option = switch (backend) {
        .d3d11 => "-DSOKOL_D3D11",
        .metal => "-DSOKOL_METAL",
        .gl => "-DSOKOL_GLCORE33",
        .gles2 => "-DSOKOL_GLES2",
        .gles3 => "-DSOKOL_GLES3",
        .wgpu => "-DSOKOL_WGPU",
        else => unreachable,
    };

    inline for (csources) |csrc| {
        lib.addCSourceFile(.{ .file = .{ .path = csrc }, .flags = &[_][]const u8{ "-DIMPL", backend_option } });
    }
    if (target.result.os.tag == .linux) {
        lib.linkSystemLibrary("X11");
        lib.linkSystemLibrary("Xi");
        lib.linkSystemLibrary("Xcursor");
        lib.linkSystemLibrary("GL");
        lib.linkSystemLibrary("asound");
    } else if (target.result.os.tag == .windows) {
        lib.linkSystemLibrary("kernel32");
        lib.linkSystemLibrary("user32");
        lib.linkSystemLibrary("gdi32");
        lib.linkSystemLibrary("ole32");
        lib.linkSystemLibrary("d3d11");
        lib.linkSystemLibrary("dxgi");
    }

    // Add imgui files
    lib.addCSourceFile(.{
        .file = .{ .path = "zig-imgui/cimgui_unity.cpp" },
        .flags = &[_][]const u8{
            "-fno-sanitize=undefined",
            "-ffunction-sections",
        },
    });
    lib.linkLibCpp();

    const imgui = b.addModule("imgui", .{ .root_source_file = .{ .path = "zig-imgui/imgui.zig" } });
    imgui.linkLibrary(lib);
    sokol.linkLibrary(lib);

    // TODO not sure why this is necessary
    sokol.addIncludePath(.{ .path = "sokol" });
}
