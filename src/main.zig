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
    const palette_index: usize = @intCast(try lua.toInteger(-1));
    lua.pop(1);

    // _ = try lua.getGlobal("Rogue");
    // const rogue_lua: usize = @intCast(try lua.toInteger(-1));
    // _ = rogue_lua;
    // lua.pop(1);

    // const t = try lua.getGlobal("TharoonUnits");
    // std.testing.expect(t == .table);

    // lua.rawGetIndex();

    const data_file_name = "C:/Program Files/GOG Galaxy/Games/War Wind/Data/RES.001";
    // const data_file_name = "C:/Program Files/GOG Galaxy/Games/War Wind/Editor/Data/RES.005";

    const file = try std.fs.cwd().openFile(data_file_name, .{ .mode = .read_only });
    defer file.close();

    //Somehow it should be clear that index starts at file offset 0, maybe wrap it into struct D3GR with init?
    const index: []u32 = try readIndex(allocator, file.reader());
    defer allocator.free(index);

    try file.seekTo(index[palette_index]);
    const palette: []color.Rgba32 = try readPalette(allocator, file.reader());
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

    // const ops = [_]FrameBlockOp{.{ .copy = .{ .items = 4 } }};
    const ops = copy(4);
    const copy56 = [_]FrameBlockOp{.{ .copy = .{ .items = 56 } }};
    const replicate56 = [_]FrameBlockOp{.{ .replicate = .{ .items = 1, .times = 56 } }};
    const ops3 = &[_]FrameBlockOp{
        .{ .copy = .{ .items = 34 } },
        .{ .skip = .{ .items = 4 } },
        .{ .copy = .{ .items = 18 } },
    };
    const noremap: RemapColors = .{ .from = 88, .to = 88, .n = 8 };
    _ = ops3;
    // allocate pixels, how to get size???
    // sprite_sheet(name, w, h).from[frames(at_index)(+w,+h).chunks[], frames[at_index](+w, +h).chunks[]]
    //(read frames(+fsize), apply ops(+image_len) => chunk), write_chunk at offset(+image_size), write_pixels, write image

    var frames_arena_allocator = std.heap.ArenaAllocator.init(allocator);
    defer frames_arena_allocator.deinit();
    const fa = frames_arena_allocator.allocator();

    var tilesIndex: TilesIndex = std.AutoHashMap(u8, usize).init(allocator);
    defer tilesIndex.deinit();

    try tilesIndex.put(0xF0, 0x30); //coast
    try tilesIndex.put(0xF3, 0x40); //light snow
    try tilesIndex.put(0xF6, 0x60); //dark marsh
    try tilesIndex.put(0xF7, 0x50); //light marsh
    try tilesIndex.put(0xF8, 0x20); //dark water
    try tilesIndex.put(0xF9, 0x10); //light water
    try tilesIndex.put(0x09, 0x200); //coast - light water
    try tilesIndex.put(0x20, 0x500); //light marsh - coast
    try tilesIndex.put(0x26, 0x600); //light marsh - dark marsh
    try tilesIndex.put(0x37, 0x300); //light snow - light marsh
    try tilesIndex.put(0x49, 0x100); //light water - dark water
    // 0 - coast
    // 1 - ice
    // 2 - dark snow
    // 3 - light snow
    // 4 - dark steppe
    // 5 - dark steppe
    // 6 - dark marsh
    // 7 - light marsh
    // 8 - dark water
    // 9 - light water

    // 0 - coast [with light water]
    // 1 - light steppe
    // 2 - light marsh
    // 3 - light snow
    // 4 - light water [with dark water]
    // 5 - ice [with light water]
    //15 - no corner needed, just base tile

    //indices point to images packed in a .RES file
    const sources = [_]Output{
        .{ .transform = .{ .frames = try from(fa, file, index[3]), .ops = &ops } },
        .{ .transform = .{ .frames = try from(fa, file, index[6]), .ops = &ops } },
        .{ .transform = .{ .frames = try from(fa, file, index[9]), .ops = &ops } },
        .{ .transform = .{ .frames = try from(fa, file, index[10]), .ops = &ops } },
        .{ .transform = .{ .frames = try from(fa, file, index[11]), .ops = &ops } },
        .{ .transform = .{ .frames = try from(fa, file, index[12]), .ops = &ops } },
        .{ .transform = .{ .frames = try from(fa, file, index[13]), .ops = &copy56 } },
        .{ .transform = .{ .frames = try from(fa, file, index[3]), .ops = &replicate56 } },
        .{ .offset = .{ .frames = -56 } },
        .{ .transform = .{ .frames = try from(fa, file, index[15]), .ops = &copy56 } },
        .{ .transform = .{ .frames = try from(fa, file, index[9]), .ops = &replicate56 } },
        .{ .offset = .{ .frames = -56 } },
        .{ .transform = .{ .frames = try from(fa, file, index[15]), .ops = &copy56 } },
        .{ .transform = .{ .frames = try from(fa, file, index[10]), .ops = &replicate56 } },
        .{ .offset = .{ .frames = -56 } },
        .{ .transform = .{ .frames = try from(fa, file, index[16]), .ops = &copy56 } },
        .{ .transform = .{ .frames = try from(fa, file, index[17]), .ops = &copy56 } },
    };

    // _ = sources;
    const sprite_sheet = try outputFrames(allocator, &sources, noremap, 16, 512);
    defer allocator.free(sprite_sheet.pixels);

    try writeImage(allocator, "tundra", sprite_sheet.width, sprite_sheet.height, palette[0..256], sprite_sheet.pixels);

    // const map_dir_name = "C:/Program Files/GOG Galaxy/Games/War Wind/Data/NETWORK";
    // const map_dir = try std.fs.openDirAbsolute(map_dir_name, .{ .iterate = true });
    // var files = map_dir.iterate();
    // while (try files.next()) |f| {
    //     switch (f.kind) {
    //         .file => {
    //             std.debug.print("{s}", .{f.name});
    //             const full_file_name = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ map_dir_name, f.name });
    //             defer allocator.free(full_file_name);
    //             var file1 = try std.fs.cwd().openFile(full_file_name, .{ .mode = .read_only });
    //             defer file1.close();
    //             try getTerrain(allocator, file1);
    //         },
    //         else => continue,
    //     }
    // }

    const lvlfile = "C:/Program Files/GOG Galaxy/Games/War Wind/Data/NETWORK/BLANK01.LVL";
    var file1 = try std.fs.cwd().openFile(lvlfile, .{ .mode = .read_only });
    defer file1.close();

    try getTerrain(allocator, file1, tilesIndex);

    const cross_source = [_]Output{
        .{ .transform = .{ .frames = try from(fa, file, index[192]), .ops = &copy(8) } },
    };
    const cross_image = try outputFrames(allocator, &cross_source, noremap, 1, 8);
    defer allocator.free(cross_image.pixels);

    try writeImage(allocator, "cross", cross_image.width, cross_image.height, palette[0..256], cross_image.pixels);
}

