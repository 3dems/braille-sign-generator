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

-- Mapeo de celdas Braille estándar (6 puntos: col1 = 1,2,3; col2 = 4,5,6)
local BRAILLE_MAP = {
    ['a'] = {1},
    ['b'] = {1, 2},
    ['c'] = {1, 4},
    ['d'] = {1, 4, 5},
    ['e'] = {1, 5},
    ['f'] = {1, 2, 4},
    ['g'] = {1, 2, 4, 5},
    ['h'] = {1, 2, 5},
    ['i'] = {2, 4},
    ['j'] = {2, 4, 5},
    ['k'] = {1, 3},
    ['l'] = {1, 2, 3},
    ['m'] = {1, 3, 4},
    ['n'] = {1, 3, 4, 5},
    ['o'] = {1, 3, 5},
    ['p'] = {1, 2, 3, 4},
    ['q'] = {1, 2, 3, 4, 5},
    ['r'] = {1, 2, 3, 5},
    ['s'] = {2, 3, 4},
    ['t'] = {2, 3, 4, 5},
    ['u'] = {1, 3, 6},
    ['v'] = {1, 2, 3, 6},
    ['w'] = {2, 4, 5, 6},
    ['x'] = {1, 3, 4, 6},
    ['y'] = {1, 3, 4, 5, 6},
    ['z'] = {1, 3, 5, 6},
    -- Caracteres especiales y tildes en castellano
    ['á'] = {1, 2, 3, 5, 6},
    ['é'] = {2, 3, 4, 6},
    ['í'] = {3, 4},
    ['ó'] = {3, 4, 6},
    ['ú'] = {2, 3, 4, 5, 6},
    ['ü'] = {1, 2, 5, 6},
    ['ñ'] = {1, 2, 4, 5, 6},
    -- Puntuación
    ['.'] = {3},
    [','] = {2},
    ['-'] = {3, 6},
    ['!'] = {2, 3, 5},
    ['?'] = {2, 6}
}

-- Mapeo de dígitos (precedidos por signo numérico #)
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

-- Convierte texto en una lista de celdas Braille
local function text_to_braille_cells(str)
    local cells = {}
    local in_number_mode = false
    
    -- Normalizar a minúsculas en UTF-8 básico
    str = string.lower(str)
    
    local i = 1
    while i <= #str do
        local c = string.sub(str, i, i)
        local byte = string.byte(c)
        
        -- Detección de caracteres multibyte UTF-8 (tildes, ñ)
        if byte >= 192 and byte <= 223 and i < #str then
            c = string.sub(str, i, i + 1)
            i = i + 1
        end
        
        if c == " " then
            table.insert(cells, {}) -- Celda vacía (espacio)
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
            -- Carácter no reconocido, espacio de seguridad
            table.insert(cells, {})
            in_number_mode = false
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
    local dot_radius = 0.75 -- Diámetro estándar de 1.5 mm
    local include_visual = opts.include_visual_text
    local mounting_holes = opts.mounting_holes

    -- Dimensiones estándar Marburg Medium
    local dot_spacing_x = 2.5
    local dot_spacing_y = 2.5
    local cell_pitch_x = 6.0
    local braille_cell_height = 5.0 -- Desde fila 1 hasta fila 3 (2 * 2.5 mm)

    local cells = text_to_braille_cells(text)
    local num_cells = math.max(#cells, 1)

    -- Ancho del contenido Braille
    local braille_width = (num_cells - 1) * cell_pitch_x + dot_spacing_x

    -- Cálculos de márgenes
    local margin_x = mounting_holes and 16.0 or 10.0
    local margin_top = 8.0
    local margin_bottom = 8.0
    local gap_to_visual_text = 6.0

    -- Medir texto visual si está activado
    local visual_mesh = nil
    local visual_width = 0
    local visual_height = 0
    if include_visual then
        local font = api.get_default_font()
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

    -- 1. Crear placa base
    local base_mesh = api.make_cube(plate_width, plate_height, base_thickness)
    local other_volumes = {}

    -- Esfera base para los puntos Braille
    -- Se coloca de modo que sobresalga dot_height sobre la cara superior
    local sphere_mesh = api.make_sphere(dot_radius)
    local dot_z = base_thickness - (dot_radius - dot_height)

    -- Mapeo de coordenadas relativas para los 6 puntos de la celda
    -- Centrado en el origen de la celda
    local DOT_OFFSETS = {
        [1] = {x = 0, y = dot_spacing_y},
        [2] = {x = 0, y = 0},
        [3] = {x = 0, y = -dot_spacing_y},
        [4] = {x = dot_spacing_x, y = dot_spacing_y},
        [5] = {x = dot_spacing_x, y = 0},
        [6] = {x = dot_spacing_x, y = -dot_spacing_y}
    }

    -- Centrado del bloque Braille en la placa
    local braille_start_x = -braille_width / 2
    local braille_center_y = include_visual and (plate_height / 2 - margin_top - braille_cell_height / 2) or 0

    -- 2. Generar puntos Braille
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

    -- 3. Añadir texto visual si está habilitado
    if include_visual and visual_mesh then
        local vb = visual_mesh:bounds()
        local visual_center_x = (vb.max_x + vb.min_x) / 2
        local visual_center_y = (vb.max_y + vb.min_y) / 2
        local target_y = -plate_height / 2 + margin_bottom + visual_height / 2

        table.insert(other_volumes, {
            mesh = visual_mesh,
            translate = {
                x = -visual_center_x,
                y = target_y - visual_center_y,
                z = base_thickness
            }
        })
    end

    -- 4. Añadir orificios de montaje M3 (3.2 mm de diámetro) si está activo
    if mounting_holes then
        local hole_radius = 1.6
        local hole_height = base_thickness * 3
        local hole_mesh = api.make_cylinder(hole_radius, hole_height)
        local hole_x = plate_width / 2 - margin_x / 2

        -- Agujero izquierdo
        table.insert(other_volumes, {
            mesh = hole_mesh,
            type = VolumeType.Negative,
            translate = {
                x = -hole_x,
                y = 0,
                z = -base_thickness / 2
            }
        })

        -- Agujero derecho
        table.insert(other_volumes, {
            mesh = hole_mesh,
            type = VolumeType.Negative,
            translate = {
                x = hole_x,
                y = 0,
                z = -base_thickness / 2
            }
        })
    end

    -- 5. Añadir el objeto completo al proyecto de PrusaSlicer
    api.project:add_object {
        mesh = base_mesh,
        other_volumes = other_volumes,
        translate = {
            x = 0,
            y = 0,
            z = 0
        }
    }
end
