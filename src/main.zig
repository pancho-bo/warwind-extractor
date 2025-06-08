const Frame = struct { width: u16, height: u16, pixels: []u8 };

pub fn main() !void {
    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // Don't forget to flush!

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var lua = try Lua.init(allocator);
    defer lua.deinit();

    try lua.doFile("scripts/conf.lua");
    _ = try lua.getGlobal("Infile");
    const image_path_lua = try lua.toString(-1);
    const image_path = try allocator.dupeZ(u8, image_path_lua);
    defer allocator.free(image_path);
    lua.pop(1);

    _ = try lua.getGlobal("Palette");
    const palette_lua: usize = @intCast(try lua.toInteger(-1));
    lua.pop(1);

    // _ = try lua.getGlobal("Rogue");
    // const rogue_lua: usize = @intCast(try lua.toInteger(-1));
    // _ = rogue_lua;
    // lua.pop(1);

    // const t = try lua.getGlobal("TharoonUnits");
    // std.testing.expect(t == .table);

    // lua.rawGetIndex();

    {
        // var image = try zigimg.Image.fromFilePath(allocator, "C:/Projects/data.wwgus/graphics/missiles/ww/shamali_missile.png");
        var image = try zigimg.Image.fromFilePath(allocator, image_path);
        defer image.deinit();

        try image.writeToFilePath("C:/Projects/out.png", .{ .png = .{} });
    }

    const data_file_name = "C:/Program Files/GOG Galaxy/Games/War Wind/Data/RES.001";

    const file = try std.fs.cwd().openFile(data_file_name, .{ .mode = .read_only });
    defer file.close();

    const data = file.reader();
    const num_nodes = try data.readInt(u32, .little);

    try stdout.print("Number of nodes: {d}\n", .{num_nodes});
    try bw.flush(); // Don't forget to flush!

    //*   Read index *//
    var index: []u32 = try allocator.alloc(u32, num_nodes);
    defer allocator.free(index);

    {
        var i: usize = 0;
        while (i < num_nodes) : (i += 1) {
            const next_node_position: u32 = try data.readInt(u32, .little);
            index[i] = next_node_position;
            try stdout.print("Node {d}: next node position: {X}\n", .{ i, next_node_position });
            try bw.flush(); // Don't forget to flush!
            // try data.skipBytes(next_node_position - current_position, .{});
        }
    }

    //*   Read palette *//
    try file.seekTo(index[palette_lua]);
    const d3gr: [4]u8 = try data.readBytesNoEof(4);
    try std.testing.expect(std.mem.eql(u8, &d3gr, "D3GR"));

    _ = try data.readInt(u32, .little); //0x2001
    _ = try data.readInt(u32, .little); //frames_start
    const palette_start = try data.readInt(u32, .little);

    //read 12 bytes from the start already
    try data.skipBytes(palette_start - 12, .{});

    var palette: [256]zigimg.color.Rgba32 align(1) = undefined;
    {
        for (0..256) |i| {
            const r: u8 = try data.readByte() << 2;
            const g: u8 = try data.readByte() << 2;
            const b: u8 = try data.readByte() << 2;
            const a: u8 = if (i == 0) 0 else 0xff; // Zero color is transparent
            palette[i] = zigimg.color.Rgba32.initRgba(@intCast(r), @intCast(g), @intCast(b), @intCast(a));
        }
    }

    //*   Output palette *//
    {
        var image = try zigimg.Image.fromRawPixels(allocator, 16, 16, @ptrCast(&palette), .rgba32);
        defer image.deinit();

        const bytes = image.rawBytes();
        {
            var j: usize = 0;
            while (j < 16 * 4) : (j += 4) {
                var k: usize = 0;
                while (k < 16 * 4) : (k += 4) {
                    try stdout.print("{x}{x}{x}{x}|", .{ bytes[j * 16 + k], bytes[j * 16 + k + 1], bytes[j * 16 + k + 2], bytes[j * 16 + k + 3] });
                }
                try stdout.print("\n", .{});
            }
            try bw.flush(); // Don't forget to flush!
        }
        try image.writeToFilePath("C:/Projects/p1.png", .{ .png = .{} });
    }

    const ops = [_]FramesBlockOperation{ FramesBlockOperation{ .transpose = Transpose{ .rows = 5, .cols = 4 } }, FramesBlockOperation{ .transpose = Transpose{ .rows = 5, .cols = 4 } }, FramesBlockOperation{ .replicate = Replicate{ .items = 4, .times = 5 } } };
    try outputFrames(allocator, file, index[40], palette, &ops, "minister", 88, 88, 8);
    try outputFrames(allocator, file, index[41], palette, &ops, "servant", 88, 88, 8);
    try outputFrames(allocator, file, index[42], palette, &ops, "rover", 88, 88, 8);
    try outputFrames(allocator, file, index[43], palette, &ops, "rogue", 88, 88, 8);
    try outputFrames(allocator, file, index[44], palette, &ops, "executioner", 88, 88, 8);
    try outputFrames(allocator, file, index[45], palette, &ops, "psychic", 88, 88, 8);

    try outputFrames(allocator, file, index[58], palette, &ops, "dancer", 80, 88, 8);
    try outputFrames(allocator, file, index[59], palette, &ops, "initiate", 80, 88, 8);
    try outputFrames(allocator, file, index[60], palette, &ops, "cavalier", 80, 88, 8);
    try outputFrames(allocator, file, index[61], palette, &ops, "disciple", 80, 88, 8);
    try outputFrames(allocator, file, index[62], palette, &ops, "defender", 80, 88, 8);
    try outputFrames(allocator, file, index[63], palette, &ops, "shaman", 80, 88, 8);

    try outputFrames(allocator, file, index[58], palette, &ops, "dancer", 80, 88, 8);
    try outputFrames(allocator, file, index[59], palette, &ops, "initiate", 80, 88, 8);
    try outputFrames(allocator, file, index[60], palette, &ops, "cavalier", 80, 88, 8);
    try outputFrames(allocator, file, index[61], palette, &ops, "disciple", 80, 88, 8);
    try outputFrames(allocator, file, index[62], palette, &ops, "defender", 80, 88, 8);
    try outputFrames(allocator, file, index[63], palette, &ops, "shaman", 80, 88, 8);

    try outputFrames(allocator, file, index[94], palette, &ops, "primemaker", 240, 88, 8);
    try outputFrames(allocator, file, index[95], palette, &ops, "scrub", 240, 88, 8);
    try outputFrames(allocator, file, index[96], palette, &ops, "weed", 240, 88, 8);
    try outputFrames(allocator, file, index[97], palette, &ops, "scout", 240, 88, 8);
    try outputFrames(allocator, file, index[98], palette, &ops, "squire", 240, 88, 8);
    try outputFrames(allocator, file, index[99], palette, &ops, "druid", 240, 88, 8);

    try outputFrames(allocator, file, index[88], palette, &ops, "general", 64, 88, 8);
    try outputFrames(allocator, file, index[89], palette, &ops, "worker", 64, 88, 8);
    try outputFrames(allocator, file, index[90], palette, &ops, "biker", 64, 88, 8);
    try outputFrames(allocator, file, index[91], palette, &ops, "agent", 64, 88, 8);
    try outputFrames(allocator, file, index[92], palette, &ops, "veteran", 64, 88, 8);
    try outputFrames(allocator, file, index[93], palette, &ops, "sorcerer", 64, 88, 8);

    // try outputFrames(allocator, file, index[46], palette, &ops, "general", 56, 88, 8);
    // try outputFrames(allocator, file, index[47], palette, &ops, "worker", 56, 88, 8);
    // try outputFrames(allocator, file, index[48], palette, &ops, "biker", 56, 88, 8);
    // try outputFrames(allocator, file, index[49], palette, &ops, "agent", 56, 88, 8);
    // try outputFrames(allocator, file, index[50], palette, &ops, "veteran", 56, 88, 8);
    // try outputFrames(allocator, file, index[51], palette, &ops, "sorcerer", 56, 88, 8);

    try outputFrames(allocator, file, index[66], palette, &ops, "primeminister", 88, 88, 8);
    try outputFrames(allocator, file, index[64], palette, &ops, "primeminister", 88, 88, 8);
}

