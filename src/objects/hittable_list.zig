const std = @import("std");
const c = @import("../common.zig");

const Interval = c.Interval;
const Ray = c.Ray;
const Sphere = @import("sphere.zig");
const HitRecord = @import("hittable.zig").HitRecord;
const HittableList = @This();
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

spheres: ArrayList(Sphere),

pub fn init(alloc: Allocator) HittableList {
    return .{ .spheres = ArrayList(Sphere).init(alloc) };
}

pub fn add_sphere(self: *HittableList, sphere: Sphere) !void {
    try self.spheres.append(sphere);
}

pub inline fn hit(self: HittableList, r: Ray, ray_t: Interval) ?HitRecord {
    var closest_so_far = ray_t.max;
    var temp_rec: ?HitRecord = null;

    for (self.spheres.items) |*item| {
        if (item.hit(r, Interval.init(ray_t.min, closest_so_far))) |rec| {
            closest_so_far = rec.t;
            temp_rec = rec;
        }
    }

    return temp_rec;
}

pub fn deinit(self: *HittableList) void {
    self.spheres.deinit();
}
