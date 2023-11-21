const c = @import("../common.zig");
const Material = @import("../material.zig").Material;

const Interval = c.Interval;
const Point3 = c.Point3;
const Vec3 = c.Vec3;
const Ray = c.Ray;

const Hittable = @This();

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

ptr: *anyopaque,
hitFn: *const fn (ptr: *anyopaque, r: Ray, ray_t: Interval) ?HitRecord,

pub fn init(ptr: anytype) Hittable {
    const T = @TypeOf(ptr);
    const ptr_info = @typeInfo(T);

    const gen = struct {
        pub fn hit(pointer: *anyopaque, r: Ray, ray_t: Interval) ?HitRecord {
            const self: T = @ptrCast(@alignCast(pointer));
            return ptr_info.Pointer.child.hit(self, r, ray_t);
        }
    };

    return .{
        .ptr = ptr,
        .hitFn = gen.hit,
    };
}

pub fn hit(self: Hittable, r: Ray, ray_t: Interval) ?HitRecord {
    return self.hitFn(self.ptr, r, ray_t);
}