const Transpose = struct { rows: usize, cols: usize };

const Replicate = struct { items: usize, times: usize };

const FramesBlockOperationTag = enum { transpose, replicate };

const FramesBlockOperation = union(FramesBlockOperationTag) { transpose: Transpose, replicate: Replicate };

fn outputFrames(allocator: std.mem.Allocator, file: std.fs.File, offset: u32, palette: [256]zigimg.color.Rgba32, operations: []const FramesBlockOperation, name: []const u8, remap_colors_from: u8, remap_colors_to: u8, remap_colors_n: u8) !void {
    //*   Read sprite sheet format: *//
    var frames_arena_allocator = std.heap.ArenaAllocator.init(allocator);
    const frames_allocator = frames_arena_allocator.allocator();

    const frames: []Frame = try readSpriteSheet(frames_allocator, file, offset);

    // const frames_alt: []Frame = try readSpriteSheet(frames_allocator, file, index[98]);

    defer frames_arena_allocator.deinit();

    // {
    //     const frame: usize = 0;
    //     var image = try zigimg.Image.create(allocator, frames[frame].width, frames[frame].height, .indexed8);
    //     var image_alt = try zigimg.Image.create(allocator, frames_alt[frame].width, frames_alt[frame].height, .indexed8);
    //     var image = try zigimg.Image.fromRawPixels(allocator, frames[0].width, frames[0].height, @ptrCast(pixels), .rgba32);
    //     defer image.deinit();
    //     defer image_alt.deinit();

    //     for (0..palette.len) |i| {
    //         image.pixels.indexed8.palette[i] = palette[i];
    //     }
    //     for (0..frames[frame].pixels.len) |i| {
    //         image.pixels.indexed8.indices[i] = frames[frame].pixels[i];
    //     }
    //     for (0..palette.len) |i| {
    //         image_alt.pixels.indexed8.palette[i] = palette[i];
    //     }
    //     for (0..frames[frame].pixels.len) |i| {
    //         if (frames[frame].pixels[i] != frames_alt[frame].pixels[i]) {
    //             image_alt.pixels.indexed8.indices[i] = frames_alt[frame].pixels[i];
    //         } else {
    //             image_alt.pixels.indexed8.indices[i] = 0;
    //         }
    //     }
    //     for (image_alt.pixels.indexed8.indices) |i| {
    //         if (i != 0) {
    //             std.debug.print("{d}|", .{i});
    //         }
    //     }
    //     std.debug.print("\n", .{});

    //     try image.writeToFilePath("C:/Projects/rogue1.png", .{ .png = .{} });
    //     try image_alt.writeToFilePath("C:/Projects/rogue2.png", .{ .png = .{} });
    // }

    var max_width: usize = 0;
    var max_height: usize = 0;
    for (frames) |f| {
        if (f.height > max_height) max_height = f.height;
        if (f.width > max_width) max_width = f.width;
    }
    std.debug.print("{s}: frames: {d}, frame size: {d}x{d}\n", .{ name, frames.len, max_width, max_height });

    var out_frames: usize = 0;
    var read_frames: usize = 0;
    for (operations) |o| {
        switch (o) {
            .transpose => {
                out_frames += o.transpose.cols * o.transpose.rows;
                read_frames += o.transpose.cols * o.transpose.rows;
            },
            .replicate => {
                out_frames += o.replicate.items * o.replicate.times;
                read_frames += o.replicate.items;
            },
        }
    }
    // std.debug.print("operations on {d} frames, output {d} frames\n", .{ read_frames, out_frames });
    try std.testing.expect(read_frames <= frames.len);

    var combined_image_storage: []u8 = try allocator.alloc(u8, out_frames * max_height * max_width);
    defer allocator.free(combined_image_storage);
    @memset(combined_image_storage, 0);

    var frames_done: usize = 0;
    var result_cols: usize = 0;
    var result_rows: usize = 0;
    for (operations) |o| {
        switch (o) {
            .transpose => {
                if (result_cols == 0 or result_cols == o.transpose.rows) {
                    result_cols = o.transpose.rows;
                } else {
                    return error.ResultColumnsVaries;
                }
                const frames_perm = try transpose(allocator, o.transpose.rows, o.transpose.cols, frames_done);
                defer allocator.free(frames_perm);
                const frames_to_do: usize = o.transpose.cols * o.transpose.rows;
                write_block(o.transpose.cols, o.transpose.rows, frames, frames_perm, combined_image_storage[frames_done * max_height * max_width .. (frames_done + frames_to_do) * max_height * max_width]);
                frames_done += frames_to_do;
                result_rows += o.transpose.cols;
                // std.debug.print("frames done: {d}, frames to do: {d}, rows done: {d}\n", .{ frames_done, frames_to_do, result_rows });
            },
            .replicate => {
                if (result_cols == 0 or result_cols == o.replicate.times) {
                    result_cols = o.replicate.times;
                } else {
                    return error.ResultColumnsVaries;
                }
                const frames_perm = try replicate(allocator, o.replicate.items, o.replicate.times, frames_done);
                defer allocator.free(frames_perm);
                const frames_to_do: usize = o.replicate.items * o.replicate.times;
                // for (frames_perm) |f| {
                //     std.debug.print("{d} ", .{f});
                // }
                // std.debug.print("\n", .{});
                write_block(o.replicate.items, o.replicate.times, frames, frames_perm, combined_image_storage[frames_done * max_height * max_width .. (frames_done + frames_to_do) * max_height * max_width]);
                result_rows += o.replicate.items;
                frames_done += o.replicate.items * o.replicate.times;
            },
        }
    }

    var combined_image = try zigimg.Image.create(allocator, max_width * result_cols, max_height * result_rows, .indexed8);
    defer combined_image.deinit();
    for (0..palette.len) |i| {
        combined_image.pixels.indexed8.palette[i] = palette[i];
    }
    for (0..(out_frames * max_width * max_height)) |i| {
        var target_color = combined_image_storage[i];
        if (target_color >= remap_colors_from and target_color < remap_colors_from + remap_colors_n) {
            target_color = target_color - remap_colors_from + remap_colors_to;
        } else if (target_color == 1) {
            target_color = 96;
        }
        combined_image.pixels.indexed8.indices[i] = target_color;
    }

    const dir = "C:/Projects";
    const outfile = try std.fmt.allocPrint(allocator, "{s}/{s}.png", .{ dir, name });
    defer allocator.free(outfile);
    try combined_image.writeToFilePath(outfile, .{ .png = .{} });
}

