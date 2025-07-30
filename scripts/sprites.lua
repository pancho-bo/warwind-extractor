function Transpose(rows, cols)
   return {transpose = {rows = rows, cols = cols}}
end

function Copy(items)
   return {copy = {items = items}}
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

local res001 = ResFile("C:/Program Files/GOG Galaxy/Games/War Wind/Data/RES.001")
local palette = Palette(res001, 0)

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
                    file = res001,
                    offset = offset
                },
                transform = { Transpose(5, 4), Transpose(5, 4), Replicate(4, 5) },
                write_offset = 0
            }
        },
        palette = palette
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


SpriteSheet{
    name = "cross",
    columns = 1,
    rows = 8,
    out_dir = "C:/Projects/data.wwgus/graphics/ui/ww",
    color_remap = ColorRemap{ from = 88, to = 88, n = 8},
    frames = {
        Chunk{
            source = DatFile{
                file = res001,
                offset = 192
            },
            transform = { Copy(8) },
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
