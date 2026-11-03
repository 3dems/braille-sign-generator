--[[
    3DEMS Braille Tactile Sign Generator Pro
    Plugin para PrusaSlicer 3.0+
    Autor: 3DEMS (Author ID: 9d2f6477-ddc2-4189-b873-d0026dd7a4ef)
    Estándares principales: Europa/España (ONCE), América/EE.UU. (ADA), Internacional (BANA)
--]]

info = {
    id = "braille_sign_generator",
    type = "project.plugin",
    title = "Braille Tactile Sign Pro",
    menu = "3DEMS/Braille Tactile Sign",
    params = {
        {name = "text", label = "Texto a traducir", type = "string", default = "Baño hombres"},
        {
            name = "standard",
            label = "Estándar / Región",
            type = "combobox",
            allowed_values = {
                "Europa / España (ONCE - Marburg)",
                "América / EE.UU. (ADA Standard)",
                "Internacional / Compacto (BANA)",
                "Personalizado (Ajuste manual)"
            }
        },
        {
            name = "dot_shape",
            label = "Geometría de puntos Braille",
            type = "combobox",
            allowed_values = {
                "Cúpula esférica redondeada (Sensación táctil clásica)",
                "Pivote cilíndrico (Máxima definición vertical)"
            }
        },
        {name = "include_visual_text", label = "Incluir texto visual debajo", type = "bool", default = true},
        {name = "mounting_holes", label = "Orificios para tornillos M3 (3.2 mm)", type = "bool", default = false},
        {name = "base_thickness", label = "Grosor de la base [mm]", type = "float", default = 2.4},
        {name = "custom_dot_diameter", label = "[Manual] Diámetro de puntos [mm]", type = "float", default = 1.6},
        {name = "custom_dot_height", label = "[Manual] Altura de puntos [mm]", type = "float", default = 0.7}
    }
}