fn write_block(result_rows: usize, result_cols: usize, frames: []Frame, frames_perm: []usize, storage: []u8) void {
    var max_width: usize = 0;
    var max_height: usize = 0;
    for (frames) |f| {
        if (f.height > max_height) max_height = f.height;
        if (f.width > max_width) max_width = f.width;
    }

    for (0..result_rows) |i| {
        for (0..result_cols) |j| {
            const source_frame = frames[frames_perm[i * result_cols + j]];
            const frame_offset_w: usize = (max_width - source_frame.width) / 2;
            const frame_offset_h: usize = (max_height - source_frame.height) / 2;
            for (0..source_frame.height) |h| {
                for (0..source_frame.width) |w| {
                    const combined_image_storage_offset_h: usize = max_width * result_cols * (i * max_height + h + frame_offset_h);
                    const combined_image_storage_offset_w: usize = j * max_width + w + frame_offset_w;
                    // const combined_image_storage_offset: usize = i * 5 * max_height * max_width + j * max_width + (h + frame_offset_h) * max_width + w + frame_offset_w;
                    const combined_image_storage_offset: usize = combined_image_storage_offset_h + combined_image_storage_offset_w;
                    const target_frame_offset = h * source_frame.width + w;
                    // if (i == 0 and j == 0) {
                    //     std.debug.print("frame {d}:{d}, size: {d}x{d}, offsets: {d}:{d}, put: {d}:{d} => {d}:{d} \n", .{ i, j, target_frame.height, target_frame.width, frame_offset_h, frame_offset_w, h, w, combined_image_storage_offset_h, combined_image_storage_offset_w });
                    // }
                    storage[combined_image_storage_offset] = source_frame.pixels[target_frame_offset];
                }
            }
        }
    }
}

