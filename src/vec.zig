const std = @import("std");
const c = @import("common.zig");
const ReduceOp = std.builtin.ReduceOp;

const VecSimd = @Vector(3, f64);
const Random = c.Random;

pub const Point3 = Vec3;
pub const Vec3 = extern struct {
    x: f64 = 0,
    y: f64 = 0,
    z: f64 = 0,

    pub inline fn toArray(self: Vec3) [3]f64 {
        return @bitCast(self);
    }

    pub inline fn toSimd(self: Vec3) VecSimd {
        return @bitCast(self);
    }

    pub inline fn fromSimd(simd: VecSimd) Vec3 {
        return @bitCast(simd);
    }

    pub inline fn toSlice(self: *Vec3) []f64 {
        return std.mem.bytesAsSlice(f64, std.mem.asBytes(self));
    }

    pub inline fn fromArray(arr: [3]f64) Vec3 {
        return @bitCast(arr);
    }

    pub inline fn at(self: Vec3, index: u8) f64 {
        return self.toArray()[index];
    }

    pub inline fn neg(self: Vec3) Vec3 {
        return self.mulScalar(-1);
    }

    pub inline fn add(self: Vec3, other: Vec3) Vec3 {
        return fromSimd(self.toSimd() + other.toSimd());
    }

    pub inline fn sub(self: Vec3, other: Vec3) Vec3 {
        return self.add(other.neg());
    }

    pub inline fn mul(self: Vec3, other: Vec3) Vec3 {
        return fromSimd(self.toSimd() * other.toSimd());
    }

    pub inline fn mulScalar(self: Vec3, scalar: f64) Vec3 {
        return fromSimd(@as(VecSimd, @splat(scalar)) * self.toSimd());
    }

    pub inline fn divScalar(self: Vec3, scalar: f64) Vec3 {
        return self.mulScalar(1 / scalar);
    }

    pub inline fn length(self: Vec3) f64 {
        return @sqrt(self.lengthSquared());
    }

    pub inline fn lengthSquared(self: Vec3) f64 {
        return @reduce(ReduceOp.Add, self.toSimd() * self.toSimd());
    }

    pub inline fn dot(self: Vec3, other: Vec3) f64 {
        return @reduce(ReduceOp.Add, self.mul(other).toSimd());
    }

    pub inline fn unit(self: Vec3) Vec3 {
        return self.divScalar(self.length());
    }

    pub inline fn randomInUnitSphere(rng: *Random) Vec3 {
        var p: Vec3 = undefined;
        while (true) {
            p = Vec3.randomInRange(rng, -1, 1);
            if (p.lengthSquared() < 1)
                return p;
        }
    }

    pub inline fn randomUnitVector(rng: *Random) Vec3 {
        const temp = Vec3.randomInUnitSphere(rng).unit();

        std.log.debug("Unit Sphere: {any}\n", .{temp});
        return temp;
    }

    pub inline fn randomOnHemisphere(rng: *Random, normal: Vec3) Vec3 {
        const on_unit_sphere = Vec3.randomUnitVector(rng);
        return if (on_unit_sphere.dot(normal) > 0) on_unit_sphere else on_unit_sphere.neg();
    }

    pub fn random(rng: *Random) Vec3 {
        return Vec3{
            .x = rng.float(),
            .y = rng.float(),
            .z = rng.float(),
        };
    }

    pub fn randomInRange(rng: *Random, min: f64, max: f64) Vec3 {
        return Vec3{
            .x = rng.floatInRange(min, max),
            .y = rng.floatInRange(min, max),
            .z = rng.floatInRange(min, max),
        };
    }
};

export fn getVec(vec: *Vec3, index: u8) f64 {
    return vec.at(index);
}

const testing = std.testing;
test "To array" {
    const v = Vec3{};
    const arr = v.toArray();

    try testing.expectEqual([3]f64{ 0, 0, 0 }, arr);
}
