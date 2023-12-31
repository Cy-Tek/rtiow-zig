const std = @import("std");
const math = std.math;

const Hittable = @import("objects/hittable.zig");
const HittableList = @import("objects/hittable_list.zig");
const c = @import("common.zig");
const color = @import("color.zig");

const Camera = @This();
const Point3 = c.Point3;
const Vec3 = c.Vec3;
const Color = color.Color;
const Ray = c.Ray;
const Random = c.Random;

var rng = &c.random;

asepct_ratio: f64 = 1.0,
image_width: u32 = 100,
samples_per_pixel: u32 = 10,
max_depth: u32 = 10,
image_height: u32,
center: Point3,
pixel00_loc: Point3,
pixel_delta_u: Vec3,
pixel_delta_v: Vec3,
vfov: f64 = 90,

look_from: Point3 = Point3{ .x = 0, .y = 0, .z = 1 },
look_at: Point3 = Point3{ .x = 0, .y = 0, .z = 0 },
vup: Vec3 = Vec3{ .x = 0, .y = 1, .z = 0 },

u: Vec3,
v: Vec3,
w: Vec3,

defocus_angle: f64 = 0,
focus_dist: f64 = 10,
defocus_disk_u: Vec3,
defocus_disk_v: Vec3,

pub fn render(self: *Camera, world: HittableList) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // We want this to print every line we pass into it, so no need for the overhead
    // of a buffered Writer
    const stderr = std.io.getStdErr().writer();

    // Render the image
    try stdout.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height }); // Metadata

    for (0..self.image_height) |j| {
        try stderr.print("\rScanlines remaining: {d} ", .{(self.image_height - j)});

        for (0..self.image_width) |i| {
            var pixel_color = Color{};
            for (0..self.samples_per_pixel) |_| {
                const r = self.getRay(i, j);
                pixel_color = pixel_color.add(rayColor(r, self.max_depth, world));
            }

            try color.write(stdout, pixel_color, self.samples_per_pixel);
        }
    }

    try stderr.print("\rDone.                        \n", .{});
    try bw.flush();
}

pub fn init(
    aspect_ratio: f64,
    image_width: u32,
    samples_per_pixel: u32,
    vfov: f64,
    look_from: Point3,
    look_at: Point3,
    vup: Vec3,
    defocus_angle: f64,
    focus_dist: f64,
) Camera {
    const image_height = blk: {
        const f_width: f64 = @floatFromInt(image_width);
        const height: u32 = @intFromFloat(f_width / aspect_ratio);
        break :blk if (height < 1) 1 else height;
    };

    // Camera settings
    const theta = std.math.degreesToRadians(f64, vfov);
    const h = std.math.tan(theta / 2);
    const viewport_height: f64 = 2 * h * focus_dist;
    const viewport_width: f64 = viewport_height *
        @as(f64, @floatFromInt(image_width)) /
        @as(f64, @floatFromInt(image_height));
    const camera_center = look_from;

    // Calculate the u,v,w unit basis vectors for the camera coordinate frame
    const w = look_from.sub(look_at).unit();
    const u = vup.cross(w).unit();
    const v = w.cross(u);

    // Calculate the vectors across the horizontal and down the vertical viewport edges
    const viewport_u = u.mulScalar(viewport_width);
    const viewport_v = v.mulScalar(viewport_height);

    // Calculate the horizontal and vertical delta vectors from pixel to pixel
    const pixel_delta_u = viewport_u.divScalar(@floatFromInt(image_width));
    const pixel_delta_v = viewport_v.divScalar(@floatFromInt(image_height));

    // Calculate the location of the upper left pixel
    const viewport_upper_left = camera_center
        .sub(w.mulScalar(focus_dist))
        .sub(viewport_u.divScalar(2))
        .sub(viewport_v.divScalar(2));
    const pixel00_loc = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).mulScalar(0.5));

    const defocus_radius = focus_dist * math.tan(math.degreesToRadians(f64, defocus_angle / 2));
    const defocus_disk_u = u.mulScalar(defocus_radius);
    const defocus_disk_v = v.mulScalar(defocus_radius);

    return Camera{
        .asepct_ratio = aspect_ratio,
        .image_width = image_width,
        .image_height = image_height,
        .center = camera_center,
        .pixel00_loc = pixel00_loc,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
        .samples_per_pixel = samples_per_pixel,
        .u = u,
        .v = v,
        .w = w,
        .vfov = vfov,
        .look_from = look_from,
        .look_at = look_at,
        .vup = vup,
        .defocus_angle = defocus_angle,
        .focus_dist = focus_dist,
        .defocus_disk_u = defocus_disk_u,
        .defocus_disk_v = defocus_disk_v,
    };
}

fn getRay(self: *const Camera, i: usize, j: usize) Ray {
    const pixel_center = self.pixel00_loc
        .add(self.pixel_delta_u.mulScalar(@floatFromInt(i)))
        .add(self.pixel_delta_v.mulScalar(@floatFromInt(j)));
    const pixel_sample = pixel_center.add(self.pixelSampleSquare());

    const ray_origin = if (self.defocus_angle <= 0) self.center else defocusDiskSample(self);
    const ray_direction = pixel_sample.sub(ray_origin);

    return Ray{ .origin = ray_origin, .direction = ray_direction };
}

fn pixelSampleSquare(self: *const Camera) Vec3 {
    const px = -0.5 + rng.float();
    const py = -0.5 + rng.float();

    return self
        .pixel_delta_u
        .mulScalar(px)
        .add(self.pixel_delta_v.mulScalar(py));
}

fn defocusDiskSample(self: *const Camera) Point3 {
    const p = Vec3.randomInUnitDisk();
    return self.center
        .add(self.defocus_disk_u.mulScalar(p.x))
        .add(self.defocus_disk_v.mulScalar(p.y));
}

fn rayColor(r: c.Ray, depth: u32, world: HittableList) Color {
    if (depth <= 0) return Color{};

    var record = world.hit(r, c.Interval.init(0.001, c.infinity));
    if (record) |*rec| {
        var scattered: Ray = undefined;
        var attenuation: Color = undefined;
        var mat = &rec.mat;

        if (mat.scatter(r, rec, &attenuation, &scattered))
            return rayColor(scattered, depth - 1, world).mul(attenuation);

        return Color{};
    }

    const unit_direction = r.direction.unit();
    const a = 0.5 * (unit_direction.y + 1);
    const white = Color{ .x = 1, .y = 1, .z = 1 };
    const blue = Color{ .x = 0.5, .y = 0.7, .z = 1 };

    return white.mulScalar(1 - a).add(blue.mulScalar(a));
}
