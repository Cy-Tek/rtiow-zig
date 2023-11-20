const c = @import("common.zig");
const Interval = c.Interval;
pub const Color = c.Vec3;

const intensity = Interval.init(0.000, 0.999);

pub fn write(writer: anytype, color: Color, samples_per_pixel: u32) !void {
    const scale: f64 = 1.0 / @as(f64, @floatFromInt(samples_per_pixel));
    const rgb = color.mulScalar(scale);
    try writer.print("{d:.0} {d:.0} {d:.0}\n", .{
        intensity.clamp(rgb.x) * 255,
        intensity.clamp(rgb.y) * 255,
        intensity.clamp(rgb.z) * 255,
    });
}
