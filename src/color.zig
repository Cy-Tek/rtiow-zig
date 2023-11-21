const c = @import("common.zig");
const Interval = c.Interval;
pub const Color = c.Vec3;

const intensity = Interval.init(0.000, 0.999);

inline fn linearToGamma(linear_component: f64) f64 {
    return @sqrt(linear_component);
}

pub fn write(writer: anytype, color: Color, samples_per_pixel: u32) !void {
    var r = color.x;
    var g = color.y;
    var b = color.z;

    // Divide the color by the number of samples
    const scale: f64 = 1.0 / @as(f64, @floatFromInt(samples_per_pixel));
    r *= scale;
    g *= scale;
    b *= scale;

    // Apply the linear to gamma transform
    r = linearToGamma(r);
    g = linearToGamma(g);
    b = linearToGamma(b);

    try writer.print("{d:.0} {d:.0} {d:.0}\n", .{
        intensity.clamp(r) * 255,
        intensity.clamp(g) * 255,
        intensity.clamp(b) * 255,
    });
}
