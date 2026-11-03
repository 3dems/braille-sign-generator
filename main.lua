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

-- Generador de geometría STL para la placa base sólida continua y los puntos Braille combinados
-- Garantiza que la placa sea un prisma sólido continuo y que PrusaSlicer lamine el 100% de los puntos
local function write_braille_plate_stl(filepath, width, height, thickness, dots, dot_r, dot_h, is_sphere)
    local f = io.open(filepath, "w")
    if not f then return false end

    f:write("solid braille_plate\n")

    local function write_triangle(v1x, v1y, v1z, v2x, v2y, v2z, v3x, v3y, v3z)
        local ax = v2x - v1x
        local ay = v2y - v1y
        local az = v2z - v1z
        local bx = v3x - v1x
        local by = v3y - v1y
        local bz = v3z - v1z
        local nx = ay * bz - az * by
        local ny = az * bx - ax * bz
        local nz = ax * by - ay * bx
        local len = math.sqrt(nx * nx + ny * ny + nz * nz)
        if len > 0 then
            nx = nx / len
            ny = ny / len
            nz = nz / len
        else
            nx, ny, nz = 0.0, 0.0, 1.0
        end
        f:write(string.format("  facet normal %.6e %.6e %.6e\n    outer loop\n      vertex %.6f %.6f %.6f\n      vertex %.6f %.6f %.6f\n      vertex %.6f %.6f %.6f\n    endloop\n  endfacet\n",
            nx, ny, nz, v1x, v1y, v1z, v2x, v2y, v2z, v3x, v3y, v3z))
    end

    local function write_quad(v1x, v1y, v1z, v2x, v2y, v2z, v3x, v3y, v3z, v4x, v4y, v4z)
        write_triangle(v1x, v1y, v1z, v2x, v2y, v2z, v3x, v3y, v3z)
        write_triangle(v1x, v1y, v1z, v3x, v3y, v3z, v4x, v4y, v4z)
    end

    local W, H, T = width, height, thickness

    -- 1. Prisma rectangular de la placa base: 100% cerrado, sólido y estanco (watertight manifold)
    -- Fondo (-Z)
    write_quad(0, 0, 0,  0, H, 0,  W, H, 0,  W, 0, 0)
    -- Tapa superior (+Z)
    write_quad(0, 0, T,  W, 0, T,  W, H, T,  0, H, T)
    -- Frente (-Y)
    write_quad(0, 0, 0,  W, 0, 0,  W, 0, T,  0, 0, T)
    -- Trasera (+Y)
    write_quad(W, H, 0,  0, H, 0,  0, H, T,  W, H, T)
    -- Izquierda (-X)
    write_quad(0, 0, 0,  0, 0, T,  0, H, T,  0, H, 0)
    -- Derecha (+X)
    write_quad(W, 0, 0,  W, H, 0,  W, H, T,  W, 0, T)

    -- 2. Puntos Braille integrados en la misma malla
    -- Se anclan 0.15 mm por debajo de la superficie superior para una adherencia estructural perfecta
    local embed = 0.15
    local z_base = T - embed
    local n_lat = 10
    local n_lon = 18

    for _, dot in ipairs(dots) do
        local cx, cy = dot.x, dot.y
        if is_sphere then
            -- Cúpula esférica redondeada (Sensación táctil clásica)
            local apex_z = T + dot_h
            local total_h = dot_h + embed
            local rings = {}
            for i = 1, n_lat do
                local theta = (math.pi / 2.0) * (i / n_lat)
                local z = z_base + total_h * math.cos(theta)
                local r = dot_r * math.sin(theta)
                local ring = {}
                for j = 0, n_lon - 1 do
                    local phi = (2.0 * math.pi) * (j / n_lon)
                    ring[j + 1] = {x = cx + r * math.cos(phi), y = cy + r * math.sin(phi), z = z}
                end
                rings[i] = ring
            end

            -- Casquete superior (del ápice al primer anillo)
            for j = 1, n_lon do
                local next_j = (j % n_lon) + 1
                write_triangle(cx, cy, apex_z,
                               rings[1][next_j].x, rings[1][next_j].y, rings[1][next_j].z,
                               rings[1][j].x, rings[1][j].y, rings[1][j].z)
            end

            -- Anillos del cuerpo esférico
            for i = 1, #rings - 1 do
                local r1 = rings[i]
                local r2 = rings[i + 1]
                for j = 1, n_lon do
                    local next_j = (j % n_lon) + 1
                    write_quad(r1[j].x, r1[j].y, r1[j].z,
                               r1[next_j].x, r1[next_j].y, r1[next_j].z,
                               r2[next_j].x, r2[next_j].y, r2[next_j].z,
                               r2[j].x, r2[j].y, r2[j].z)
                end
            end

            -- Fondo plano del punto en z_base
            local last_ring = rings[#rings]
            for j = 1, n_lon do
                local next_j = (j % n_lon) + 1
                write_triangle(cx, cy, z_base,
                               last_ring[j].x, last_ring[j].y, last_ring[j].z,
                               last_ring[next_j].x, last_ring[next_j].y, last_ring[next_j].z)
            end
        else
            -- Pivote cilíndrico
            local top_z = T + dot_h
            local top_ring = {}
            local bot_ring = {}
            for j = 0, n_lon - 1 do
                local phi = (2.0 * math.pi) * (j / n_lon)
                local rx = dot_r * math.cos(phi)
                local ry = dot_r * math.sin(phi)
                top_ring[j + 1] = {x = cx + rx, y = cy + ry, z = top_z}
                bot_ring[j + 1] = {x = cx + rx, y = cy + ry, z = z_base}
            end

            for j = 1, n_lon do
                local next_j = (j % n_lon) + 1
                write_triangle(cx, cy, top_z,  top_ring[next_j].x, top_ring[next_j].y, top_ring[next_j].z,  top_ring[j].x, top_ring[j].y, top_ring[j].z)
                write_triangle(cx, cy, z_base,  bot_ring[j].x, bot_ring[j].y, bot_ring[j].z,  bot_ring[next_j].x, bot_ring[next_j].y, bot_ring[next_j].z)
                write_quad(top_ring[j].x, top_ring[j].y, top_ring[j].z,
                           top_ring[next_j].x, top_ring[next_j].y, top_ring[next_j].z,
                           bot_ring[next_j].x, bot_ring[next_j].y, bot_ring[next_j].z,
                           bot_ring[j].x, bot_ring[j].y, bot_ring[j].z)
            end
        end
    end

    f:write("endsolid braille_plate\n")
    f:close()
    return true
end

function execute(opts)
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
    local include_visual = opts.include_visual_text
    local mounting_holes = opts.mounting_holes
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
        local font = api.get_font("Inter") or api.get_default_font()
        visual_mesh = api.emboss_text {
            font = font,
            text = text,
            depth = 0.8
        }
        vb = visual_mesh:bounds()
        visual_width = vb.max_x - vb.min_x
        visual_height = vb.max_y - vb.min_y
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

    -- 3. Generar la placa base con los puntos Braille integrados en un prisma 100% sólido y continuo
    -- Al estar en la misma malla manifold, PrusaSlicer 3.0 lamina el 100% de los puntos sin omitirlos
    local temp_dir = os.getenv("TEMP") or os.getenv("TMP") or "C:/Windows/Temp"
    local stl_path = temp_dir:gsub("\\", "/") .. "/ps_braille_base_" .. tostring(os.time()) .. ".stl"

    local ok_write = write_braille_plate_stl(stl_path, plate_width, plate_height, base_thickness, dots, dot_radius, dot_height, is_sphere)

    local base_mesh = nil
    if ok_write then
        local ok_load, loaded = pcall(function() return api.load_stl(stl_path) end)
        if ok_load and loaded then
            base_mesh = loaded
        end
        pcall(function() os.remove(stl_path) end)
    end

    local other_volumes = {}

    -- Fallback si api.load_stl no estuviese disponible
    if not base_mesh then
        base_mesh = api.make_cube(plate_width, plate_height, base_thickness)
        for _, dot in ipairs(dots) do
            local dot_mesh
            if is_sphere then
                dot_mesh = api.make_sphere(dot_radius)
                table.insert(other_volumes, {
                    mesh = dot_mesh,
                    translate = {x = dot.x, y = dot.y, z = p_top_z + dot_height - dot_radius}
                })
            else
                dot_mesh = api.make_cylinder(dot_radius, dot_height)
                table.insert(other_volumes, {
                    mesh = dot_mesh,
                    translate = {x = dot.x, y = dot.y, z = p_top_z}
                })
            end
        end
    end

    -- 4. Añadir orificios de montaje M3 (3.2 mm) si están habilitados como volúmenes negativos
    if mounting_holes then
        local hole_radius = 1.6
        local hole_height = base_thickness * 3

        -- Agujero izquierdo
        table.insert(other_volumes, {
            mesh = api.make_cylinder(hole_radius, hole_height),
            type = VolumeType.Negative,
            translate = {
                x = p_min_x + (margin_x / 2),
                y = p_center_y,
                z = p_top_z - (hole_height / 2)
            }
        })

        -- Agujero derecho
        table.insert(other_volumes, {
            mesh = api.make_cylinder(hole_radius, hole_height),
            type = VolumeType.Negative,
            translate = {
                x = p_max_x - (margin_x / 2),
                y = p_center_y,
                z = p_top_z - (hole_height / 2)
            }
        })
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
