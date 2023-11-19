const vec = @import("../vec.zig");
const ray = @import("../ray.zig");

const Self = @This();
const Point3 = vec.Point3;
const Ray = ray.Ray;

const Hittable = @import("hittable.zig");
const HitRecord = Hittable.HitRecord;

center: Point3,
radius: f64,

pub fn hit(self: *Self, r: Ray, ray_tmin: f64, ray_tmax: f64) ?HitRecord {
    const oc = r.origin.sub(self.center);
    const a = r.direction.lengthSquared();
    const half_b = oc.dot(r.direction);
    const c = oc.lengthSquared() - self.radius * self.radius;

    const discriminant = half_b * half_b - a * c;
    if (discriminant < 0) return null;
    const sqrtd = @sqrt(discriminant);

    // Find the nearest root that lies in the acceptable range
    var root = (-half_b - sqrtd) / a;
    if (root <= ray_tmin or ray_tmax <= root) {
        root = (-half_b + sqrtd) / a;
        if (root <= ray_tmin or ray_tmax <= root)
            return null;
    }

    var rec = HitRecord{
        .p = r.at(root),
        .t = root,
    };

    const outward_normal = rec.p.sub(self.center).divScalar(self.radius);
    rec.setFaceNormal(r, outward_normal);

    return rec;
}

pub fn hittable(self: *Self) Hittable {
    return Hittable.init(self);
}
