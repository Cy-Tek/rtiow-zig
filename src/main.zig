const std = @import("std");
const color = @import("color.zig");
const c = @import("common.zig");

const material = @import("material.zig");
const Material = material.Material;
const Diffuse = material.Lambertian;
const Metal = material.Metal;

const Camera = @import("camera.zig");
const Hittable = @import("objects/hittable.zig");
const HittableList = @import("objects/hittable_list.zig");
const Sphere = @import("objects/sphere.zig");
const Ray = c.Ray;
const Color = color.Color;
const Vec3 = c.Vec3;
const Point3 = c.Point3;
const Interval = c.Interval;

pub fn main() !void {
    // Allocator setup
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) @panic("TEST FAIL");
    }

    // Initialize random number generator
    c.random = c.Random.init(@intCast(std.time.timestamp()));

    // World
    var world = HittableList.init(allocator);
    defer world.deinit();

    const material_ground = Diffuse.init(.{ .x = 0.8, .y = 0.8, .z = 0 });
    const material_center = Diffuse.init(.{ .x = 0.7, .y = 0.3, .z = 0.3 });
    const material_left = Metal.init(.{ .x = 0.8, .y = 0.8, .z = 0.8 }, 0.3);
    const material_right = Metal.init(.{ .x = 0.8, .y = 0.6, .z = 0.2 }, 1);

    var sphere1 = Sphere{ .center = .{ .z = -1 }, .radius = 0.5, .mat = material_center };
    var sphere2 = Sphere{ .center = .{ .y = -100.5, .z = -1 }, .radius = 100, .mat = material_ground };
    var sphere3 = Sphere{ .center = .{ .x = -1, .z = -1 }, .radius = 0.5, .mat = material_left };
    var sphere4 = Sphere{ .center = .{ .x = 1, .z = -1 }, .radius = 0.5, .mat = material_right };

    try world.add(sphere1.hittable());
    try world.add(sphere2.hittable());
    try world.add(sphere3.hittable());
    try world.add(sphere4.hittable());

    // Render the image
    var camera = Camera.init(16.0 / 9.0, 1920, 500);
    camera.max_depth = 50;

    try camera.render(&world);
}