fn copy(items: comptime_int) [1]FrameBlockOp {
    return [_]FrameBlockOp{.{ .copy = .{ .items = items } }};
}

const TilesIndex = std.AutoHashMap(u8, usize);
pub fn getTerrain(allocator: std.mem.Allocator, file: std.fs.File, tilesIndex: TilesIndex) !void {
    const data = file.reader();

    const header: [6]u8 = try data.readBytesNoEof(6);
    // std.debug.print("{s}\n", .{header});
    std.debug.assert(std.mem.eql(u8, &header, "WARMAP"));

    //Should be 1
    const levelInfo = try data.readInt(u32, .little);
    std.debug.assert(levelInfo == 1);
    // std.debug.print("levelInfo: {d}\n", .{levelInfo});

    // base tiles as of RES.005
    // in_lvl_file offset_res.005 name
    // 0   1 - coast
    // 1   2 - ice
    // 2   3 - dark snow
    // 3   4 - light snow
    // 4   5 - dark steppe
    // 5   6 - dark steppe
    // 6   7 - dark marsh
    // 7   8 - light marsh
    // 8   9 - dark water
    // 9  10 - light water
    var base_tiles: []u8 = undefined;
    defer allocator.free(base_tiles);
    {
        const record_size_bytes = try data.readInt(u32, .little);
        const records = try data.readInt(u32, .little);
        _ = record_size_bytes;
        base_tiles = try allocator.alloc(u8, records);
        // std.debug.print("{d}:{d}\n", .{ record_size_bytes, records });

        std.debug.print("base tiles set: ", .{});
        for (0..records) |i| {
            const x: u8 = try data.readInt(u8, .little);
            base_tiles[i] = x;
            std.debug.print("{d}, ", .{x});
        }
        // std.debug.print("\n", .{});
    }

    // corner tiles as of RES.005
    // in_lvl_file offset_res.005 name
    // 0  19 - coast [with light water]
    // 1  20 - light steppe
    // 2  21 - light marsh
    // 3  22 - light snow
    // 4  23 - light water [with dark water]
    // 5  24 - ice [with light water]
    //15  15 - no corner needed, just base tile
    var corner_tiles: []u8 = undefined;
    defer allocator.free(corner_tiles);
    {
        const record_size_bytes = try data.readInt(u32, .little);
        const records = try data.readInt(u32, .little);
        _ = record_size_bytes;
        corner_tiles = try allocator.alloc(u8, records);
        // std.debug.print("{d}:{d}\n", .{ record_size_bytes, records });

        std.debug.print("corner tiles set: ", .{});
        for (0..records) |i| {
            const x: u8 = try data.readInt(u8, .little);
            corner_tiles[i] = x;
            std.debug.print("{d}, ", .{x});
        }
        std.debug.print("\n", .{});
    }

    var map_terrain: []MapTile = undefined;
    defer allocator.free(map_terrain);
    {
        const record_size_bytes = try data.readInt(u32, .little);
        const records = try data.readInt(u32, .little);
        map_terrain = try allocator.alloc(MapTile, records);
        std.debug.print("Records: {d}, record size: {d}\n", .{ records, record_size_bytes });

        // std.debug.print("map terrain: \n", .{});
        for (0..(records), 0..) |i, n| {
            const x: u16 = try data.readInt(u16, .little);
            var tile = @as(MapTile, @bitCast(x));
            tile.base_tile = @as(u4, @intCast(base_tiles[tile.base_tile]));
            if (tile.corner_tile != 0xF) {
                tile.corner_tile = @as(u4, @intCast(corner_tiles[tile.corner_tile]));
            }
            map_terrain[i] = tile;
            if (n < 10) {
                std.debug.print("code: {x}, base: {d}:{d}, corner: {d}:{d}\n", .{ x, tile.base_tile, tile.base_tile_index, tile.corner_tile, tile.corner_tile_index });
            }
        }
        // std.debug.print("\n", .{});
    }

    const outfile_name = "C:/Projects/map.txt";
    var f = try std.fs.createFileAbsolute(outfile_name, .{ .truncate = true });
    f.close();
    var outfile = try std.fs.openFileAbsolute("C:/Projects/map.txt", .{ .mode = .write_only });
    defer outfile.close();
    const writer = outfile.writer();
    for (map_terrain, 0..) |tile, i| {
        const key: u8 = @as(u8, @intCast(tile.corner_tile)) << 4 | @as(u8, @intCast(tile.base_tile));
        if (tilesIndex.get(key)) |tile_group_offset| {
            const row = (i / 96) * 2;
            const column = (i % 96) * 2;
            const tile_frame_offset = if (tile.corner_tile == 0xF) @as(usize, tile.base_tile_index) else @as(usize, tile.corner_tile_index);
            const tile_number = tile_group_offset + tile_frame_offset;

            const s = try std.fmt.allocPrint(allocator, "SetTile( {d}, {d}, {d}, 0, 0)\n", .{ tile_number, column, row });
            if (i < 10) {
                std.debug.print("SetTile( {d}, {d}, {d}, 0, 0)\n", .{ tile_number, column, row });
            }
            _ = try writer.write(s);
            allocator.free(s);
        } else {
            std.debug.print("Can't get tile offset for key {x}\n", .{key});
        }
    }
}

