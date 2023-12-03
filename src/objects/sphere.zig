const c = @import("../common.zig");

const Self = @This();
const Point3 = c.Point3;
const Ray = c.Ray;
const Interval = c.Interval;
const Material = @import("../material.zig").Material;

const Hittable = @import("hittable.zig");
const HitRecord = Hittable.HitRecord;

center: Point3,
radius: f64,
mat: Material,

pub fn init(center: Point3, radius: f64, mat: Material) Self {
    return Self{ .center = center, .radius = radius, .mat = mat };
}

pub inline fn hit(self: *Self, r: Ray, ray_t: c.Interval) ?HitRecord {
    const oc = r.origin.sub(self.center);
    const a = r.direction.lengthSquared();
    const half_b = oc.dot(r.direction);
    const cn = oc.lengthSquared() - self.radius * self.radius;

    const discriminant = half_b * half_b - a * cn;
    if (discriminant < 0) return null;
    const sqrtd = @sqrt(discriminant);

    // Find the nearest root that lies in the acceptable range
    var root = (-half_b - sqrtd) / a;
    if (root <= ray_t.min or ray_t.max <= root) {
        root = (-half_b + sqrtd) / a;
        if (root <= ray_t.min or ray_t.max <= root)
            return null;
    }

    var rec = HitRecord{
        .p = r.at(root),
        .t = root,
        .mat = self.mat,
    };

    const outward_normal = rec.p.sub(self.center).divScalar(self.radius);
    rec.setFaceNormal(r, outward_normal);

    return rec;
}

pub fn hittable(self: *Self) Hittable {
    return Hittable.init(self);
}
