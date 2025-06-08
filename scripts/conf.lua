Infile = "C:/Projects/data.wwgus/graphics/missiles/ww/shamali_missile.png"

Palette = 0

function Transpose(rows, cols)
   return {"transpose", rows, cols}
end

function Replicate(rows, cols)
   return {"replicate", rows, cols}
end

function Frames(f)
    return f
end

function Unit(u)
    return u
end

TharoonUnits = {
    Unit {
        name = "minister",
        data_index = 40,
        frames = Frames { Transpose(5, 4), Transpose(5, 4), Replicate(4, 5) }
    },
    Unit {
        name = "servant",
        data_index = 41,
        frames = Frames { Transpose(5, 4), Transpose(5, 4), Replicate(4, 5) }
    },
    Unit {
        name = "rover",
        data_index = 42,
        frames = Frames { Transpose(5, 4), Transpose(5, 4), Replicate(5, 5) }
    },
    Unit {
        name = "rogue",
        data_index = 43,
        frames = Frames { Transpose(5, 4), Transpose(5, 4), Replicate(4, 5) }
    },
    Unit {
        name = "executioner",
        data_index = 44,
        frames = Frames { Transpose(5, 4), Transpose(5, 4), Replicate(4, 5) }
    },
    Unit {
        name = "psychic",
        data_index = 45,
        frames = Frames { Transpose(5, 4), Transpose(5, 4), Replicate(4, 5) }
    }
}