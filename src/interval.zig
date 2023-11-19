const std = @import("std");
const infinity = std.math.inf;

pub const Interval = struct {
    const empty = Interval.init(infinity(f64), -infinity(f64));
    const universe = Interval.init(-infinity(f64), infinity(f64));

    min: f64 = infinity(f64),
    max: f64 = -infinity(f64),

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
};
