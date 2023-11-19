const std = @import("std");
const infinity = std.math.inf(f64);
const Interval = @This();

const empty = Interval.init(infinity, -infinity);
const universe = Interval.init(-infinity, infinity);

min: f64 = infinity,
max: f64 = -infinity,

pub fn init(min: f64, max: f64) Interval {
    return .{
        .min = min,
        .max = max,
    };
}

pub fn contains(self: Interval, x: f64) bool {
    return self.min <= x and x <= self.max;
}

pub fn surrounds(self: Interval, x: f64) bool {
    return self.min < x and x < self.max;
}
