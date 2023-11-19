const std = @import("std");

pub const infinity = std.math.inf(f64);
pub const pi = std.math.pi;
pub const Interval = @import("interval.zig");

pub usingnamespace @import("ray.zig");
pub usingnamespace @import("vec.zig");
