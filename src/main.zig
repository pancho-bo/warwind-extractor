// const SpriteSheet = struct { name: []const u8, columns: usize, rows: usize, frames: []ChunkL };
// const DatFile = struct { name: []const u8, offset: usize };
// const ChunkL = struct { source: []const u8, transform: []FramesBlockOperation, color_remap: ColorRemap, write_offset: usize };
// const ColorRemap = struct { from_base: usize, to_base: usize, colors: usize };

pub fn spriteSheet(lua: *Lua) !i32 {
    errdefer {
        const message = lua.toString(-1) catch "Can't get error from lua";
        std.debug.print("{s}", .{message});
    }
    // _ = try lua.toAnyAlloc(SpriteSheet, -1);

    _ = lua.getField(-1, "name");
    const name: []const u8 = try lua.toString(-1);
    _ = lua.pop(1);

    _ = lua.getField(-1, "columns");
    const columns: usize = @intCast(try lua.toInteger(-1));
    _ = lua.pop(1);

    _ = lua.getField(-1, "rows");
    const rows: usize = @intCast(try lua.toInteger(-1));
    _ = lua.pop(1);

    std.debug.print("Name is {s}, columns: {d}, rows: {d}", .{ name, columns, rows });

    // const ops = [_]FramesBlockOperation{ FramesBlockOperation{ .transpose = Transpose{ .rows = 5, .cols = 4 } }, FramesBlockOperation{ .transpose = Transpose{ .rows = 5, .cols = 4 } }, FramesBlockOperation{ .replicate = Replicate{ .items = 4, .times = 5 } } };
    // try outputFrames(lua.allocator(), file, index[40], palette, &ops, "minister", .{ .from = 88, .to = 88, .n = 8 }, 5, 0);
    // const s = lua.typeNameIndex(-1);
    // std.debug.print("Type is {s}\n", .{s});
    // lua.len(-1);
    // const size: usize = @intCast(try lua.toInteger(-1));
    // std.debug.print("Size is {d}\n", .{size});

    return 0;
}

// pub fn color_remap(lua: *Lua) !i32 {
//     //new function?

//     return 1;
// }

// pub fn read_file(lua: *Lua) !i32 {
//     const name: []const u8 = lua.getField(-1, "name");

//     return 0;
// }

// pub fn write_file(lua: *Lua) !i32 {
//     const name: []const u8 = lua.getField(-1, "name");
//     write_image(lua.allocator(), name, 800, 600, palette, pixels);
//     return 0;
// }

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

    var lua: *Lua = try Lua.init(allocator);
    defer lua.deinit();

    lua.openTable();
    // lua.autoPushFunction(sprite_sheet);
    lua.pushFunction(zlua.wrap(spriteSheet));
    lua.setGlobal("SpriteSheet");

    {
        errdefer {
            const message = lua.toString(-1) catch "Can't get error from lua";
            // const message2 = lua.toString(-2) catch "Can't get error from lua";
            std.debug.print("Got error from Lua: {s}\n", .{message});
        }
        try lua.doFile("scripts/conf.lua");
    }

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
            // try stdout.print("Node {d}: next node position: {X}\n", .{ i, next_node_position });
            // try bw.flush(); // Don't forget to flush!
            // try data.skipBytes(next_node_position - current_position, .{});
        }
    }

    const palette: []zigimg.color.Rgba32 = try readPalette(allocator, file, index[palette_lua]);
    defer allocator.free(palette);

    // {
    //     errdefer {
    //         const message = lua.toString(-1) catch "Can't get error from lua";
    //         // const message2 = lua.toString(-2) catch "Can't get error from lua";
    //         std.debug.print("Got error from Lua: {s}\n", .{message});
    //     }
    //     try lua.doFile("scripts/sprites.lua");
    // }

    // try doUnits(allocator, file, index, palette);

    const ops = [_]FrameBlockOp{FrameBlockOp{ .copy = .{ .items = 4 } }};
    // allocate pixels, how to get size???
    // sprite_sheet(name, w, h).from[frames(at_index)(+w,+h).chunks[], frames[at_index](+w, +h).chunks[]]
    //(read frames(+fsize), apply ops(+image_len) => chunk), write_chunk at offset(+image_size), write_pixels, write image
    const indices = [_]u32{ index[3], index[7], index[8], index[9], index[10], index[11], index[12] };
    const sprite_sheet = try outputFrames(allocator, file, indices[0..], &ops, .{ .from = 88, .to = 88, .n = 8 }, 16, 64);
    defer allocator.free(sprite_sheet.pixels);

    try writeImage(allocator, "coast", sprite_sheet.width, sprite_sheet.height, palette[0..256], sprite_sheet.pixels);

    // var chunk: FrameChunk = read_frames();
    // ops.
}