fn replicate(allocator: std.mem.Allocator, items: usize, cols: usize, offset: usize) ![]usize {
    var result: []usize = try allocator.alloc(usize, items * cols);
    for (0..items) |i| {
        for (0..cols) |c| {
            result[cols * i + c] = i + offset;
        }
    }
    return result;
}

fn transpose(allocator: std.mem.Allocator, rows: usize, cols: usize, offset: usize) ![]usize {
    var result: []usize = try allocator.alloc(usize, rows * cols);
    var i: usize = 0;
    while (i < cols) : (i += 1) {
        var j: usize = 0;
        while (j < rows) : (j += 1) {
            result[rows * i + j] = j * cols + i + offset;
        }
    }
    return result;
}

test "traspose_test" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const t1 = [6]usize{ 10, 13, 11, 14, 12, 15 };
    const t2 = try transpose(allocator, 2, 3, 10);
    defer allocator.free(t2);
    try std.testing.expect(std.mem.eql(usize, t2, &t1));
}

fn extractFrame(lua: *Lua) i32 {
    lua.getTable(0);
}

fn readSpriteSheet(frames_allocator: std.mem.Allocator, file: std.fs.File, offset: u32) ![]Frame {
    try file.seekTo(offset);
    const data = file.reader();
    std.debug.print("Reading sprite sheet at position {X}\n", .{offset});

    const header: [4]u8 = try data.readBytesNoEof(4);
    try std.testing.expect(std.mem.eql(u8, &header, "D3GR"));
    _ = try data.readInt(u32, .little); //?
    const frames_start = try data.readInt(u32, .little);
    _ = try data.readInt(u32, .little); //palette_start
    _ = try data.readInt(u32, .little); //?
    _ = try data.readInt(u32, .little); //?
    const frames_num: u16 = try data.readInt(u16, .little);

    try data.skipBytes(frames_start - 26, .{});
    // std.debug.print("Frames start: {X}, frames num: {d}, jump: {x}\n", .{ frames_start, frames_num, frames_start - 26 });

    var frames: []Frame = try frames_allocator.alloc(Frame, frames_num);

    {
        var i: usize = 0;
        while (i < frames_num) : (i += 1) {
            _ = try data.readInt(u32, .little); //frame_size

            _ = try data.readInt(u32, .little); //?
            _ = try data.readInt(u16, .little); //?
            _ = try data.readInt(u16, .little); //?

            const height: u16 = try data.readInt(u16, .little);
            const width: u16 = try data.readInt(u16, .little);
            // std.debug.print("Frame {d}: width: {d}, height: {d}\n", .{ i, width, height });
            var pixels: []u8 = try frames_allocator.alloc(u8, width * height);
            {
                var j: usize = 0;
                while (j < width * height) : (j += 1) {
                    pixels[j] = try data.readByte();
                }
            }
            frames[i] = Frame{ .width = width, .height = height, .pixels = pixels };
        }
    }
    return frames;
}

const std = @import("std");
const zigimg = @import("zigimg");
const zlua = @import("zlua");

const Lua = zlua.Lua;
