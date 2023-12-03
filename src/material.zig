const std = @import("std");
const c = @import("common.zig");
const Vec3 = c.Vec3;
const Color = @import("color.zig").Color;
const Hittable = @import("objects/hittable.zig");
const HitRecord = Hittable.HitRecord;
const Ray = c.Ray;

pub const Material = union(enum) {
    diffuse: Lambertian,
    metal: Metal,
    dielectric: Dielectric,

    pub fn scatter(self: *Material, ray: Ray, rec: *const HitRecord, attenuation: *Color, scattered: *Ray) bool {
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

    pub fn scatter(self: *Metal, ray: Ray, rec: *const HitRecord, attenuation: *Color, scattered: *Ray) bool {
        const reflected = ray.direction.unit().reflect(rec.normal);
        scattered.* = Ray{ .origin = rec.p, .direction = reflected.add(Vec3.randomUnitVector().mulScalar(self.fuzz)) };
        attenuation.* = self.albedo;
        return scattered.direction.dot(rec.normal) > 0;
    }
};

pub const Lambertian = struct {
    albedo: Color,

    pub fn init(r: f64, g: f64, b: f64) Material {
        return Material{ .diffuse = Lambertian{ .albedo = Color{ .x = r, .y = g, .z = b } } };
    }

    pub fn scatter(self: *Lambertian, ray: Ray, rec: *const HitRecord, attenuation: *Color, scattered: *Ray) bool {
        _ = ray;
        var scatter_direction = rec.normal.add(Vec3.randomUnitVector());

        if (scatter_direction.nearZero())
            scatter_direction = rec.normal;

        scattered.* = Ray{ .origin = rec.p, .direction = scatter_direction };
        attenuation.* = self.albedo;

        return true;
    }
};

pub const Dielectric = struct {
    ior: f64,

    pub fn init(index_of_refraction: f64) Material {
        return Material{ .dielectric = .{ .ior = index_of_refraction } };
    }

    pub fn scatter(self: *Dielectric, ray: Ray, rec: *const HitRecord, attenuation: *Color, scattered: *Ray) bool {
        attenuation.* = Color{ .x = 1, .y = 1, .z = 1 };
        const refraction_ratio = if (rec.front_face) (1.0 / self.ior) else self.ior;
        const unit_direction = ray.direction.unit();
        const cos_theta: f64 = @min(unit_direction.neg().dot(rec.normal), 1.0);
        const sin_theta: f64 = @sqrt(1.0 - cos_theta * cos_theta);
        const cannot_refract = refraction_ratio * sin_theta > 1.0;

        const direction = if (cannot_refract or reflectance(cos_theta, refraction_ratio) > c.random.float())
            unit_direction.reflect(rec.normal)
        else
            unit_direction.refraction(rec.normal, refraction_ratio);

        scattered.* = Ray{ .origin = rec.p, .direction = direction };
        return true;
    }

    fn reflectance(cosine: f64, ref_idx: f64) f64 {
        // Use Schlick's approximation for reflectance
        var r0 = (1 - ref_idx) / (1 + ref_idx);
        r0 *= r0;
        return r0 + (1 - r0) * std.math.pow(f64, 1 - cosine, 5);
    }
};
