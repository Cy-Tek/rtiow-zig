const std = @import("std");
const c = @import("../common.zig");

const Interval = c.Interval;
const Ray = c.Ray;
const Hittable = @import("hittable.zig");
const HitRecord = Hittable.HitRecord;
const HittableList = @This();
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

objects: ArrayList(Hittable),

pub fn init(alloc: Allocator) HittableList {
    return .{ .objects = ArrayList(Hittable).init(alloc) };
}

pub fn add(self: *HittableList, object: Hittable) !void {
    try self.objects.append(object);
}

pub fn hit(self: *HittableList, r: Ray, ray_t: Interval) ?HitRecord {
    var closest_so_far = ray_t.max;
    var temp_rec: ?HitRecord = null;

    for (self.objects.items) |*item| {
        if (item.hit(r, Interval.init(ray_t.min, closest_so_far))) |rec| {
            closest_so_far = rec.t;
            temp_rec = rec;
        }
    }

    return temp_rec;
}

pub fn deinit(self: *HittableList) void {
    self.objects.deinit();
}

pub fn hittable(self: *HittableList) Hittable {
    return Hittable.init(self);
}
