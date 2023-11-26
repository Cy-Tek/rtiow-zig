const c = @import("../common.zig");
const Material = @import("../material.zig").Material;

const HittableList = @import("./hittable_list.zig");
const Sphere = @import("./sphere.zig");
const Interval = c.Interval;
const Point3 = c.Point3;
const Vec3 = c.Vec3;
const Ray = c.Ray;

pub const HitRecord = struct {
    p: Point3,
    t: f64,
    mat: Material,
    normal: Vec3 = undefined,
    front_face: bool = undefined,

    pub fn setFaceNormal(self: *HitRecord, r: Ray, outward_normal: Vec3) void {
        // Sets the hit record normal vector
        // NOTE: the parameter `outword_normal` is assumed to have unit length

        self.front_face = r.direction.dot(outward_normal) < 0;
        self.normal = if (self.front_face) outward_normal else outward_normal.neg();
    }
};
