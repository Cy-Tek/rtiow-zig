const std = @import("std");
const color = @import("color.zig");
const c = @import("common.zig");

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

    // World
    var world = HittableList.init(allocator);
    defer world.deinit();

    var sphere1 = Sphere{ .center = .{ .z = -1 }, .radius = 0.5 };
    var sphere2 = Sphere{ .center = .{ .y = -100.5, .z = -1 }, .radius = 100 };

    try world.add(sphere1.hittable());
    try world.add(sphere2.hittable());

    // Render the image
    var camera = Camera.init(16.0 / 9.0, 400, 100);
    try camera.render(&world);
}