pub fn readPalette(allocator: std.mem.Allocator, file: std.fs.File, offset: usize) ![]zigimg.color.Rgba32 {
    //*   Read palette *//
    const data = file.reader();
    try file.seekTo(offset);
    const d3gr: [4]u8 = try data.readBytesNoEof(4);
    try std.testing.expect(std.mem.eql(u8, &d3gr, "D3GR"));

    _ = try data.readInt(u32, .little); //0x2001
    _ = try data.readInt(u32, .little); //frames_start
    const palette_start = try data.readInt(u32, .little);

    //read 12 bytes from the start already
    try data.skipBytes(palette_start - 12, .{});

    const palette: []zigimg.color.Rgba32 = try allocator.alloc(zigimg.color.Rgba32, 256);
    {
        for (0..256) |i| {
            const r: u8 = try data.readByte() << 2;
            const g: u8 = try data.readByte() << 2;
            const b: u8 = try data.readByte() << 2;
            const a: u8 = if (i == 0) 0 else 0xff; // Zero color is transparent
            palette[i] = zigimg.color.Rgba32.initRgba(@intCast(r), @intCast(g), @intCast(b), @intCast(a));
        }
    }
    return palette;
}

const FrameIterator = struct {
    i: usize,
    frames: []Frame,
    nextChunk: ?*FrameChunk = null,
    perm: ?[]usize = null,
    replicate: ?usize = null,
    j: usize,
    const Self = @This();

    pub fn next(self: *Self) ?Frame {
        if (self.i < self.frames.len) {
            //Don't know how to do it without function overrides
            if (self.replicate) |r| {
                defer {
                    self.j += 1;
                    if (self.j == r) {
                        self.j = 0;
                        self.i += 1;
                    }
                }
                if (self.perm) |p| {
                    return self.frames[p[self.i]];
                } else {
                    // std.debug.print("Getting replicated frame {d} times: {d}\n", .{ self.i, self.j });
                    return self.frames[self.i];
                }
            } else {
                defer self.i += 1;

                if (self.perm) |p| {
                    return self.frames[p[self.i]];
                } else {
                    return self.frames[self.i];
                }
            }
        } else {
            if (self.nextChunk) |c| {
                return c.frames[0]; //Replace iterator
            } else {
                return null;
            }
        }
    }
};

const FrameChunk = struct {
    cols: usize,
    rows: usize,
    frame_w: usize,
    frame_h: usize,
    frames: []Frame,
    perm: ?[]usize = null,
    repl_n: ?usize = null,
    len: usize,

    pub fn iterate(self: *FrameChunk) FrameIterator {
        return FrameIterator{ .i = 0, .frames = self.frames, .perm = self.perm, .j = 0, .replicate = self.repl_n };
    }

    pub fn slice(self: *FrameChunk, from: usize, to: usize) void {
        self.frames = self.frames[from..to];
        self.len = to - from;
    }

    fn transpose(self: *FrameChunk, allocator: std.mem.Allocator, rows: usize, cols: usize) ![]usize {
        var result: []usize = try allocator.alloc(usize, rows * cols);
        var i: usize = 0;
        while (i < cols) : (i += 1) {
            var j: usize = 0;
            while (j < rows) : (j += 1) {
                result[rows * i + j] = j * cols + i;
            }
        }
        self.perm = result;
        return result;
    }

    fn replicate(self: *FrameChunk, times: usize) void {
        self.repl_n = times;
        self.len = self.len * times;
    }
};
const Frame = struct { width: u16, height: u16, pixels: []u8 };

