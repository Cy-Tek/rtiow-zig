const vec = @import("vec.zig");
const Vec3 = vec.Vec3;
const Point3 = vec.Point3;

pub const Ray = struct {
    origin: Point3,
    direction: Vec3,

    pub fn at(self: Ray, t: f64) Point3 {
        return self.direction.mulScalar(t).add(self.origin);
    }
};
