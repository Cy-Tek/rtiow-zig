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

    const ground_material = Diffuse.init(0.5, 0.5, 0.5);
    try world.add_sphere(Sphere{ .center = Point3{ .y = -1000 }, .mat = ground_material, .radius = 1000 });

    for (0..22) |a| {
        for (0..22) |b| {
            const f_a = @as(f64, @floatFromInt(a)) - 11;
            const f_b = @as(f64, @floatFromInt(b)) - 11;
            const choose_mat = c.random.float();
            const center = Point3{
                .x = f_a + (0.9 * c.random.float()),
                .y = 0.2,
                .z = f_b + (0.9 * c.random.float()),
            };

            const mat = if (center.sub(Point3{ .x = 4, .y = 0.2, .z = 0 }).length() > 0.9) blk: {
                if (choose_mat < 0.8) {
                    const albedo = Color.random().mul(Color.random());
                    break :blk Diffuse.init(albedo.x, albedo.y, albedo.z);
                } else if (choose_mat < 0.95) {
                    const albedo = Color.randomInRange(0.5, 1);
                    const fuzz = c.random.floatInRange(0, 0.5);
                    break :blk Metal.init(albedo, fuzz);
                } else break :blk Dielectric.init(1.5);
            } else continue;

            try world.add_sphere(Sphere{ .center = center, .mat = mat, .radius = 0.2 });
        }
    }

    const material_1 = Dielectric.init(1.5);
    try world.add_sphere(Sphere{ .center = Point3{ .y = 1 }, .mat = material_1, .radius = 1 });

    const material_2 = Diffuse.init(0.4, 0.2, 0.1);
    try world.add_sphere(Sphere{ .center = Point3{ .x = -4, .y = 1 }, .mat = material_2, .radius = 1 });

    const material_3 = Metal.init(Color{ .x = 0.7, .y = 0.6, .z = 0.5 }, 0);
    try world.add_sphere(Sphere{ .center = Point3{ .x = 4, .y = 1 }, .mat = material_3, .radius = 1 });

    // Render the image
    var camera = Camera.init(
        16.0 / 9.0,
        1200,
        100,
        20,
        Point3{ .x = 13, .y = 2, .z = 3 },
        Point3{ .x = 0, .y = 0, .z = 0 },
        Vec3{ .x = 0, .y = -1, .z = 0 },
        0.6,
        10.0,
    );
    camera.max_depth = 50;

    try camera.render(world);
}
