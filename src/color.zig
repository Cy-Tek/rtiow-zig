const vec = @import("vec.zig");
pub const Color = vec.Vec3;

pub fn write(writer: anytype, color: Color) !void {
    const rgb = color.mulScalar(255); // convert from 0.0-1.0 to 0.0-255.999
    try writer.print("{d:.0} {d:.0} {d:.0}\n", .{ rgb.x, rgb.y, rgb.z });
}