const MapTile = packed struct {
    base_tile_index: u2,
    base_tile: u4,
    corner_tile_index: u6,
    corner_tile: u4,
};

pub fn from(a: std.mem.Allocator, file: std.fs.File, offset: u32) ![]const Frame {
    try file.seekTo(offset);
    return readD3GR(a, file.reader());
}

const Output = union(enum) {
    transform: Transform,
    seek: Seek,
    offset: Offset,
};

const Transform = struct {
    frames: []const Frame,
    ops: []const FrameBlockOp,
};

const Seek = struct { to_frame: usize };
const Offset = struct { frames: isize };

pub fn readIndex(a: std.mem.Allocator, data: std.fs.File.Reader) ![]u32 {
    const num_nodes = try data.readInt(u32, .little);
    std.debug.print("Number of nodes: {d}\n", .{num_nodes});
    var index: []u32 = try a.alloc(u32, num_nodes);

    for (0..num_nodes) |i| {
        const next_node_position: u32 = try data.readInt(u32, .little);
        index[i] = next_node_position;
        // std.debug.print("Node {d}: offset: {X}\n", .{ i, next_node_position });
        // try bw.flush(); // Don't forget to flush!
        // try data.skipBytes(next_node_position - current_position, .{});
    }
    return index;
}

pub fn readPalette(allocator: std.mem.Allocator, data: std.fs.File.Reader) ![]color.Rgba32 {
    const d3gr: [4]u8 = try data.readBytesNoEof(4);
    try std.testing.expect(std.mem.eql(u8, &d3gr, "D3GR"));

    _ = try data.readInt(u32, .little); //0x2001
    _ = try data.readInt(u32, .little); //frames_start
    const palette_start = try data.readInt(u32, .little);

    //read 12 bytes from the start already
    try data.skipBytes(palette_start - 12, .{});

    const palette: []zigimg.color.Rgba32 = try allocator.alloc(color.Rgba32, 256);
    {
        for (0..256) |i| {
            const r: u8 = try data.readByte() << 2;
            const g: u8 = try data.readByte() << 2;
            const b: u8 = try data.readByte() << 2;
            const a: u8 = if (i == 0) 0 else 0xff; // Zero color is transparent
            palette[i] = color.Rgba32.initRgba(@intCast(r), @intCast(g), @intCast(b), @intCast(a));
        }
    }
    return palette;
}

