function Transpose(rows, cols)
   return {"transpose", rows, cols}
end

function Copy(frames)
   return {copy = {items = frames}}
end

function Replicate(rows, cols)
   return {"replicate", rows, cols}
end

function DatFile(x) 
    return x
end

function Chunk(x)
    return x
end

function ColorRemap(x)
    return x
end

function Transform(x)
    return x
end



-- function Frames(f)
--     return f
-- end

-- function Unit(u)
--     return u
-- end

-- TharoonUnits = {
--     Unit {
--         name = "minister",
--         data_index = 40,
--         frames = Frames { Transpose(5, 4), Transpose(5, 4), Replicate(4, 5) }
--     },
--     Unit {
--         name = "servant",
--         data_index = 41,
--         frames = Frames { Transpose(5, 4), Transpose(5, 4), Replicate(4, 5) }
--     },
--     Unit {
--         name = "rover",
--         data_index = 42,
--         frames = Frames { Transpose(5, 4), Transpose(5, 4), Replicate(5, 5) }
--     },
--     Unit {
--         name = "rogue",
--         data_index = 43,
--         frames = Frames { Transpose(5, 4), Transpose(5, 4), Replicate(4, 5) }
--     },
--     Unit {
--         name = "executioner",
--         data_index = 44,
--         frames = Frames { Transpose(5, 4), Transpose(5, 4), Replicate(4, 5) }
--     },
--     Unit {
--         name = "psychic",
--         data_index = 45,
--         frames = Frames { Transpose(5, 4), Transpose(5, 4), Replicate(4, 5) }
--     }
-- }

-- function DatFile (t)
--     return function (f)
--         -- f(read_file(t.name, t.offset))
--         read_file(f, t.name, t.offset)
--     end
-- end

-- function SpriteSheet (t)
--     -- return function (f)
--     --     -- f(read_file(t.name, t.offset))
--     --     write_file(f, t.name, t.offset)
--     -- end
--     t.frames[1].source(write_file(t.name))
-- end

-- SpriteSheet{
--     name = "minister",
--     columns = 5,
--     rows = 12,
--     out_dir = "C:/data.wwgus/graphics/ww/tharoon",
--     frames = {
--         Chunk{
--             source = DatFile{
--                 name = "RES.001",
--                 offset = 40
--             },
--             transform = { Transpose(5, 4), Transpose(5, 4), Replicate(4, 5) },
--             color_remap = ColorRemap{ from_base = 88, to_base = 88, colors = 8},
--             write_offset = 0
--         }
--     }
-- }

local res001 = ResFile("C:/Program Files/GOG Galaxy/Games/War Wind/Data/RES.001")
local palette = Palette(res001, 0)

SpriteSheet{
    name = "cross",
    columns = 1,
    rows = 8,
    out_dir = "C:/Projects/data.wwgus/graphics/ui/ww",
    frames = {
        Chunk{
            source = DatFile{
                file = res001,
                offset = 40
            },
            transform = { Copy(8) },
            color_remap = ColorRemap{ from_base = 88, to_base = 88, colors = 8},
            write_offset = 0
        }
    },
    palette = palette
}

-- SpriteSheet{
--     name = "tiles",
--     columns = 16,
--     rows = 20,
--     frames = {
--         Chunk{
--             source = DatFile{
--                 name = "RES.001",
--                 offset = 3
--             },
--             write_offset = 16
--         }
--     }
-- }
