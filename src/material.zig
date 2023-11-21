const std = @import("std");
const c = @import("common.zig");
const Vec3 = c.Vec3;
const Color = @import("color.zig").Color;
const Hittable = @import("objects/hittable.zig");
const Ray = c.Ray;

pub const Material = union(enum) {
    diffuse: Lambertian,
    metal: Metal,

    pub fn scatter(self: *Material, ray: Ray, rec: Hittable.HitRecord, attenuation: *Color, scattered: *Ray) bool {
        return switch (self.*) {
            inline else => |*m| m.scatter(ray, rec, attenuation, scattered),
        };
    }
};

pub const Metal = struct {
    albedo: Color,
    fuzz: f64,

    pub fn init(color: Color, fuzz: f64) Material {
        const f = if (fuzz < 1) fuzz else 1.0;
        return Material{ .metal = Metal{ .albedo = color, .fuzz = f } };
    }

    pub fn scatter(self: *Metal, ray: Ray, rec: Hittable.HitRecord, attenuation: *Color, scattered: *Ray) bool {
        const reflected = ray.direction.unit().reflect(rec.normal);
        scattered.* = Ray{ .origin = rec.p, .direction = reflected.add(Vec3.randomUnitVector().mulScalar(self.fuzz)) };
        attenuation.* = self.albedo;
        return scattered.direction.dot(rec.normal) > 0;
    }
};

pub const Lambertian = struct {
    albedo: Color,

    pub fn init(color: Color) Material {
        return Material{ .diffuse = Lambertian{ .albedo = color } };
    }

    pub fn scatter(self: *Lambertian, ray: Ray, rec: Hittable.HitRecord, attenuation: *Color, scattered: *Ray) bool {
        _ = ray;
        var scatter_direction = rec.normal.add(Vec3.randomUnitVector());

        if (scatter_direction.nearZero())
            scatter_direction = rec.normal;

        scattered.* = Ray{ .origin = rec.p, .direction = scatter_direction };
        attenuation.* = self.albedo;

        return true;
    }
};