fn doUnits(allocator: std.mem.Allocator, file: std.fs.File, index: []u32, palette: [256]zigimg.color.Rgba32) !void {
    const ops = [_]FrameBlockOp{ FrameBlockOp{ .transpose = Transpose{ .rows = 5, .cols = 4 } }, FrameBlockOp{ .transpose = Transpose{ .rows = 5, .cols = 4 } }, FrameBlockOp{ .replicate = Replicate{ .items = 4, .times = 5 } } };
    try outputFrames(allocator, file, index[40], palette, &ops, "minister", .{ .from = 88, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[41], palette, &ops, "servant", .{ .from = 88, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[42], palette, &ops, "rover", .{ .from = 88, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[43], palette, &ops, "rogue", .{ .from = 88, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[44], palette, &ops, "executioner", .{ .from = 88, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[45], palette, &ops, "psychic", .{ .from = 88, .to = 88, .n = 8 }, 5, 0);

    try outputFrames(allocator, file, index[58], palette, &ops, "dancer", .{ .from = 80, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[59], palette, &ops, "initiate", .{ .from = 80, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[60], palette, &ops, "cavalier", .{ .from = 80, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[61], palette, &ops, "disciple", .{ .from = 80, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[62], palette, &ops, "defender", .{ .from = 80, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[63], palette, &ops, "shaman", .{ .from = 80, .to = 88, .n = 8 }, 5, 0);

    try outputFrames(allocator, file, index[58], palette, &ops, "dancer", .{ .from = 80, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[59], palette, &ops, "initiate", .{ .from = 80, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[60], palette, &ops, "cavalier", .{ .from = 80, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[61], palette, &ops, "disciple", .{ .from = 80, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[62], palette, &ops, "defender", .{ .from = 80, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[63], palette, &ops, "shaman", .{ .from = 80, .to = 88, .n = 8 }, 5, 0);

    try outputFrames(allocator, file, index[94], palette, &ops, "primemaker", .{ .from = 240, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[95], palette, &ops, "scrub", .{ .from = 240, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[96], palette, &ops, "weed", .{ .from = 240, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[97], palette, &ops, "scout", .{ .from = 240, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[98], palette, &ops, "squire", .{ .from = 240, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[99], palette, &ops, "druid", .{ .from = 240, .to = 88, .n = 8 }, 5, 0);

    try outputFrames(allocator, file, index[88], palette, &ops, "general", .{ .from = 64, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[89], palette, &ops, "worker", .{ .from = 64, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[90], palette, &ops, "biker", .{ .from = 64, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[91], palette, &ops, "agent", .{ .from = 64, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[92], palette, &ops, "veteran", .{ .from = 64, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[93], palette, &ops, "sorcerer", .{ .from = 64, .to = 88, .n = 8 }, 5, 0);

    try outputFrames(allocator, file, index[46], palette, &ops, "general", .{ .from = 56, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[47], palette, &ops, "worker", .{ .from = 56, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[48], palette, &ops, "biker", .{ .from = 56, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[49], palette, &ops, "agent", .{ .from = 56, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[50], palette, &ops, "veteran", .{ .from = 56, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[51], palette, &ops, "sorcerer", .{ .from = 56, .to = 88, .n = 8 }, 5, 0);

    try outputFrames(allocator, file, index[66], palette, &ops, "primeminister", .{ .from = 88, .to = 88, .n = 8 }, 5, 0);
    try outputFrames(allocator, file, index[64], palette, &ops, "primeminister", .{ .from = 88, .to = 88, .n = 8 }, 5, 0);
}

const Transpose = struct { rows: usize, cols: usize };

const Replicate = struct { items: usize, times: usize };

const Copy = struct { items: usize };

const FrameBlockOp = union(enum) { transpose: Transpose, replicate: Replicate, copy: Copy };

const RemapColors = struct { from: u8, to: u8, n: u8 };

const SpriteSheet = struct { width: usize, height: usize, pixels: []u8 };

fn outputFrames(
    allocator: std.mem.Allocator,
    file: std.fs.File,
    read_indicies: []const u32,
    operations: []const FrameBlockOp,
    remap_colors: RemapColors,
    output_cols: usize,
    out_image_frames: usize,
) !SpriteSheet {

    //*   Read sprite sheet format: *//
    var frames_arena_allocator = std.heap.ArenaAllocator.init(allocator);
    const frames_allocator = frames_arena_allocator.allocator();
    defer frames_arena_allocator.deinit();

    const frameSet: [][]Frame = try frames_allocator.alloc([]Frame, read_indicies.len);
    for (read_indicies, 0..) |offset, i| {
        frameSet[i] = try readFrames(frames_allocator, file, offset);
    }

    // const frames_alt: []Frame = try readSpriteSheet(frames_allocator, file, index[98]);

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
    for (frameSet) |frames| {
        for (frames) |f| {
            if (f.height > max_height) max_height = f.height;
            if (f.width > max_width) max_width = f.width;
        }
    }
    std.debug.print("frameSets: {d}, frame size: {d}x{d}\n", .{ frameSet.len, max_width, max_height });

    //Compute how many frames we should read and output, for proper memory allocation
    var out_frames: usize = 0;
    {
        for (frameSet) |frames| {
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
                    .copy => {
                        out_frames += o.copy.items;
                        read_frames += o.copy.items;
                    },
                }
            }
            try std.testing.expect(read_frames <= frames.len);
        }
        if (out_image_frames > out_frames) {
            out_frames = out_image_frames;
        }
        // std.debug.print("operations on {d} frames, output {d} frames\n", .{ read_frames, out_frames });
    }

    const combined_image_storage: []u8 = try allocator.alloc(u8, out_frames * max_height * max_width);
    @memset(combined_image_storage, 0);

    var cursor: usize = 0;
    var result_rows: usize = 0;
    for (frameSet) |frames| {
        var frames_done: usize = 0;
        for (operations) |o| {
            switch (o) {
                .transpose => {
                    // const frames_perm = try transpose(allocator, o.transpose.rows, o.transpose.cols, frames_done);
                    // defer allocator.free(frames_perm);
                    const frames_to_do: usize = o.transpose.cols * o.transpose.rows;
                    // write_block(o.transpose.cols, o.transpose.rows, frames, frames_perm, combined_image_storage[frames_done * max_height * max_width .. (frames_done + frames_to_do) * max_height * max_width]);
                    var chunk = try as_chunk(allocator, frames);
                    defer allocator.destroy(chunk);
                    chunk.slice(frames_done, frames_done + frames_to_do);
                    const frames_perm = try chunk.transpose(allocator, o.transpose.rows, o.transpose.cols);
                    defer allocator.free(frames_perm);
                    write_chunk(chunk, combined_image_storage, output_cols, cursor);
                    frames_done += frames_to_do;
                    result_rows += o.transpose.cols;
                    cursor += frames_to_do;
                    std.debug.print("frames done: {d}, frames to do: {d}, rows done: {d}\n", .{ frames_done, frames_to_do, result_rows });
                },
                .replicate => {
                    var chunk = try as_chunk(allocator, frames);
                    defer allocator.destroy(chunk);
                    chunk.slice(frames_done, frames_done + o.replicate.items);
                    std.debug.print("Slicing for replicate: from {d} to {d} times: {d}\n", .{ frames_done, frames_done + o.replicate.items, o.replicate.times });
                    chunk.replicate(o.replicate.times);
                    write_chunk(chunk, combined_image_storage, output_cols, cursor);
                    result_rows += o.replicate.items;
                    frames_done += o.replicate.items * o.replicate.times;
                    cursor += o.replicate.items * o.replicate.times;
                },
                .copy => {
                    var chunk = try as_chunk(allocator, frames);
                    defer allocator.destroy(chunk);
                    chunk.slice(frames_done, frames_done + o.copy.items);
                    std.debug.print("Slicing for copy: from {d} to {d}\n", .{ frames_done, frames_done + o.copy.items });
                    write_chunk(chunk, combined_image_storage, output_cols, cursor);
                    result_rows += ((frames_done + o.copy.items) / output_cols) - (frames_done / output_cols);
                    frames_done += o.copy.items;
                    cursor += o.copy.items;
                },
            }
        }
    }
    if ((out_image_frames / output_cols) > result_rows) {
        result_rows = @intFromFloat(std.math.ceil(@as(f64, @floatFromInt(out_image_frames)) / @as(f64, @floatFromInt(output_cols))));
    }
    std.debug.print("Output image frames: {d}, rows: {d}", .{ out_frames, result_rows });

    //remap
    for (0..(out_frames * max_width * max_height)) |i| {
        var target_color = combined_image_storage[i];
        if (target_color >= remap_colors.from and target_color < remap_colors.from + remap_colors.n) {
            target_color = target_color - remap_colors.from + remap_colors.to;
        } else if (target_color == 1) {
            target_color = 96;
        }
        combined_image_storage[i] = target_color;
    }

    return SpriteSheet{ .width = max_width * output_cols, .height = max_height * result_rows, .pixels = combined_image_storage };
}

fn writeImage(allocator: std.mem.Allocator, name: []const u8, width: usize, height: usize, palette: []zigimg.color.Rgba32, pixels: []u8) !void {
    var combined_image = try zigimg.Image.create(allocator, width, height, .indexed8);
    defer combined_image.deinit();
    @memcpy(combined_image.pixels.indexed8.palette, palette);
    @memcpy(combined_image.pixels.indexed8.indices, pixels);
    const dir = "C:/Projects";
    const outfile = try std.fmt.allocPrint(allocator, "{s}/{s}.png", .{ dir, name });
    defer allocator.free(outfile);
    try combined_image.writeToFilePath(outfile, .{ .png = .{} });
}

fn as_chunk(allocator: std.mem.Allocator, frames: []Frame) !*FrameChunk {
    var max_width: usize = 0;
    var max_height: usize = 0;
    for (frames) |f| {
        if (f.height > max_height) max_height = f.height;
        if (f.width > max_width) max_width = f.width;
    }
    const chunk = try allocator.create(FrameChunk);
    chunk.* = FrameChunk{
        .rows = frames.len,
        .cols = 1,
        .frame_h = max_height,
        .frame_w = max_width,
        .frames = frames,
        .len = frames.len,
    };
    return chunk;
}

fn write_chunk(chunk: *FrameChunk, storage: []u8, cols: usize, offset_frames: usize) void {
    const start_row = offset_frames / cols;
    const end_row: usize = @intFromFloat(std.math.ceil(@as(f64, @floatFromInt(offset_frames + chunk.len)) / @as(f64, @floatFromInt(cols))));

    var frame_iterator = chunk.iterate();

    // const start_offset_px = start_row * cols * chunk.frame_h * chunk.frame_w;
    // const start_offset_px = i * chunk.frame_h * chunk.frame_w + start_col * chunk.frame_w;
    for (start_row..end_row) |i| {
        const start_col: usize = if (i == start_row) offset_frames % cols else 0;
        var end_col: usize = cols;
        if (i == end_row - 1) {
            const rem = (offset_frames + chunk.len) % cols;
            if (rem != 0) end_col = rem;
        }

        for (start_col..end_col) |j| {
            std.debug.print("Put frame {d}:{d}, frame size: {d}x{d}\n", .{ i, j, chunk.frame_w, chunk.frame_h });
            const source_frame = frame_iterator.next().?;
            const frame_offset_w: usize = (chunk.frame_w - source_frame.width) / 2;
            const frame_offset_h: usize = (chunk.frame_h - source_frame.height) / 2;
            for (0..source_frame.height) |h| {
                for (0..source_frame.width) |w| {
                    const combined_image_storage_offset_h: usize = chunk.frame_w * cols * (i * chunk.frame_h + h + frame_offset_h);
                    const combined_image_storage_offset_w: usize = j * chunk.frame_w + w + frame_offset_w;
                    // const combined_image_storage_offset: usize = i * 5 * max_height * max_width + j * max_width + (h + frame_offset_h) * max_width + w + frame_offset_w;
                    const combined_image_storage_offset: usize = combined_image_storage_offset_h + combined_image_storage_offset_w;
                    const target_frame_offset = h * source_frame.width + w;
                    // if (i == 4 and j == 0 and h < 10) {
                    // std.debug.print("frame {d}:{d}, size: {d}x{d}, offsets: {d}:{d}, put: {d}:{d} => {d}:{d}, total offset: {d} \n", .{ i, j, source_frame.height, source_frame.width, frame_offset_h, frame_offset_w, h, w, combined_image_storage_offset_h, combined_image_storage_offset_w, combined_image_storage_offset });
                    // }
                    storage[combined_image_storage_offset] = source_frame.pixels[target_frame_offset];
                }
            }
        }
    }
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

fn readFrames(frames_allocator: std.mem.Allocator, file: std.fs.File, offset: u32) ![]Frame {
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

fn outputPalette(allocator: std.mem.Allocator, palette: []zigimg.color.Rgba32) void {
    // *   Output palette *//
    {
        var image = try zigimg.Image.fromRawPixels(allocator, 16, 16, @ptrCast(&palette), .rgba32);
        defer image.deinit();
        try image.writeToFilePath("C:/Projects/p1.png", .{ .png = .{} });
    }
}
