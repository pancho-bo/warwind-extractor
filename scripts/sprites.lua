function Transpose(rows, cols)
   return {transpose = {rows = rows, cols = cols}}
end

function Copy(items)
   return {copy = {items = items}}
end

function Skip(items)
   return {skip = {items = items}}
end

function Replicate(items, times)
   return {replicate = {items = items, times = times}}
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

RES001 = ResFile("C:/Program Files/GOG Galaxy/Games/War Wind/Data/RES.001")
Palette1 = Palette(RES001, 0)
local noremap = ColorRemap{ from = 88, to = 88, n = 8}

function OutDir(dir)
    return function(sprite)
        sprite.out_dir = dir
        return sprite
    end
end

function RemapColors(r)
    return function(sprite)
        sprite.color_remap = r
        return sprite
    end
end

local function map(f)
  return function(t)
    local t1 = {}
    for k,v in next, t do
      t1[k]=f(v)
    end
    return t1
  end
end

local function compose(fs)
  return function(t)
      local t1 = t
      for _,f in ipairs(fs) do
        t1 = f(t1)
      end
      return t1
  end
end

function SpritesWith(fs)
    return function (spritesF)
        local mapped = map(compose(fs))(spritesF)
        return map(SpriteSheet)(mapped)
    end
end


function UnitSprite(offset, name)
    return {
        name = name,
        columns = 5,
        rows = 12,
        out_dir = "C:/Projects/data.wwgus/graphics/ww/tharoon/units",
        color_remap = ColorRemap{ from = 88, to = 88, n = 8},
        frames = {
            Chunk{
                source = DatFile{
                    file = RES001,
                    offset = offset
                },
                transform = { Transpose(5, 4), Transpose(5, 4), Replicate(4, 5) },
                write_offset = 0
            }
        },
        palette = Palette1
    }
end

SpritesWith{
    OutDir("C:/Projects/data.wwgus/graphics/ww/tharoon/units")
} {
    UnitSprite(40, "minister"),
    UnitSprite(41, "servant"),
    UnitSprite(42, "rover"),
    UnitSprite(43, "rogue"),
    UnitSprite(44, "executioner"),
    UnitSprite(45, "psychic"),
}

SpritesWith{
    OutDir("C:/Projects/data.wwgus/graphics/ww/shamali/units"),
    RemapColors(ColorRemap{ from = 80, to = 88, n = 8})
} {
    UnitSprite(58, "dancer"),
    UnitSprite(59, "initiate"),
    UnitSprite(60, "cavalier"),
    UnitSprite(61, "disciple"),
    UnitSprite(62, "defender"),
    UnitSprite(63, "shaman")
}

SpritesWith {
    OutDir("C:/Projects/data.wwgus/graphics/ww/eaggra/units"),
    RemapColors(ColorRemap{ from = 240, to = 88, n = 8})
} {
    UnitSprite(94, "primemaker"),
    UnitSprite(95, "scrub"),
    UnitSprite(96, "weed"),
    UnitSprite(97, "scout"),
    UnitSprite(98, "squire"),
    UnitSprite(99, "druid"),
}

SpritesWith {
    OutDir("C:/Projects/data.wwgus/graphics/ww/obblinox/units"),
    RemapColors(ColorRemap{ from = 64, to = 88, n = 8})
} {
    UnitSprite(88, "general"),
    UnitSprite(89, "worker"),
    UnitSprite(90, "biker"),
    UnitSprite(91, "agent"),
    UnitSprite(92, "veteran"),
    UnitSprite(93, "sorcerer")
}

-- UI
SpriteSheet{
    name = "cross",
    columns = 1,
    rows = 8,
    out_dir = "C:/Projects/data.wwgus/graphics/ui/ww",
    color_remap = noremap,
    frames = {
        Chunk{
            source = DatFile{
                file = RES001,
                offset = 192
            },
            transform = { Copy(8) },
            write_offset = 0
        }
    },
    palette = Palette1
}

SpriteSheet{
    name = "cursor",
    columns = 1,
    rows = 1,
    out_dir = "C:/Projects/data.wwgus/graphics/ui/ww/tharoon",
    color_remap = noremap,
    frames = {
        Chunk{
            source = DatFile{
                file = RES001,
                offset = 185
            },
            transform = { Copy(1) },
            write_offset = 0
        }
    },
    palette = Palette1
}

SpriteSheet{
    name = "mainpanel",
    columns = 1,
    rows = 1,
    out_dir = "C:/Projects/data.wwgus/graphics/ui/ww/tharoon",
    color_remap = noremap,
    frames = {
        Chunk{
            source = DatFile{
                file = RES001,
                offset = 193
            },
            transform = { Copy(1) },
            write_offset = 0
        }
    },
    palette = Palette1
}

SpriteSheet{
    name = "statusline",
    columns = 1,
    rows = 1,
    out_dir = "C:/Projects/data.wwgus/graphics/ui/ww/tharoon",
    color_remap = noremap,
    frames = {
        Chunk{
            source = DatFile{
                file = RES001,
                offset = 193
            },
            transform = { Skip(1), Copy(1) },
            write_offset = 0
        }
    },
    palette = Palette1
}

SpriteSheet{
    name = "infopanel",
    columns = 1,
    rows = 1,
    out_dir = "C:/Projects/data.wwgus/graphics/ui/ww/tharoon",
    color_remap = noremap,
    frames = {
        Chunk{
            source = DatFile{
                file = RES001,
                offset = 193
            },
            transform = { Skip(21), Copy(1) },
            write_offset = 0
        }
    },
    palette = Palette1
}

-- Tilesets

SpriteSheet{
    name = "swamp",
    columns = 16,
    rows = 32,
    out_dir = "C:/Projects/data.wwgus/graphics/ww/tilesets/swamp",
    color_remap = ColorRemap{ from = 88, to = 88, n = 8},
    frames = {
        Chunk{source = DatFile{ file = RES001, offset = 3},  transform = {Copy(4)} },
        Chunk{source = DatFile{ file = RES001, offset = 6},  transform = {Copy(4)} },
        Chunk{source = DatFile{ file = RES001, offset = 9},  transform = {Copy(4)} },
        Chunk{source = DatFile{ file = RES001, offset = 10}, transform = {Copy(4)} },
        Chunk{source = DatFile{ file = RES001, offset = 11}, transform = {Copy(4)} },
        Chunk{source = DatFile{ file = RES001, offset = 12}, transform = {Copy(4)} },
        Chunk{source = DatFile{ file = RES001, offset = 13}, transform = {Copy(56)} } ,
        Chunk{source = DatFile{ file = RES001, offset = 3},  transform = {Replicate(1, 56)} },
        Chunk{source = DatFile{ file = RES001, offset = 15}, transform = {Copy(56)}, write_offset = -56 },
        Chunk{source = DatFile{ file = RES001, offset = 9},  transform = {Replicate(1, 56)}},
        Chunk{source = DatFile{ file = RES001, offset = 15}, transform = {Copy(56)}, write_offset = -56 },
        Chunk{source = DatFile{ file = RES001, offset = 10}, transform = {Replicate(1, 56)}},
        Chunk{source = DatFile{ file = RES001, offset = 16}, transform = {Copy(56)}, write_offset = -56 },
        Chunk{source = DatFile{ file = RES001, offset = 17}, transform = {Copy(56)} },
    },
    palette = Palette1
}