const FrameIterator = struct {
    i: usize,
    frames: []const Frame,
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
    offset_h_min: usize,
    offset_w_min: usize,
    frames: []const Frame,
    perm: ?[]usize = null,
    repl_n: ?usize = null,
    len: usize,

    pub fn iterate(self: *FrameChunk) FrameIterator {
        return FrameIterator{ .i = 0, .frames = self.frames, .perm = self.perm, .j = 0, .replicate = self.repl_n };
    }

    pub fn slice(self: *FrameChunk, from_frame: usize, to: usize) void {
        self.frames = self.frames[from_frame..to];
        self.len = to - from_frame;
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
const Frame = struct { width: u16, height: u16, offset_w: u16, offset_h: u16, pixels: []u8 };

fn doUnits(allocator: std.mem.Allocator, file: std.fs.File, index: []u32, palette: [256]color.Rgba32) !void {
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
const Skip = struct { items: usize };

const FrameBlockOp = union(enum) { transpose: Transpose, replicate: Replicate, copy: Copy, skip: Skip };

const RemapColors = struct { from: u8, to: u8, n: u8 };

const SpriteSheet = struct { width: usize, height: usize, pixels: []u8 };

const ReadFrames = struct { from: u32, ops: []FrameBlockOp };

fn outputFrames(
    allocator: std.mem.Allocator,
    sources: []const Output,
    remap_colors: RemapColors,
    output_cols: usize,
    out_image_frames: usize,
) !SpriteSheet {
    //why there is a need to calculate these twice?
    var max_width: usize = 0;
    var max_height: usize = 0;
    var offset_h_min: usize = 0xFFFF_FFFF;
    var offset_w_min: usize = 0xFFFF_FFFF;
    for (sources) |source| {
        switch (source) {
            .transform => for (source.transform.frames) |f| {
                if (f.offset_h < offset_h_min) offset_h_min = f.offset_h;
                if (f.offset_w < offset_w_min) offset_w_min = f.offset_w;
            },
            else => {},
        }
    }
    for (sources) |source| {
        switch (source) {
            .transform => for (source.transform.frames) |f| {
                if (f.height + f.offset_h - offset_h_min > max_height) max_height = f.height + f.offset_h - offset_h_min;
                if (f.width + f.offset_w - offset_h_min > max_width) max_width = f.width + f.offset_w - offset_w_min;
            },
            else => {},
        }
    }
    std.debug.print("frameSets: {d}, frame size: {d}x{d}\n", .{ sources.len, max_width, max_height });

    //Compute how many frames we should read and output, for proper memory allocation
    var out_frames: usize = 0;
    {
        for (sources) |source| {
            switch (source) {
                .transform => {
                    var read_frames: usize = 0;
                    for (source.transform.ops) |o| {
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
                            .skip => {
                                read_frames += o.skip.items;
                            },
                        }
                    }
                    try std.testing.expect(read_frames <= source.transform.frames.len);
                },
                .offset => out_frames = @intCast(@as(isize, @intCast(out_frames)) + source.offset.frames),
                .seek => out_frames = source.seek.to_frame,
            }
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
    for (sources) |source| {
        switch (source) {
            .transform => {
                var frames_done: usize = 0;
                for (source.transform.ops) |o| {
                    switch (o) {
                        .transpose => {
                            // const frames_perm = try transpose(allocator, o.transpose.rows, o.transpose.cols, frames_done);
                            // defer allocator.free(frames_perm);
                            const frames_to_do: usize = o.transpose.cols * o.transpose.rows;
                            // write_block(o.transpose.cols, o.transpose.rows, frames, frames_perm, combined_image_storage[frames_done * max_height * max_width .. (frames_done + frames_to_do) * max_height * max_width]);
                            var chunk = try as_chunk(allocator, source.transform.frames);
                            defer allocator.destroy(chunk);
                            chunk.slice(frames_done, frames_done + frames_to_do);
                            const frames_perm = try chunk.transpose(allocator, o.transpose.rows, o.transpose.cols);
                            defer allocator.free(frames_perm);
                            write_chunk(chunk, combined_image_storage, output_cols, cursor);
                            result_rows += ((frames_done + frames_to_do) / output_cols) - (frames_done / output_cols);
                            frames_done += frames_to_do;
                            cursor += frames_to_do;
                            std.debug.print("frames done: {d}, frames to do: {d}, rows done: {d}\n", .{ frames_done, frames_to_do, result_rows });
                        },
                        .replicate => {
                            var chunk = try as_chunk(allocator, source.transform.frames);
                            defer allocator.destroy(chunk);
                            chunk.slice(frames_done, frames_done + o.replicate.items);
                            std.debug.print("Slicing for replicate: from {d} to {d} times: {d}\n", .{ frames_done, frames_done + o.replicate.items, o.replicate.times });
                            chunk.replicate(o.replicate.times);
                            write_chunk(chunk, combined_image_storage, output_cols, cursor);
                            result_rows += ((frames_done + o.replicate.items) / output_cols) - (frames_done / output_cols);
                            frames_done += o.replicate.items * o.replicate.times;
                            cursor += o.replicate.items * o.replicate.times;
                        },
                        .copy => {
                            var chunk = try as_chunk(allocator, source.transform.frames);
                            defer allocator.destroy(chunk);
                            chunk.slice(frames_done, frames_done + o.copy.items);
                            std.debug.print("Slicing for copy: from {d} to {d}\n", .{ frames_done, frames_done + o.copy.items });
                            write_chunk(chunk, combined_image_storage, output_cols, cursor);
                            result_rows += ((frames_done + o.copy.items) / output_cols) - (frames_done / output_cols);
                            frames_done += o.copy.items;
                            cursor += o.copy.items;
                        },
                        .skip => {
                            frames_done += o.skip.items;
                            result_rows += ((frames_done + o.skip.items) / output_cols) - (frames_done / output_cols);
                            std.debug.print("skip frames: {d}, new cursor: {d}\n", .{ o.skip.items, cursor });
                        },
                    }
                }
            },
            .offset => {
                cursor = @intCast(@as(isize, @intCast(cursor)) + source.offset.frames);
                std.debug.print("Cursor offset of: {d}, new cursor: {d}\n", .{ source.offset.frames, cursor });
            },
            .seek => cursor = source.seek.to_frame,
        }
    }
    if ((out_image_frames / output_cols) > result_rows) {
        result_rows = @intFromFloat(std.math.ceil(@as(f64, @floatFromInt(out_image_frames)) / @as(f64, @floatFromInt(output_cols))));
    }
    std.debug.print("Output image frames: {d}, rows: {d}", .{ out_frames, result_rows });

    //remap colors
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

fn writeImage(allocator: std.mem.Allocator, name: []const u8, width: usize, height: usize, palette: []color.Rgba32, pixels: []u8) !void {
    var combined_image = try zigimg.Image.create(allocator, width, height, .indexed8);
    defer combined_image.deinit();
    @memcpy(combined_image.pixels.indexed8.palette, palette);
    @memcpy(combined_image.pixels.indexed8.indices, pixels);
    const dir = "C:/Projects";
    const outfile = try std.fmt.allocPrint(allocator, "{s}/{s}.png", .{ dir, name });
    defer allocator.free(outfile);
    try combined_image.writeToFilePath(outfile, .{ .png = .{} });
}

fn as_chunk(allocator: std.mem.Allocator, frames: []const Frame) !*FrameChunk {
    var max_width: usize = 0;
    var max_height: usize = 0;
    var offset_h_min: usize = 0xFFFF_FFFF;
    var offset_w_min: usize = 0xFFFF_FFFF;
    for (frames) |f| {
        if (f.offset_h < offset_h_min) offset_h_min = f.offset_h;
        if (f.offset_w < offset_w_min) offset_w_min = f.offset_w;
    }
    for (frames) |f| {
        if (f.height + f.offset_h - offset_h_min > max_height) max_height = f.height + f.offset_h - offset_h_min;
        if (f.width + f.offset_w - offset_w_min > max_width) max_width = f.width + f.offset_w - offset_w_min;
    }
    const chunk = try allocator.create(FrameChunk);
    chunk.* = FrameChunk{
        .rows = frames.len,
        .cols = 1,
        .frame_h = max_height,
        .frame_w = max_width,
        .offset_h_min = offset_h_min,
        .offset_w_min = offset_w_min,
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
            // std.debug.print("Put frame {d}:{d}, frame size: {d}x{d}\n", .{ i, j, chunk.frame_w, chunk.frame_h });
            const source_frame = frame_iterator.next().?;
            // const frame_offset_w: usize = (chunk.frame_w - source_frame.width) / 2;
            // const frame_offset_h: usize = (chunk.frame_h - source_frame.height) / 2;
            const frame_offset_w: usize = source_frame.offset_w - chunk.offset_w_min;
            const frame_offset_h: usize = source_frame.offset_h - chunk.offset_h_min;
            for (0..source_frame.height) |h| {
                for (0..source_frame.width) |w| {
                    const combined_image_storage_offset_h: usize = chunk.frame_w * cols * (i * chunk.frame_h + h + frame_offset_h);
                    const combined_image_storage_offset_w: usize = j * chunk.frame_w + w + frame_offset_w;
                    // const combined_image_storage_offset: usize = i * 5 * max_height * max_width + j * max_width + (h + frame_offset_h) * max_width + w + frame_offset_w;
                    const combined_image_storage_offset: usize = combined_image_storage_offset_h + combined_image_storage_offset_w;
                    const target_frame_offset = h * source_frame.width + w;
                    if (j == 0 and h < 1) {
                        std.debug.print("frame {d}:{d}, size: {d}x{d}, offsets: {d}:{d}, put: {d}:{d} => {d}:{d}, total offset: {d} \n", .{ i, j, source_frame.height, source_frame.width, frame_offset_h, frame_offset_w, h, w, combined_image_storage_offset_h, combined_image_storage_offset_w, combined_image_storage_offset });
                    }
                    if (source_frame.pixels[target_frame_offset] != 0) {
                        storage[combined_image_storage_offset] = source_frame.pixels[target_frame_offset];
                    }
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

fn readD3GR(frames_allocator: std.mem.Allocator, data: std.fs.File.Reader) ![]Frame {
    const header: [4]u8 = try data.readBytesNoEof(4);
    try std.testing.expect(std.mem.eql(u8, &header, "D3GR"));
    _ = try data.readInt(u32, .little); //?
    const frames_start = try data.readInt(u32, .little);
    _ = try data.readInt(u32, .little); //palette_start
    _ = try data.readInt(u32, .little); //?
    _ = try data.readInt(u32, .little); //?
    const frames_num: u16 = try data.readInt(u16, .little);

    try data.skipBytes(frames_start - 26, .{});

    var frames: []Frame = try frames_allocator.alloc(Frame, frames_num);

    {
        var i: usize = 0;
        while (i < frames_num) : (i += 1) {
            _ = try data.readInt(u32, .little); //frame_size

            _ = try data.readInt(u32, .little); //?
            const offset_w = try data.readInt(u16, .little); //?
            const offset_h = try data.readInt(u16, .little); //?

            const height: u16 = try data.readInt(u16, .little);
            const width: u16 = try data.readInt(u16, .little);
            // std.debug.print("Frame {d}: {} {} o_w: {} o_h: {} width: {d}, height: {d}\n", .{ i, x1, x2, offset_w, offset_h, width, height });
            var pixels: []u8 = try frames_allocator.alloc(u8, width * height);
            {
                var j: usize = 0;
                while (j < width * height) : (j += 1) {
                    pixels[j] = try data.readByte();
                }
            }
            frames[i] = Frame{ .width = width, .height = height, .offset_w = offset_w, .offset_h = offset_h, .pixels = pixels };
        }
    }
    return frames;
}

fn outputPalette(allocator: std.mem.Allocator, palette: []color.Rgba32) void {
    {
        var image = try zigimg.Image.fromRawPixels(allocator, 16, 16, @ptrCast(&palette), .rgba32);
        defer image.deinit();
        try image.writeToFilePath("C:/Projects/p1.png", .{ .png = .{} });
    }
}

const std = @import("std");
const zigimg = @import("zigimg");
const color = zigimg.color;
const zlua = @import("zlua");
const Lua = zlua.Lua;
