const std = @import("std");
const vec = @import("vec.zig");
const color = @import("color.zig");
const ray = @import("ray.zig");

const Hittable = @import("objects/hittable.zig");
const HittableList = @import("objects/hittable_list.zig");
const Sphere = @import("objects/sphere.zig");
const Ray = ray.Ray;
const Color = color.Color;
const Vec3 = vec.Vec3;
const Point3 = vec.Point3;

const aspect_ratio: f64 = 16.0 / 9.0;
const image_width = 400;
const image_height = blk: {
    const f_width: f64 = @floatFromInt(image_width);
    const height: i32 = @intFromFloat(f_width / aspect_ratio);
    break :blk if (height < 1) 1 else height;
};

// Camera settings

const focal_length = 1.0;
const viewport_height = 2.0;
const viewport_width = viewport_height * (@as(f64, @floatFromInt(image_width)) / image_height);
const camera_center = Point3{};

// Calculate the vectors across the horizontal and down the vertical viewport edges
const viewport_u = Vec3{ .x = viewport_width };
const viewport_v = Vec3{ .y = -viewport_height };

// Calculate the horizontal and vertical delta vectors from pixel to pixel
const pixel_delta_u = viewport_u.divScalar(image_width);
const pixel_delta_v = viewport_v.divScalar(image_height);

// Calculate the location of the upper left pixel
const viewport_upper_left = camera_center
    .sub(Point3{ .z = focal_length })
    .sub(viewport_u.divScalar(2))
    .sub(viewport_v.divScalar(2));
const pixel00_loc = viewport_upper_left.add(pixel_delta_u.add(pixel_delta_v).mulScalar(0.5));

pub fn main() !void {
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    // Allocator setup
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) @panic("TEST FAIL");
    }

    // World
    var world = HittableList.init(allocator);
    defer world.deinit();

    var sphere1 = Sphere{ .center = .{ .z = -1 }, .radius = 0.5 };
    var sphere2 = Sphere{ .center = .{ .y = -100.5, .z = -1 }, .radius = 100 };

    try world.add(sphere1.hittable());
    try world.add(sphere2.hittable());

    // Render the image
    try stdout.print("P3\n{d} {d}\n255\n", .{ image_width, image_height }); // Metadata

    for (0..image_height) |j| {
        std.log.info("\rScanlines remaining: {d} ", .{(image_height - j)});
        for (0..image_width) |i| {
            const pixel_center = pixel00_loc.add(
                pixel_delta_u
                    .mulScalar(@floatFromInt(i))
                    .add(pixel_delta_v.mulScalar(@floatFromInt(j))),
            );
            const ray_direction = pixel_center.sub(camera_center);
            const r = Ray{ .origin = camera_center, .direction = ray_direction };

            const c = rayColor(r, world.hittable());
            try color.write(stdout, c);
        }
    }

    std.log.info("\rDone.                        \n", .{});
    try bw.flush();
}

fn rayColor(r: Ray, world: Hittable) Color {
    if (world.hit(r, 0, std.math.inf(f64))) |rec| {
        return rec.normal.add(.{ .x = 1, .y = 1, .z = 1 }).mulScalar(0.5);
    }

    const unit_direction = r.direction.unit();
    const a = 0.5 * (unit_direction.y + 1);
    const white = Color{ .x = 1, .y = 1, .z = 1 };
    const blue = Color{ .x = 0.5, .y = 0.7, .z = 1 };

    return white.mulScalar(1 - a).add(blue.mulScalar(a));
}
