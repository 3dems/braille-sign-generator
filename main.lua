--[[
    3DEMS Braille Tactile Sign Generator
    Plugin para PrusaSlicer 3.0+
    Autor: 3DEMS (Author ID: 9d2f6477-ddc2-4189-b873-d0026dd7a4ef)
    Estándar: Norma Marburg Medium para señalización táctil accesible
--]]

info = {
    id = "braille_sign_generator",
    type = "project.plugin",
    title = "Braille Tactile Sign",
    menu = "3DEMS/Braille Tactile Sign",
    params = {
        {name = "text", label = "Texto a traducir", type = "string", default = "SALIDA"},
        {name = "include_visual_text", label = "Incluir texto visual debajo", type = "bool", default = true},
        {name = "mounting_holes", label = "Orificios para tornillos M3 (3.2 mm)", type = "bool", default = false},
        {name = "base_thickness", label = "Grosor de la base [mm]", type = "float", default = 2.4},
        {name = "dot_height", label = "Altura de puntos Braille [mm]", type = "float", default = 0.6}
    }
}

-- Mapeo completo de celdas Braille estándar (6 puntos)
-- Columna 1 (izq): 1, 2, 3
-- Columna 2 (der): 4, 5, 6
local BRAILLE_MAP = {
    -- Letras básicas (minúsculas y mayúsculas ASCII)
    ['a'] = {1}, ['A'] = {1},
    ['b'] = {1, 2}, ['B'] = {1, 2},
    ['c'] = {1, 4}, ['C'] = {1, 4},
    ['d'] = {1, 4, 5}, ['D'] = {1, 4, 5},
    ['e'] = {1, 5}, ['E'] = {1, 5},
    ['f'] = {1, 2, 4}, ['F'] = {1, 2, 4},
    ['g'] = {1, 2, 4, 5}, ['G'] = {1, 2, 4, 5},
    ['h'] = {1, 2, 5}, ['H'] = {1, 2, 5},
    ['i'] = {2, 4}, ['I'] = {2, 4},
    ['j'] = {2, 4, 5}, ['J'] = {2, 4, 5},
    ['k'] = {1, 3}, ['K'] = {1, 3},
    ['l'] = {1, 2, 3}, ['L'] = {1, 2, 3},
    ['m'] = {1, 3, 4}, ['M'] = {1, 3, 4},
    ['n'] = {1, 3, 4, 5}, ['N'] = {1, 3, 4, 5},
    ['o'] = {1, 3, 5}, ['O'] = {1, 3, 5},
    ['p'] = {1, 2, 3, 4}, ['P'] = {1, 2, 3, 4},
    ['q'] = {1, 2, 3, 4, 5}, ['Q'] = {1, 2, 3, 4, 5},
    ['r'] = {1, 2, 3, 5}, ['R'] = {1, 2, 3, 5},
    ['s'] = {2, 3, 4}, ['S'] = {2, 3, 4},
    ['t'] = {2, 3, 4, 5}, ['T'] = {2, 3, 4, 5},
    ['u'] = {1, 3, 6}, ['U'] = {1, 3, 6},
    ['v'] = {1, 2, 3, 6}, ['V'] = {1, 2, 3, 6},
    ['w'] = {2, 4, 5, 6}, ['W'] = {2, 4, 5, 6},
    ['x'] = {1, 3, 4, 6}, ['X'] = {1, 3, 4, 6},
    ['y'] = {1, 3, 4, 5, 6}, ['Y'] = {1, 3, 4, 5, 6},
    ['z'] = {1, 3, 5, 6}, ['Z'] = {1, 3, 5, 6},
    
    -- Castellano: vocales con tilde y diéresis (minúsculas y mayúsculas UTF-8)
    ['á'] = {1, 2, 3, 5, 6}, ['Á'] = {1, 2, 3, 5, 6},
    ['é'] = {2, 3, 4, 6},    ['É'] = {2, 3, 4, 6},
    ['í'] = {3, 4},          ['Í'] = {3, 4},
    ['ó'] = {3, 4, 6},       ['Ó'] = {3, 4, 6},
    ['ú'] = {2, 3, 4, 5, 6}, ['Ú'] = {2, 3, 4, 5, 6},
    ['ü'] = {1, 2, 5, 6},    ['Ü'] = {1, 2, 5, 6},
    ['ñ'] = {1, 2, 4, 5, 6}, ['Ñ'] = {1, 2, 4, 5, 6},

    -- Puntuación y símbolos habituales
    ['.'] = {3},
    [','] = {2},
    [';'] = {2, 3},
    [':'] = {2, 5},
    ['-'] = {3, 6},
    ['!'] = {2, 3, 5},
    ['?'] = {2, 6},
    ['('] = {2, 3, 5, 6},
    [')'] = {2, 3, 5, 6},
    ['/'] = {3, 4}
}

