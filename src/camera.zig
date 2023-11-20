const std = @import("std");
const Hittable = @import("objects/hittable.zig");
const c = @import("common.zig");
const color = @import("color.zig");

const Camera = @This();
const Point3 = c.Point3;
const Vec3 = c.Vec3;
const Color = color.Color;
const Ray = c.Ray;
const Random = c.Random;

asepct_ratio: f64 = 1.0,
image_width: u32 = 100,
samples_per_pixel: u32 = 10,
image_height: u32,
center: Point3,
pixel00_loc: Point3,
pixel_delta_u: Vec3,
pixel_delta_v: Vec3,
rng: Random,

pub fn render(self: *Camera, world: anytype) !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Render the image
    try stdout.print("P3\n{d} {d}\n255\n", .{ self.image_width, self.image_height }); // Metadata

    for (0..self.image_height) |j| {
        std.log.info("\rScanlines remaining: {d} ", .{(self.image_height - j)});
        for (0..self.image_width) |i| {
            var pixel_color = Color{};
            for (0..self.samples_per_pixel) |_| {
                const r = self.getRay(i, j);
                pixel_color = pixel_color.add(Camera.rayColor(r, world.hittable()));
            }

            try color.write(stdout, pixel_color, self.samples_per_pixel);
        }
    }

    std.log.info("\rDone.                        \n", .{});
    try bw.flush();
}

pub fn init(aspect_ratio: f64, image_width: u32, samples_per_pixel: u32) Camera {
    const image_height = blk: {
        const f_width: f64 = @floatFromInt(image_width);
        const height: u32 = @intFromFloat(f_width / aspect_ratio);
        break :blk if (height < 1) 1 else height;
    };

    // Camera settings
    const focal_length = 1.0;
    const viewport_height = 2.0;
    const viewport_width: f64 = viewport_height * (@as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height)));
    const camera_center = Point3{};

    // Calculate the vectors across the horizontal and down the vertical viewport edges
    const viewport_u = Vec3{ .x = viewport_width };
    const viewport_v = Vec3{ .y = -viewport_height };

    // Calculate the horizontal and vertical delta vectors from pixel to pixel
    const pixel_delta_u = viewport_u.divScalar(@floatFromInt(image_width));
    const pixel_delta_v = viewport_v.divScalar(@floatFromInt(image_height));

    // Calculate the location of the upper left pixel
    const viewport_upper_left = camera_center
        .sub(Point3{ .z = focal_length })
        .sub(viewport_u.divScalar(2))
        .sub(viewport_v.divScalar(2));
    const pixel00_loc = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).mulScalar(0.5));

    const rng = Random.init(@intCast(std.time.timestamp()));

    return Camera{
        .asepct_ratio = aspect_ratio,
        .image_width = image_width,
        .image_height = image_height,
        .center = camera_center,
        .pixel00_loc = pixel00_loc,
        .pixel_delta_u = pixel_delta_u,
        .pixel_delta_v = pixel_delta_v,
        .rng = rng,
        .samples_per_pixel = samples_per_pixel,
    };
}

fn getRay(self: *Camera, i: usize, j: usize) Ray {
    const pixel_center = self.pixel00_loc
        .add(self.pixel_delta_u.mulScalar(@floatFromInt(i)))
        .add(self.pixel_delta_v.mulScalar(@floatFromInt(j)));
    const pixel_sample = pixel_center.add(self.pixelSampleSquare());

    const ray_origin = self.center;
    const ray_direction = pixel_sample.sub(ray_origin);

    return Ray{ .origin = ray_origin, .direction = ray_direction };
}

fn pixelSampleSquare(self: *Camera) Vec3 {
    const px = -0.5 + self.rng.float();
    const py = -0.5 + self.rng.float();

    return self
        .pixel_delta_u
        .mulScalar(px)
        .add(self.pixel_delta_v.mulScalar(py));
}

fn rayColor(r: c.Ray, world: Hittable) Color {
    if (world.hit(r, c.Interval.init(0, c.infinity))) |rec| {
        return rec.normal.add(.{ .x = 1, .y = 1, .z = 1 }).mulScalar(0.5);
    }

    const unit_direction = r.direction.unit();
    const a = 0.5 * (unit_direction.y + 1);
    const white = Color{ .x = 1, .y = 1, .z = 1 };
    const blue = Color{ .x = 0.5, .y = 0.7, .z = 1 };

    return white.mulScalar(1 - a).add(blue.mulScalar(a));
}