-- Los 3 grandes estándares mundiales de señalética Braille
local STANDARDS = {
    ["Europa / España (ONCE - Marburg)"] = {
        dot_diameter = 1.6, -- Óptimo para laminado con boquilla 0.4
        dot_height = 0.7,
        dot_spacing_x = 2.5,
        dot_spacing_y = 2.5,
        cell_pitch_x = 6.2,
        visual_gap = 8.0
    },
    ["América / EE.UU. (ADA Standard)"] = {
        dot_diameter = 1.6,
        dot_height = 0.7,
        dot_spacing_x = 2.4,
        dot_spacing_y = 2.4,
        cell_pitch_x = 6.3,
        visual_gap = 9.5 -- Separación legal obligatoria en EE.UU.: 3/8 in (9.5 mm)
    },
    ["Internacional / Compacto (BANA)"] = {
        dot_diameter = 1.6,
        dot_height = 0.7,
        dot_spacing_x = 2.3,
        dot_spacing_y = 2.3,
        cell_pitch_x = 6.0,
        visual_gap = 7.5
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
    opts = opts or {}
    local text = opts.text or "Baño hombres"
    if #text == 0 then text = "3DEMS" end

    -- Obtener la configuración según la normativa seleccionada
    local std_name = opts.standard or "Europa / España (ONCE - Marburg)"
    local std_config = STANDARDS[std_name]

    local dot_diameter = std_config and std_config.dot_diameter or (opts.custom_dot_diameter or 1.6)
    local dot_height = std_config and std_config.dot_height or (opts.custom_dot_height or 0.7)
    local dot_spacing_x = std_config and std_config.dot_spacing_x or 2.5
    local dot_spacing_y = std_config and std_config.dot_spacing_y or 2.5
    local cell_pitch_x = std_config and std_config.cell_pitch_x or 6.2
    local gap_to_visual_text = std_config and std_config.visual_gap or 8.0

    local dot_radius = dot_diameter / 2
    local base_thickness = opts.base_thickness or 2.4
    local include_visual = (opts.include_visual_text ~= false)
    local mounting_holes = (opts.mounting_holes == true)
    local dot_shape = opts.dot_shape or "Cúpula esférica redondeada (Sensación táctil clásica)"

    local braille_cell_height = dot_spacing_y * 2 -- De fila 1 a fila 3 (5.0 mm)

    local cells = text_to_braille_cells(text)
    local num_cells = math.max(#cells, 1)

    local braille_width = (num_cells - 1) * cell_pitch_x + dot_spacing_x

    local margin_x = mounting_holes and 20.0 or 14.0
    local margin_top = 8.0
    local margin_bottom = 8.0

    -- 1. Preparar texto visual si está habilitado
    local visual_mesh = nil
    local visual_width = 0
    local visual_height = 0
    local vb = nil
    if include_visual then
        local font = nil
        pcall(function() font = api.get_font("Inter") or api.get_default_font() end)
        if not font then
            font = api.get_default_font()
        end
        pcall(function()
            visual_mesh = api.emboss_text {
                font = font,
                text = text,
                depth = 0.8
            }
            if visual_mesh then
                vb = visual_mesh:bounds()
                visual_width = vb.max_x - vb.min_x
                visual_height = vb.max_y - vb.min_y
            end
        end)
    end

    -- Calcular tamaño total de la placa base
    local content_width = math.max(braille_width, visual_width)
    local plate_width = content_width + (margin_x * 2)
    local total_content_height = braille_cell_height + (include_visual and (gap_to_visual_text + visual_height) or 0)
    local plate_height = total_content_height + margin_top + margin_bottom

    -- Puntos de referencia geométricos
    local p_min_x = 0
    local p_max_x = plate_width
    local p_min_y = 0
    local p_max_y = plate_height
    local p_center_x = plate_width / 2
    local p_center_y = plate_height / 2
    local p_top_z = base_thickness

    -- 2. Calcular coordenadas absolutas de todos los puntos Braille
    local is_sphere = (string.find(dot_shape, "cilíndrico") == nil)

    local DOT_OFFSETS = {
        [1] = {x = 0, y = dot_spacing_y},
        [2] = {x = 0, y = 0},
        [3] = {x = 0, y = -dot_spacing_y},
        [4] = {x = dot_spacing_x, y = dot_spacing_y},
        [5] = {x = dot_spacing_x, y = 0},
        [6] = {x = dot_spacing_x, y = -dot_spacing_y}
    }

    local braille_start_x = p_center_x - (braille_width / 2)
    local braille_center_y = p_center_y
    if include_visual then
        braille_center_y = p_max_y - margin_top - (braille_cell_height / 2)
    end

    local dots = {}
    for cell_idx, cell_dots in ipairs(cells) do
        local cell_x = braille_start_x + (cell_idx - 1) * cell_pitch_x
        for _, dot_num in ipairs(cell_dots) do
            local offset = DOT_OFFSETS[dot_num]
            if offset then
                table.insert(dots, {
                    x = cell_x + offset.x,
                    y = braille_center_y + offset.y
                })
            end
        end
    end

    -- 3. Crear placa base sólida pura mediante la API nativa de PrusaSlicer
    local base_mesh = api.make_cube(plate_width, plate_height, base_thickness)
    local other_volumes = {}

    -- Añadir los puntos Braille con anclaje continuo para garantizar su laminado completo
    for _, dot in ipairs(dots) do
        if is_sphere then
            -- Base cilíndrica de apoyo (0.35 mm) para asegurar que el laminador lo detecta con boquilla 0.4
            local stem_height = dot_height * 0.5
            table.insert(other_volumes, {
                mesh = api.make_cylinder(dot_radius, stem_height),
                translate = {
                    x = dot.x,
                    y = dot.y,
                    z = p_top_z
                }
            })
            -- Cúpula esférica táctil encima
            table.insert(other_volumes, {
                mesh = api.make_sphere(dot_radius),
                translate = {
                    x = dot.x,
                    y = dot.y,
                    z = p_top_z + dot_height - dot_radius
                }
            })
        else
            -- Pivote cilíndrico clásico
            table.insert(other_volumes, {
                mesh = api.make_cylinder(dot_radius, dot_height),
                translate = {
                    x = dot.x,
                    y = dot.y,
                    z = p_top_z
                }
            })
        end
    end

    -- 4. Añadir orificios de montaje M3 (3.2 mm) si están habilitados
    if mounting_holes then
        local hole_radius = 1.6
        local hole_height = base_thickness * 3

        local neg_type = nil
        pcall(function()
            if VolumeType and VolumeType.Negative then
                neg_type = VolumeType.Negative
            elseif api and api.VolumeType and api.VolumeType.Negative then
                neg_type = api.VolumeType.Negative
            elseif api and api.project and api.project.VolumeType and api.project.VolumeType.Negative then
                neg_type = api.project.VolumeType.Negative
            end
        end)

        if neg_type then
            table.insert(other_volumes, {
                mesh = api.make_cylinder(hole_radius, hole_height),
                type = neg_type,
                translate = {
                    x = p_min_x + (margin_x / 2),
                    y = p_center_y,
                    z = p_top_z - (hole_height / 2)
                }
            })
            table.insert(other_volumes, {
                mesh = api.make_cylinder(hole_radius, hole_height),
                type = neg_type,
                translate = {
                    x = p_max_x - (margin_x / 2),
                    y = p_center_y,
                    z = p_top_z - (hole_height / 2)
                }
            })
        end
    end

    -- 5. Posicionar texto visual centrado justo debajo del bloque Braille
    if include_visual and visual_mesh and vb then
        local visual_local_cx = (vb.max_x + vb.min_x) / 2
        local visual_local_cy = (vb.max_y + vb.min_y) / 2
        local visual_target_y = p_min_y + margin_bottom + (visual_height / 2)

        table.insert(other_volumes, {
            mesh = visual_mesh,
            translate = {
                x = p_center_x - visual_local_cx,
                y = visual_target_y - visual_local_cy,
                z = p_top_z - vb.min_z - 0.05
            }
        })
    end

    -- 6. Añadir el objeto completo a la bandeja
    api.project:add_object {
        mesh = base_mesh,
        other_volumes = other_volumes
    }
end