-- Mapeo de dígitos con prefijo numérico (# = 3, 4, 5, 6)
local NUMBER_SIGN = {3, 4, 5, 6}
local DIGIT_MAP = {
    ['1'] = {1},
    ['2'] = {1, 2},
    ['3'] = {1, 4},
    ['4'] = {1, 4, 5},
    ['5'] = {1, 5},
    ['6'] = {1, 2, 4},
    ['7'] = {1, 2, 4, 5},
    ['8'] = {1, 2, 5},
    ['9'] = {2, 4},
    ['0'] = {2, 4, 5}
}

-- Convierte cualquier cadena UTF-8 en secuencia de celdas Braille
local function text_to_braille_cells(str)
    local cells = {}
    local in_number_mode = false
    
    local i = 1
    local len = #str
    while i <= len do
        local byte = string.byte(str, i)
        local c
        
        -- Detección de caracteres multibyte UTF-8 (2 bytes para tildes/ñ)
        if byte >= 192 and byte <= 223 and (i + 1) <= len then
            c = string.sub(str, i, i + 1)
            i = i + 1
        elseif byte >= 224 and byte <= 239 and (i + 2) <= len then
            c = string.sub(str, i, i + 2)
            i = i + 2
        else
            c = string.sub(str, i, i)
        end
        
        if c == " " then
            table.insert(cells, {}) -- Espacio entre palabras
            in_number_mode = false
        elseif DIGIT_MAP[c] then
            if not in_number_mode then
                table.insert(cells, NUMBER_SIGN)
                in_number_mode = true
            end
            table.insert(cells, DIGIT_MAP[c])
        elseif BRAILLE_MAP[c] then
            in_number_mode = false
            table.insert(cells, BRAILLE_MAP[c])
        else
            -- Si no está en el mapa, intentar con minúscula básica o espacio neutro
            local lower_c = string.lower(c)
            if BRAILLE_MAP[lower_c] then
                in_number_mode = false
                table.insert(cells, BRAILLE_MAP[lower_c])
            else
                table.insert(cells, {})
                in_number_mode = false
            end
        end
        
        i = i + 1
    end
    
    return cells
end

function execute(opts)
    local text = opts.text or "SALIDA"
    if #text == 0 then text = "3DEMS" end

    local base_thickness = opts.base_thickness or 2.4
    local dot_height = opts.dot_height or 0.6
    local dot_radius = 0.75 -- Diámetro 1.5 mm estándar
    local include_visual = opts.include_visual_text
    local mounting_holes = opts.mounting_holes

    -- Dimensiones oficiales Marburg Medium
    local dot_spacing_x = 2.5
    local dot_spacing_y = 2.5
    local cell_pitch_x = 6.0
    local braille_cell_height = 5.0 -- 2 pasos de 2.5 mm entre filas 1 y 3

    local cells = text_to_braille_cells(text)
    local num_cells = math.max(#cells, 1)

    local braille_width = (num_cells - 1) * cell_pitch_x + dot_spacing_x

    local margin_x = mounting_holes and 18.0 or 12.0
    local margin_top = 8.0
    local margin_bottom = 8.0
    local gap_to_visual_text = 6.0

    -- Preparar texto visual con la tipografía segura predeterminada
    local visual_mesh = nil
    local visual_width = 0
    local visual_height = 0
    if include_visual then
        -- Buscar preferentemente Inter o NotoSans que tienen cobertura completa de tildes
        local font = api.get_font("Inter") or api.get_default_font()
        visual_mesh = api.emboss_text {
            font = font,
            text = text,
            depth = 0.8
        }
        local vb = visual_mesh:bounds()
        visual_width = vb.max_x - vb.min_x
        visual_height = vb.max_y - vb.min_y
    end

    local content_width = math.max(braille_width, visual_width)
    local plate_width = content_width + margin_x * 2
    local total_content_height = braille_cell_height + (include_visual and (gap_to_visual_text + visual_height) or 0)
    local plate_height = total_content_height + margin_top + margin_bottom

    -- 1. Crear placa base y obtener sus dimensiones reales
    local base_mesh = api.make_cube(plate_width, plate_height, base_thickness)
    local bb = base_mesh:bounds()
    local cx = (bb.max_x + bb.min_x) / 2
    local cy = (bb.max_y + bb.min_y) / 2
    local top_z = bb.max_z

    local other_volumes = {}

    -- Esfera base para los puntos Braille (semiesfera saliente)
    local sphere_mesh = api.make_sphere(dot_radius)
    local dot_z = top_z - (dot_radius - dot_height)

    -- Mapeo de coordenadas relativas para los 6 puntos de la celda
    local DOT_OFFSETS = {
        [1] = {x = 0, y = dot_spacing_y},
        [2] = {x = 0, y = 0},
        [3] = {x = 0, y = -dot_spacing_y},
        [4] = {x = dot_spacing_x, y = dot_spacing_y},
        [5] = {x = dot_spacing_x, y = 0},
        [6] = {x = dot_spacing_x, y = -dot_spacing_y}
    }

    -- Centrado relativo al centro de la placa base (cx, cy)
    local braille_start_x = cx - (braille_width / 2)
    local braille_center_y = cy
    if include_visual then
        braille_center_y = cy + (plate_height / 2) - margin_top - (braille_cell_height / 2)
    end

    -- 2. Posicionar puntos Braille
    for cell_idx, cell_dots in ipairs(cells) do
        local cell_x = braille_start_x + (cell_idx - 1) * cell_pitch_x
        for _, dot_num in ipairs(cell_dots) do
            local offset = DOT_OFFSETS[dot_num]
            if offset then
                table.insert(other_volumes, {
                    mesh = sphere_mesh,
                    translate = {
                        x = cell_x + offset.x,
                        y = braille_center_y + offset.y,
                        z = dot_z
                    }
                })
            end
        end
    end

    -- 3. Posicionar texto visual centrado en la parte inferior de la placa
    if include_visual and visual_mesh then
        local vb = visual_mesh:bounds()
        local visual_cx = (vb.max_x + vb.min_x) / 2
        local visual_cy = (vb.max_y + vb.min_y) / 2
        local target_y = cy - (plate_height / 2) + margin_bottom + (visual_height / 2)

        table.insert(other_volumes, {
            mesh = visual_mesh,
            translate = {
                x = cx - visual_cx,
                y = target_y - visual_cy,
                z = top_z
            }
        })
    end

    -- 4. Añadir orificios de montaje M3 (3.2 mm) con sustracción booleana
    if mounting_holes then
        local hole_radius = 1.6
        local hole_height = base_thickness * 3
        local hole_mesh = api.make_cylinder(hole_radius, hole_height)
        local hole_dist_x = (plate_width / 2) - (margin_x / 2)

        -- Agujero izquierdo
        table.insert(other_volumes, {
            mesh = hole_mesh,
            type = VolumeType.Negative,
            translate = {
                x = cx - hole_dist_x,
                y = cy,
                z = top_z - (hole_height / 2)
            }
        })

        -- Agujero derecho
        table.insert(other_volumes, {
            mesh = hole_mesh,
            type = VolumeType.Negative,
            translate = {
                x = cx + hole_dist_x,
                y = cy,
                z = top_z - (hole_height / 2)
            }
        })
    end

    -- 5. Añadir el objeto a la bandeja activa
    api.project:add_object {
        mesh = base_mesh,
        other_volumes = other_volumes,
        translate = {
            x = 0,
            y = 0,
            z = -bb.min_z
        }
    }
end
