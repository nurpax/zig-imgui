const std = @import("std");
const builtin = @import("builtin");
const path = std.fs.path;
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;

const imgui_build = @import("zig-imgui/imgui_build.zig");

const glslc_command = if (builtin.os.tag == .windows) "tools/win/glslc.exe" else "glslc";

pub fn build(b: *Builder) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    imgui_build.addTestStep(b, "test", optimize, target);

    {
        const exe = exampleExe(b, "example_glfw_vulkan", optimize, target);
        linkGlfw(exe, target);
        linkVulkan(exe, target);
    }
    {
        const exe = exampleExe(b, "example_glfw_opengl3", optimize, target);
        linkGlfw(exe, target);
        linkGlad(exe, target);
    }
    {
        const exe = exampleExe(b, "example_sokol_app", optimize, target);
        linkSokol(exe, target);
    }
}

fn exampleExe(b: *Builder, comptime name: []const u8, optimize: std.builtin.Mode, target: std.zig.CrossTarget) *LibExeObjStep {
    const exe = b.addExecutable(.{ .name = name, .target = target, .optimize = optimize, .root_source_file = .{ .path = "examples/" ++ name ++ ".zig" } });
    imgui_build.link(exe);
    exe.install();

    exe.addAnonymousModule("imgui", .{ .source_file = .{ .path = "zig-imgui/imgui.zig" } });
    exe.addAnonymousModule("sokol", .{ .source_file = .{ .path = "sokol/sokol.zig" } });

    const run_step = b.step(name, "Run " ++ name);
    const run_cmd = exe.run();
    run_step.dependOn(&run_cmd.step);

    return exe;
}

fn linkGlad(exe: *LibExeObjStep, target: std.zig.CrossTarget) void {
    _ = target;
    exe.addIncludePath("examples/include/c_include");
    exe.addCSourceFile("examples/c_src/glad.c", &[_][]const u8{"-std=c99"});
    //exe.linkSystemLibrary("opengl");
}

fn linkGlfw(exe: *LibExeObjStep, target: std.zig.CrossTarget) void {
    if (target.isWindows()) {
        exe.addObjectFile(if (target.getAbi() == .msvc) "examples/lib/win/glfw3.lib" else "examples/lib/win/libglfw3.a");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("shell32");
    } else {
        exe.linkSystemLibrary("glfw");
    }
}

fn linkVulkan(exe: *LibExeObjStep, target: std.zig.CrossTarget) void {
    if (target.isWindows()) {
        exe.addObjectFile("examples/lib/win/vulkan-1.lib");
    } else {
        exe.linkSystemLibrary("vulkan");
    }
}

fn linkSokol(exe: *LibExeObjStep, target: std.zig.CrossTarget) void {
    _ = target;
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
    };
    //const backend = if (lib.target.isDarwin()) .metal else if (lib.target.isWindows()) .d3d11 else .gl;
    const backend = .d3d11;
    std.debug.assert(exe.target.isWindows());
    const backend_option = switch (backend) {
        .d3d11 => "-DSOKOL_D3D11",
        .metal => "-DSOKOL_METAL",
        .gl => "-DSOKOL_GLCORE33",
        .gles2 => "-DSOKOL_GLES2",
        .gles3 => "-DSOKOL_GLES3",
        .wgpu => "-DSOKOL_WGPU",
        else => unreachable,
    };

    for (csources) |csrc| {
        exe.addCSourceFile(csrc, &[_][]const u8{ "-DIMPL", backend_option });
    }
    if (exe.target.isLinux()) {
        exe.linkSystemLibrary("X11");
        exe.linkSystemLibrary("Xi");
        exe.linkSystemLibrary("Xcursor");
        exe.linkSystemLibrary("GL");
        exe.linkSystemLibrary("asound");
    } else if (exe.target.isWindows()) {
        exe.linkSystemLibrary("kernel32");
        exe.linkSystemLibrary("user32");
        exe.linkSystemLibrary("gdi32");
        exe.linkSystemLibrary("ole32");
        exe.linkSystemLibrary("d3d11");
        exe.linkSystemLibrary("dxgi");
    }
}
