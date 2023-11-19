const vec = @import("../vec.zig");
const ray = @import("../ray.zig");

const Point3 = vec.Point3;
const Vec3 = vec.Vec3;
const Ray = ray.Ray;

const Hittable = @This();

pub const HitRecord = struct {
    p: Point3,
    t: f64,
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
hitFn: *const fn (ptr: *anyopaque, r: Ray, ray_tmin: f64, ray_tmax: f64) ?HitRecord,

pub fn init(ptr: anytype) Hittable {
    const T = @TypeOf(ptr);
    const ptr_info = @typeInfo(T);

    const gen = struct {
        pub fn hit(pointer: *anyopaque, r: Ray, ray_tmin: f64, ray_tmax: f64) ?HitRecord {
            const self: T = @ptrCast(@alignCast(pointer));
            return ptr_info.Pointer.child.hit(self, r, ray_tmin, ray_tmax);
        }
    };

    return .{
        .ptr = ptr,
        .hitFn = gen.hit,
    };
}

pub fn hit(self: Hittable, r: Ray, ray_tmin: f64, ray_tmax: f64) ?HitRecord {
    return self.hitFn(self.ptr, r, ray_tmin, ray_tmax);
}
