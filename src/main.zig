const std = @import("std");
const color = @import("color.zig");
const c = @import("common.zig");

const material = @import("material.zig");
const Material = material.Material;
const Diffuse = material.Lambertian;
const Metal = material.Metal;
const Dielectric = material.Dielectric;

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

    const material_ground = Diffuse.init(0.8, 0.8, 0);
    const material_center = Diffuse.init(0.1, 0.2, 0.5);
    const material_left = Dielectric.init(1.5);
    const material_right = Metal.init(.{ .x = 0.8, .y = 0.6, .z = 0.2 }, 0);

    const spheres = [_]Sphere{
        Sphere.init(.{ .z = -1 }, 0.5, material_center),
        Sphere.init(.{ .y = -100.5, .z = -1 }, 100, material_ground),
        Sphere.init(.{ .x = -1, .z = -1 }, 0.5, material_left),
        Sphere.init(.{ .x = -1, .z = -1 }, -0.4, material_left),
        Sphere.init(.{ .x = 1, .z = -1 }, 0.5, material_right),
    };

    for (spheres) |sphere| {
        try world.add_sphere(sphere);
    }

    // Render the image
    var camera = Camera.init(16.0 / 9.0, 400, 100);
    camera.max_depth = 50;

    try camera.render(world);
}
