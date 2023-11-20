const std = @import("std");

pub const infinity = std.math.inf(f64);
pub const pi = std.math.pi;
pub const Interval = @import("interval.zig");

pub const Random = struct {
    prng: std.rand.DefaultPrng,

    pub fn init(seed: u64) Random {
        return .{
            .prng = std.rand.DefaultPrng.init(seed),
        };
    }

    pub fn float(self: *Random) f64 {
        return self.prng.random().float(f64);
    }

    pub fn floatInRange(self: *Random, min: f64, max: f64) f64 {
        return min + (max - min) * self.float();
    }
};

pub usingnamespace @import("ray.zig");
pub usingnamespace @import("vec.zig");
