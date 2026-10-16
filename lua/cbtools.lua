--- Procedural rendering, UI, and data helpers for Newt.
-- Requires Lua 5.1/LuaJIT and the Newt host APIs.
-- Rendering and UI state belong to these tools rather than gameplay.
-- @module cbtools
-- @usage
-- local cb = require("cbtools")
-- cb.res.initialise(384, 216)
-- cb.imgui.button(1, 10, 10, 100, 24)
local cb = {}

--- Numeric interpolation, snapping, and geometry tests.
-- @table maths
cb.maths = {}

--- Clamp a number to an inclusive range.
-- @function maths.clamp
-- @param value number: Input value.
-- @param minimum_value number: Lower bound.
-- @param maximum_value number: Upper bound.
-- @return number: Clamped value.
function cb.maths.clamp(value, minimum_value, maximum_value)
   return math.max(minimum_value, math.min(value, maximum_value))
end

--- Interpolate between two numbers without clamping the amount.
-- @function maths.lerp
-- @param start_value number: Start of the range.
-- @param end_value number: End of the range.
-- @param amount number: Interpolation amount; values outside 0 to 1 extrapolate.
-- @return number: Interpolated value.
function cb.maths.lerp(start_value, end_value, amount)
   return start_value + (end_value - start_value) * amount
end

--- Find the interpolation amount of a value within a range.
-- @function maths.inverse_lerp
-- @param start_value number: Start of the range.
-- @param end_value number: End of the range; must differ from start_value.
-- @param value number: Input value.
-- @return number: Unclamped interpolation amount.
function cb.maths.inverse_lerp(start_value, end_value, value)
   return (value - start_value) / (end_value - start_value)
end

--- Map a value from one numeric range to another without clamping.
-- @function maths.remap
-- @param value number: Input value.
-- @param input_minimum number: Start of the input range.
-- @param input_maximum number: End of the input range; must differ from input_minimum.
-- @param output_minimum number: Start of the output range.
-- @param output_maximum number: End of the output range.
-- @return number: Value in the output range.
function cb.maths.remap(value, input_minimum, input_maximum, output_minimum, output_maximum)
   local amount = cb.maths.inverse_lerp(input_minimum, input_maximum, value)
   return cb.maths.lerp(output_minimum, output_maximum, amount)
end

--- Round to the nearest integer, rounding halves toward positive infinity.
-- @function maths.round
-- @param value number: Input value.
-- @return number: Rounded integer.
function cb.maths.round(value)
   return math.floor(value + 0.5)
end

--- Return the sign of a number.
-- @function maths.sign
-- @param value number: Input value.
-- @return number: -1, 0, or 1.
function cb.maths.sign(value)
   if value < 0 then
      return -1
   elseif value > 0 then
      return 1
   end

   return 0
end

--- Calculate the Euclidean distance between two points.
-- @function maths.distance
-- @param point_a_x number: Point a x coordinate.
-- @param point_a_y number: Point a y coordinate.
-- @param point_b_x number: Point b x coordinate.
-- @param point_b_y number: Point b y coordinate.
-- @return number: Distance between the points.
function cb.maths.distance(point_a_x, point_a_y, point_b_x, point_b_y)
   local distance_x = point_b_x - point_a_x
   local distance_y = point_b_y - point_a_y

   return math.sqrt(distance_x * distance_x + distance_y * distance_y)
end

--- Round a number to the nearest multiple of a step size.
-- @function maths.snap
-- @param value number: Input value.
-- @param step_size number: Positive step size.
-- @return number: Snapped value.
function cb.maths.snap(value, step_size)
   return cb.maths.round(value / step_size) * step_size
end

--- Move a value toward a target without overshooting.
-- @function maths.approach
-- @param current_value number: Current value.
-- @param target_value number: Target value.
-- @param step_size number: Nonnegative maximum movement.
-- @return number: Updated value.
function cb.maths.approach(current_value, target_value, step_size)
   if current_value < target_value then
      return math.min(current_value + step_size, target_value)
   elseif current_value > target_value then
      return math.max(current_value - step_size, target_value)
   end

   return target_value
end

--- Test whether a point lies inside a rectangle, including its edges.
-- @function maths.point_in_rect
-- @param point_x number: Point x coordinate.
-- @param point_y number: Point y coordinate.
-- @param rect_x number: Rect x coordinate.
-- @param rect_y number: Rect y coordinate.
-- @param rect_width number: Rect width in pixels.
-- @param rect_height number: Rect height in pixels.
-- @return boolean: Whether the point is inside the rectangle.
function cb.maths.point_in_rect(point_x, point_y, rect_x, rect_y, rect_width, rect_height)
   return point_x >= rect_x and point_x <= rect_x + rect_width
      and point_y >= rect_y and point_y <= rect_y + rect_height
end

--- Test whether two rectangles overlap with positive area.
-- @function maths.rects_overlap
-- @param rect_a_x number: Rect a x coordinate.
-- @param rect_a_y number: Rect a y coordinate.
-- @param rect_a_width number: Rect a width in pixels.
-- @param rect_a_height number: Rect a height in pixels.
-- @param rect_b_x number: Rect b x coordinate.
-- @param rect_b_y number: Rect b y coordinate.
-- @param rect_b_width number: Rect b width in pixels.
-- @param rect_b_height number: Rect b height in pixels.
-- @return boolean: Whether the rectangles overlap; touching edges do not count.
function cb.maths.rects_overlap(rect_a_x, rect_a_y, rect_a_width, rect_a_height, rect_b_x, rect_b_y, rect_b_width, rect_b_height)
   return rect_a_x < rect_b_x + rect_b_width
      and rect_a_x + rect_a_width > rect_b_x
      and rect_a_y < rect_b_y + rect_b_height
      and rect_a_y + rect_a_height > rect_b_y
end

--- Plain Lua data serialization and simple CSV loading.
-- @table data
cb.data = {}

local lua_keywords = {
   ["and"] = true,
   ["break"] = true,
   ["do"] = true,
   ["else"] = true,
   ["elseif"] = true,
   ["end"] = true,
   ["false"] = true,
   ["for"] = true,
   ["function"] = true,
   ["if"] = true,
   ["in"] = true,
   ["local"] = true,
   ["nil"] = true,
   ["not"] = true,
   ["or"] = true,
   ["repeat"] = true,
   ["return"] = true,
   ["then"] = true,
   ["true"] = true,
   ["until"] = true,
   ["while"] = true,
}

--- Encode a number as Lua source, including non-finite values.
-- @local
-- @param value number: Value to encode.
-- @return string: Lua numeric expression.
local function data_serialize_number(value)
   if value ~= value then
      return "(0 / 0)"
   elseif value == math.huge then
      return "(1 / 0)"
   elseif value == -math.huge then
      return "(-1 / 0)"
   end

   return tostring(value)
end

--- Recursively encode supported data as a Lua expression.
-- @local
-- @param value any: Value to encode or validate.
-- @param active_tables table: Tables currently being visited for cycle detection.
-- @param indentation string: Current indentation prefix.
-- @return string: Serialized Lua expression.
local function data_serialize_value(value, active_tables, indentation)
   local value_type = type(value)

   if value_type == "nil" then
      return "nil"
   elseif value_type == "string" then
      return string.format("%q", value)
   elseif value_type == "number" then
      return data_serialize_number(value)
   elseif value_type == "boolean" then
      return tostring(value)
   elseif value_type ~= "table" then
      error("Cannot serialize data of type '" .. value_type .. "'", 0)
   end

   if getmetatable(value) ~= nil then
      error("Cannot serialize a table with a metatable", 0)
   end

   if active_tables[value] then
      error("Cannot serialize cyclic table data", 0)
   end

   active_tables[value] = true

   local next_indentation = indentation .. "   "
   local entries = {}
   local array_length = 0

   while rawget(value, array_length + 1) ~= nil do
      array_length = array_length + 1
   end

   for array_index = 1, array_length do
      local entry = data_serialize_value(rawget(value, array_index), active_tables, next_indentation)
      entries[#entries + 1] = next_indentation .. entry
   end

   for key, entry_value in next, value do
      local is_array_key = type(key) == "number" and key >= 1 and key <= array_length and key == math.floor(key)

      if not is_array_key then
         local key_type = type(key)

         if key_type ~= "string" and key_type ~= "number" and key_type ~= "boolean" then
            error("Cannot serialize table key of type '" .. key_type .. "'", 0)
         end

         local serialized_key

         if key_type == "string" and key:match("^[%a_][%w_]*$") and not lua_keywords[key] then
            serialized_key = key
         else
            serialized_key = "[" .. data_serialize_value(key, active_tables, next_indentation) .. "]"
         end

         local serialized_value = data_serialize_value(entry_value, active_tables, next_indentation)
         entries[#entries + 1] = next_indentation .. serialized_key .. " = " .. serialized_value
      end
   end

   active_tables[value] = nil

   if #entries == 0 then
      return "{}"
   end

   return "{\n" .. table.concat(entries, ",\n") .. ",\n" .. indentation .. "}"
end

--- Reject unsupported values and cycles in loaded data.
-- @local
-- @param value any: Value to encode or validate.
-- @param active_tables table: Tables currently being visited for cycle detection.
local function data_validate(value, active_tables)
   local value_type = type(value)

   if value_type == "nil" or value_type == "string" or value_type == "number" or value_type == "boolean" then
      return
   elseif value_type ~= "table" then
      error("Loaded data contains unsupported type '" .. value_type .. "'", 0)
   end

   if getmetatable(value) ~= nil then
      error("Loaded data contains a table with a metatable", 0)
   end

   if active_tables[value] then
      error("Loaded data contains cyclic table data", 0)
   end

   active_tables[value] = true

   for key, entry_value in next, value do
      local key_type = type(key)

      if key_type ~= "string" and key_type ~= "number" and key_type ~= "boolean" then
         error("Loaded data contains a table key of type '" .. key_type .. "'", 0)
      end

      data_validate(entry_value, active_tables)
   end

   active_tables[value] = nil
end

--- Serialize plain Lua data and write it to a file.
-- Only scalar values and plain tables with scalar keys are supported.
-- @function data.save
-- @param path string: File path.
-- @param value nil|boolean|number|string|table: Plain acyclic data to serialize.
-- @return boolean|nil: Filesystem write result.
-- @return string|nil: Filesystem error message on failure.
-- @raise Unsupported values, table keys, metatables, or cyclic tables.
function cb.data.save(path, value)
   local serialized_data = "return " .. data_serialize_value(value, {}, "") .. "\n"
   return filesystem.write_file(path, serialized_data)
end

--- Load and validate serialized Lua data in an empty environment.
-- Uses Lua 5.1/LuaJIT loadstring and setfenv. A valid nil value also returns nil without an error.
-- @function data.load
-- @param path string: File path.
-- @return nil|boolean|number|string|table: Loaded value, or nil on failure.
-- @return string|nil: Read, syntax, execution, or validation error on failure.
function cb.data.load(path)
   local serialized_data, read_error = filesystem.read_file(path)

   if not serialized_data then
      return nil, read_error
   end

   local chunk, load_error = loadstring(serialized_data, "@" .. path)

   if not chunk then
      return nil, load_error
   end

   setfenv(chunk, {})

   local loaded, value = pcall(chunk)

   if not loaded then
      return nil, value
   end

   local valid, validation_error = pcall(data_validate, value, {})

   if not valid then
      return nil, validation_error
   end

   return value
end

--- Load a simple comma-separated file using its first nonempty row as field names.
-- Quoted fields and embedded commas are not supported.
-- @function data.load_csv
-- @param path string: File path.
-- @return table: Array of row tables; empty fields are omitted and numbers and booleans are converted.
-- @raise The file cannot be read or a row has the wrong number of fields.
function cb.data.load_csv(path)
   local text = assert(filesystem.read_file(path))
   local fields = nil
   local rows = {}

   for raw_line in (text .. "\n"):gmatch("([^\n]*)\n") do
      local line = raw_line:gsub("\r$", "")

      if line ~= "" then
         local values = {}

         for value in (line .. ","):gmatch("(.-),") do
            values[#values + 1] = value
         end

         if not fields then
            fields = values
         else
            assert(#values == #fields, path .. ": wrong number of CSV fields")

            local row = {}

            for index, field in ipairs(fields) do
               local value = values[index]

               if value == "" then
                  value = nil
               elseif value == "true" then
                  value = true
               elseif value == "false" then
                  value = false
               else
                  value = tonumber(value) or value
               end

               row[field] = value
            end

            rows[#rows + 1] = row
         end
      end
   end

   return rows
end

--- Raster-backed outlines, filled shapes, and dithering.
-- @table shape
-- @field dither_checkered table: Alternating two-by-two checker pattern.
-- @field dither_25 table: Two-by-two pattern with one entry set.
-- @field dither_75 table: Two-by-two pattern with three entries set.
cb.shape = {}

cb.shape.dither_checkered = { { 1, 0 }, { 0, 1 } }
cb.shape.dither_25 = { { 1, 0 }, { 0, 0 } }
cb.shape.dither_75 = { { 1, 1 }, { 1, 0 } }

local TRANSPARENT = rgba(0, 0, 0, 0)

local scratch_pixelmap = nil
local scratch_image = nil
local scratch_width = 0
local scratch_height = 0

--- Grow the reusable raster pixelmap and image to fit the requested size.
-- @local
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
local function ensure_scratch(width, height)
   if width <= scratch_width and height <= scratch_height then
      return
   end

   local new_width = math.max(width, scratch_width)
   local new_height = math.max(height, scratch_height)

   if scratch_image then
      free(scratch_image)
   end

   if scratch_pixelmap then
      free(scratch_pixelmap)
   end

   scratch_width = new_width
   scratch_height = new_height

   scratch_pixelmap = raster.new_pixelmap(scratch_width, scratch_height)
   scratch_image = graphics.new_image_from_pixelmap(scratch_pixelmap)
end

--- Clear the active scratch region to transparent pixels.
-- @local
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
local function clear_scratch(width, height)
   raster.blit_rect(scratch_pixelmap, 0, 0, width, height, TRANSPARENT, "replace")
end

--- Upload the active scratch region and draw it at the destination.
-- @local
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
local function draw_scratch(x, y, width, height)
   graphics.update_image_region_from_pixelmap(scratch_image, scratch_pixelmap, 0, 0, width, height, 0, 0)
   graphics.draw_image_region(scratch_image, 0, 0, width, height, x, y)
end

--- Calculate the axis-aligned bounds of a nonempty vertex array.
-- @local
-- @param points table: Array of {x, y} vertices.
-- @return number: Minimum x coordinate.
-- @return number: Minimum y coordinate.
-- @return number: Maximum x coordinate.
-- @return number: Maximum y coordinate.
local function get_bounds(points)
   local minimum_x = points[1][1]
   local minimum_y = points[1][2]
   local maximum_x = minimum_x
   local maximum_y = minimum_y

   for point_index = 2, #points do
      local point_x = points[point_index][1]
      local point_y = points[point_index][2]

      minimum_x = math.min(minimum_x, point_x)
      minimum_y = math.min(minimum_y, point_y)
      maximum_x = math.max(maximum_x, point_x)
      maximum_y = math.max(maximum_y, point_y)
   end

   return minimum_x, minimum_y, maximum_x, maximum_y
end

--- Draw a pixel line between two endpoints.
-- @function shape.line
-- @param start_x number: Start x coordinate.
-- @param start_y number: Start y coordinate.
-- @param end_x number: End x coordinate.
-- @param end_y number: End y coordinate.
-- @param color number: Packed RGBA colour.
function cb.shape.line(start_x, start_y, end_x, end_y, color)
   local minimum_x = math.min(start_x, end_x)
   local minimum_y = math.min(start_y, end_y)
   local maximum_x = math.max(start_x, end_x)
   local maximum_y = math.max(start_y, end_y)

   local width = maximum_x - minimum_x + 1
   local height = maximum_y - minimum_y + 1

   ensure_scratch(width, height)
   clear_scratch(width, height)

   raster.blit_line(scratch_pixelmap, start_x - minimum_x, start_y - minimum_y, end_x - minimum_x, end_y - minimum_y,
      color)

   draw_scratch(minimum_x, minimum_y, width, height)
end

--- Draw a one-pixel rectangle outline.
-- @function shape.rect
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
-- @param color number: Packed RGBA colour.
function cb.shape.rect(x, y, width, height, color)
   if width <= 0 or height <= 0 then
      return
   end

   graphics.draw_rect(x, y, width, 1, color)
   graphics.draw_rect(x, y + height - 1, width, 1, color)
   graphics.draw_rect(x, y, 1, height, color)
   graphics.draw_rect(x + width - 1, y, 1, height, color)
end

--- Draw a filled rectangle.
-- @function shape.rect_fill
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
-- @param color number: Packed RGBA colour.
function cb.shape.rect_fill(x, y, width, height, color)
   if width <= 0 or height <= 0 then
      return
   end

   graphics.draw_rect(x, y, width, height, color)
end

--- Draw a rectangle using a repeating two-colour pattern anchored in draw coordinates.
-- @function shape.rect_dither
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
-- @param color_1 number: Packed RGBA colour for pattern entries equal to 1.
-- @param color_2 number: Packed RGBA colour for all other pattern entries.
-- @param pattern table: Nonempty rectangular array of pattern rows.
function cb.shape.rect_dither(x, y, width, height, color_1, color_2, pattern)
   if width <= 0 or height <= 0 then
      return
   end

   ensure_scratch(width, height)
   clear_scratch(width, height)

   local pattern_height = #pattern
   local pattern_width = #pattern[1]

   for pixel_y = 0, height - 1 do
      local pattern_y = ((y + pixel_y) % pattern_height) + 1

      for pixel_x = 0, width - 1 do
         local pattern_x = ((x + pixel_x) % pattern_width) + 1
         local color = pattern[pattern_y][pattern_x] == 1 and color_1 or color_2

         raster.set_pixel(scratch_pixelmap, pixel_x, pixel_y, color)
      end
   end

   draw_scratch(x, y, width, height)
end

--- Draw a pixel circle outline.
-- @function shape.circle
-- @param center_x number: Center x coordinate.
-- @param center_y number: Center y coordinate.
-- @param radius number: Radius in pixels; negative radii draw nothing.
-- @param color number: Packed RGBA colour.
function cb.shape.circle(center_x, center_y, radius, color)
   if radius < 0 then
      return
   end

   local diameter = radius * 2 + 1

   ensure_scratch(diameter, diameter)
   clear_scratch(diameter, diameter)

   raster.blit_circle_pixel_outline(scratch_pixelmap, radius, radius, radius, color)

   draw_scratch(center_x - radius, center_y - radius, diameter, diameter)
end

--- Draw a filled pixel circle.
-- @function shape.circle_fill
-- @param center_x number: Center x coordinate.
-- @param center_y number: Center y coordinate.
-- @param radius number: Radius in pixels; negative radii draw nothing.
-- @param color number: Packed RGBA colour.
function cb.shape.circle_fill(center_x, center_y, radius, color)
   if radius < 0 then
      return
   end

   local diameter = radius * 2 + 1

   ensure_scratch(diameter, diameter)
   clear_scratch(diameter, diameter)

   raster.blit_circle(scratch_pixelmap, radius, radius, radius, color)

   draw_scratch(center_x - radius, center_y - radius, diameter, diameter)
end

--- Draw a pixel triangle outline.
-- @function shape.triangle
-- @param point_a_x number: Point a x coordinate.
-- @param point_a_y number: Point a y coordinate.
-- @param point_b_x number: Point b x coordinate.
-- @param point_b_y number: Point b y coordinate.
-- @param point_c_x number: Point c x coordinate.
-- @param point_c_y number: Point c y coordinate.
-- @param color number: Packed RGBA colour.
function cb.shape.triangle(point_a_x, point_a_y, point_b_x, point_b_y, point_c_x, point_c_y, color)
   local minimum_x = math.min(point_a_x, point_b_x, point_c_x)
   local minimum_y = math.min(point_a_y, point_b_y, point_c_y)
   local maximum_x = math.max(point_a_x, point_b_x, point_c_x)
   local maximum_y = math.max(point_a_y, point_b_y, point_c_y)

   local width = maximum_x - minimum_x + 1
   local height = maximum_y - minimum_y + 1

   ensure_scratch(width, height)
   clear_scratch(width, height)

   local point_a_local_x = point_a_x - minimum_x
   local point_a_local_y = point_a_y - minimum_y
   local point_b_local_x = point_b_x - minimum_x
   local point_b_local_y = point_b_y - minimum_y
   local point_c_local_x = point_c_x - minimum_x
   local point_c_local_y = point_c_y - minimum_y

   raster.blit_line(scratch_pixelmap, point_a_local_x, point_a_local_y, point_b_local_x, point_b_local_y, color)
   raster.blit_line(scratch_pixelmap, point_b_local_x, point_b_local_y, point_c_local_x, point_c_local_y, color)
   raster.blit_line(scratch_pixelmap, point_c_local_x, point_c_local_y, point_a_local_x, point_a_local_y, color)

   draw_scratch(minimum_x, minimum_y, width, height)
end

--- Draw a filled pixel triangle.
-- @function shape.triangle_fill
-- @param point_a_x number: Point a x coordinate.
-- @param point_a_y number: Point a y coordinate.
-- @param point_b_x number: Point b x coordinate.
-- @param point_b_y number: Point b y coordinate.
-- @param point_c_x number: Point c x coordinate.
-- @param point_c_y number: Point c y coordinate.
-- @param color number: Packed RGBA colour.
function cb.shape.triangle_fill(point_a_x, point_a_y, point_b_x, point_b_y, point_c_x, point_c_y, color)
   local minimum_x = math.min(point_a_x, point_b_x, point_c_x)
   local minimum_y = math.min(point_a_y, point_b_y, point_c_y)
   local maximum_x = math.max(point_a_x, point_b_x, point_c_x)
   local maximum_y = math.max(point_a_y, point_b_y, point_c_y)

   local width = maximum_x - minimum_x + 1
   local height = maximum_y - minimum_y + 1

   ensure_scratch(width, height)
   clear_scratch(width, height)

   raster.blit_triangle(scratch_pixelmap, point_a_x - minimum_x, point_a_y - minimum_y, point_b_x - minimum_x,
      point_b_y - minimum_y, point_c_x - minimum_x, point_c_y - minimum_y, color)

   draw_scratch(minimum_x, minimum_y, width, height)
end

--- Draw a filled triangle at four times the resolution and scale it down.
-- @function shape.smooth_triangle
-- @param point_a_x number: Point a x coordinate.
-- @param point_a_y number: Point a y coordinate.
-- @param point_b_x number: Point b x coordinate.
-- @param point_b_y number: Point b y coordinate.
-- @param point_c_x number: Point c x coordinate.
-- @param point_c_y number: Point c y coordinate.
-- @param color number: Packed RGBA colour.
function cb.shape.smooth_triangle(point_a_x, point_a_y, point_b_x, point_b_y, point_c_x, point_c_y, color)
   local scale = 4

   local minimum_x = math.floor(math.min(point_a_x, point_b_x, point_c_x))
   local minimum_y = math.floor(math.min(point_a_y, point_b_y, point_c_y))
   local maximum_x = math.ceil(math.max(point_a_x, point_b_x, point_c_x))
   local maximum_y = math.ceil(math.max(point_a_y, point_b_y, point_c_y))

   local width = maximum_x - minimum_x + 1
   local height = maximum_y - minimum_y + 1

   local render_width = width * scale
   local render_height = height * scale

   ensure_scratch(render_width, render_height)
   clear_scratch(render_width, render_height)

   local point_a_local_x = (point_a_x - minimum_x) * scale
   local point_a_local_y = (point_a_y - minimum_y) * scale
   local point_b_local_x = (point_b_x - minimum_x) * scale
   local point_b_local_y = (point_b_y - minimum_y) * scale
   local point_c_local_x = (point_c_x - minimum_x) * scale
   local point_c_local_y = (point_c_y - minimum_y) * scale

   raster.blit_triangle(scratch_pixelmap, point_a_local_x, point_a_local_y, point_b_local_x, point_b_local_y,
      point_c_local_x, point_c_local_y, color)
   graphics.update_image_region_from_pixelmap(scratch_image, scratch_pixelmap, 0, 0, render_width, render_height, 0,
      0)

   graphics.begin_transform()
   graphics.set_translation(minimum_x, minimum_y)
   graphics.set_scale(1 / scale, 1 / scale)
   graphics.draw_image_region(scratch_image, 0, 0, render_width, render_height, 0, 0)
   graphics.end_transform()
end

--- Draw a closed polygon outline.
-- Fewer than two vertices draw nothing.
-- @function shape.polygon
-- @param points table: Array of {x, y} vertices.
-- @param color number: Packed RGBA colour.
function cb.shape.polygon(points, color)
   if #points < 2 then
      return
   end

   local minimum_x, minimum_y, maximum_x, maximum_y = get_bounds(points)
   local width = maximum_x - minimum_x + 1
   local height = maximum_y - minimum_y + 1

   ensure_scratch(width, height)
   clear_scratch(width, height)

   for point_index = 1, #points do
      local next_point_index = point_index + 1

      if next_point_index > #points then
         next_point_index = 1
      end

      local current_point = points[point_index]
      local next_point = points[next_point_index]

      raster.blit_line(scratch_pixelmap, current_point[1] - minimum_x, current_point[2] - minimum_y,
         next_point[1] - minimum_x, next_point[2] - minimum_y, color)
   end

   draw_scratch(minimum_x, minimum_y, width, height)
end

--- Fill a polygon using pairs of scanline intersections.
-- Fewer than three vertices draw nothing.
-- @function shape.polygon_fill
-- @param points table: Array of {x, y} vertices.
-- @param color number: Packed RGBA colour.
function cb.shape.polygon_fill(points, color)
   if #points < 3 then
      return
   end

   local minimum_x, minimum_y, maximum_x, maximum_y = get_bounds(points)
   local width = maximum_x - minimum_x + 1
   local height = maximum_y - minimum_y + 1

   ensure_scratch(width, height)
   clear_scratch(width, height)

   local local_points = {}

   for point_index = 1, #points do
      local_points[point_index] = {
         points[point_index][1] - minimum_x,
         points[point_index][2] - minimum_y,
      }
   end

   for scanline_y = 0, height - 1 do
      local intersections = {}

      for point_index = 1, #local_points do
         local next_point_index = point_index + 1

         if next_point_index > #local_points then
            next_point_index = 1
         end

         local current_point = local_points[point_index]
         local next_point = local_points[next_point_index]

         local start_x = current_point[1]
         local start_y = current_point[2]
         local end_x = next_point[1]
         local end_y = next_point[2]

         if (start_y <= scanline_y and end_y > scanline_y) or (end_y <= scanline_y and start_y > scanline_y) then
            local intersection_x = start_x + (scanline_y - start_y) * (end_x - start_x) / (end_y - start_y)
            intersections[#intersections + 1] = intersection_x
         end
      end

      table.sort(intersections)

      for intersection_index = 1, #intersections - 1, 2 do
         local fill_start_x = math.ceil(intersections[intersection_index])
         local fill_end_x = math.floor(intersections[intersection_index + 1])

         if fill_end_x >= fill_start_x then
            raster.blit_line(scratch_pixelmap, fill_start_x, scanline_y, fill_end_x, scanline_y, color)
         end
      end
   end

   draw_scratch(minimum_x, minimum_y, width, height)
end

--- Immediate-mode UI widgets and shared interaction state.
-- @table imgui
-- @field hot_id number|string: Hovered widget ID, or 0.
-- @field active_id number|string: Active widget ID, or 0.
-- @field mouse_x number: Mouse x coordinate sampled by init.
-- @field mouse_y number: Mouse y coordinate sampled by init.
-- @field mouse_pressed boolean: Whether mouse1 was pressed this frame.
-- @field mouse_released boolean: Whether mouse1 was released this frame.
-- @field mouse_down boolean: Whether mouse1 is held.
-- @field scrollbar_drag_offset number: Mouse offset within the dragged scrollbar thumb.
-- @field text_edit_id number|string: Focused text field ID, or 0.
-- @field text_scroll number: Byte offset of the first visible text position.
-- @field caret number: Caret byte offset.
-- @field caret_timer number: Elapsed time toward the next caret blink.
-- @field caret_visible boolean: Whether the caret is currently visible.
-- @field config table: Mutable widget colours, padding, and size settings.
-- @field config.color_outline number: Packed RGBA panel outline colour.
-- @field config.color_panel number: Default packed RGBA panel fill colour.
-- @field config.color_cold number: Packed RGBA colour of an idle widget.
-- @field config.color_hot number: Packed RGBA colour of a hovered widget.
-- @field config.color_active number: Packed RGBA colour of an active widget.
-- @field config.color_text number: Default packed RGBA widget text colour.
-- @field config.color_text_cold number: Idle widget text colour.
-- @field config.color_text_hot number: Hovered widget text colour.
-- @field config.color_text_active number: Active widget text colour.
-- @field config.color_image_cold number: Packed RGBA overlay colour of an idle image button.
-- @field config.color_image_hot number: Packed RGBA overlay colour of a hovered image button.
-- @field config.checkbox_size number: Checkbox side length in pixels.
-- @field config.checkbox_padding number: Inset of the checkbox mark in pixels.
-- @field config.color_checkbox_checked number: Packed RGBA checkbox mark colour.
-- @field config.color_scrollbar_track number: Packed RGBA scrollbar track colour.
-- @field config.color_scrollbar_thumb_cold number: Packed RGBA colour of an idle scrollbar thumb.
-- @field config.color_scrollbar_thumb_hot number: Packed RGBA colour of a hovered scrollbar thumb.
-- @field config.color_scrollbar_thumb_active number: Packed RGBA colour of a dragged scrollbar thumb.
-- @field config.scrollbar_min_thumb_size number: Minimum scrollbar thumb height in pixels.
-- @field config.color_label_background number: Packed RGBA label fill colour.
-- @field config.color_label_text number: Packed RGBA label text colour.
-- @field config.label_padding number: Horizontal label inset in pixels.
-- @field config.text_padding number: Text box and text field inset in pixels.
cb.imgui = {

   hot_id = 0,
   active_id = 0,

   mouse_x = 0,
   mouse_y = 0,
   mouse_pressed = false,
   mouse_released = false,
   mouse_down = false,

   scrollbar_drag_offset = 0,

   text_edit_id = 0,
   text_scroll = 0,
   caret = 0,
   caret_timer = 0,
   caret_visible = true,

   config = {
      color_outline = rgba(100, 100, 100, 255),
      color_panel = rgba(30, 30, 30, 255),
      color_cold = rgba(50, 50, 50, 255),
      color_hot = rgba(75, 75, 75, 255),
      color_active = rgba(100, 100, 100, 255),
      color_text = rgba(255, 255, 255, 255),
      color_text_cold = rgba(255, 255, 255, 255),
      color_text_hot = rgba(255, 255, 255, 255),
      color_text_active = rgba(0, 0, 0, 255),

      color_image_cold = rgba(0, 0, 0, 51),
      color_image_hot = rgba(0, 0, 0, 26),

      checkbox_size = 16,
      checkbox_padding = 4,
      color_checkbox_checked = rgba(255, 255, 255, 255),

      color_scrollbar_track = rgba(30, 30, 30, 255),
      color_scrollbar_thumb_cold = rgba(50, 50, 50, 255),
      color_scrollbar_thumb_hot = rgba(75, 75, 75, 255),
      color_scrollbar_thumb_active = rgba(100, 100, 100, 255),
      scrollbar_min_thumb_size = 12,

      color_label_background = rgba(50, 50, 50, 255),
      color_label_text = rgba(255, 255, 255, 255),
      label_padding = 4,

      text_padding = 4,
   },
}

--- Override selected IMGUI settings without replacing unspecified defaults.
-- @function imgui.set_config
-- @param settings table: Known config keys and their replacement values.
function cb.imgui.set_config(settings)
   assert(type(settings) == "table", "IMGUI config settings must be a table")

   for key, value in pairs(settings) do
      assert(cb.imgui.config[key] ~= nil, "Unknown IMGUI config setting: " .. tostring(key))
      assert(type(value) == type(cb.imgui.config[key]), "Invalid IMGUI config value for: " .. key)
      cb.imgui.config[key] = value
   end
end

--- Return the configured text colour for a widget state.
-- @local
local function widget_text_color(state)
   local config = cb.imgui.config
   if state == "active" then
      return config.color_text_active or config.color_text
   elseif state == "hot" then
      return config.color_text_hot or config.color_text
   end
   return config.color_text_cold or config.color_text
end

--- Reject missing or zero widget IDs.
-- @local
-- @param id number|string: Explicit non-zero widget ID, unique within the frame.
local function require_id(id)
   if id == nil or id == 0 then
      error("IMGUI widget id must be an explicit non-zero value", 3)
   end
end

--- Test the UI mouse position against a rectangle with exclusive right and bottom edges.
-- @local
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
-- @return boolean: Whether the mouse is inside.
local function mouse_in_bounds(x, y, width, height)
   return cb.imgui.mouse_x >= x
      and cb.imgui.mouse_x < x + width
      and cb.imgui.mouse_y >= y
      and cb.imgui.mouse_y < y + height
end

--- Get the current visual state of a widget.
-- @local
-- @param id number|string: Explicit non-zero widget ID, unique within the frame.
-- @return string: "active", "hot", or "cold".
local function widget_state(id)
   if cb.imgui.active_id == id then
      return "active"
   elseif cb.imgui.hot_id == id then
      return "hot"
   end

   return "cold"
end

--- Begin a UI frame by sampling mouse input and updating the caret timer.
-- Call once per frame before drawing widgets. Mouse coordinates are sampled in window space.
-- @function imgui.init
-- @param dt number|nil: Elapsed seconds; defaults to 0.
function cb.imgui.init(dt)
   cb.imgui.hot_id = 0

   cb.imgui.mouse_x, cb.imgui.mouse_y = input.get_mouse_position()
   cb.imgui.mouse_pressed = input.pressed("mouse1")
   cb.imgui.mouse_released = input.released("mouse1")
   cb.imgui.mouse_down = input.down("mouse1")

   cb.imgui.caret_timer = cb.imgui.caret_timer + (dt or 0)

   if cb.imgui.caret_timer >= 0.5 then
      cb.imgui.caret_timer = cb.imgui.caret_timer - 0.5
      cb.imgui.caret_visible = not cb.imgui.caret_visible
   end
end

--- Draw a panel with a one-pixel outline.
-- @function imgui.panel
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
-- @param color number|nil: Packed RGBA fill colour; defaults to config.color_panel.
function cb.imgui.panel(x, y, width, height, color)
   local config = cb.imgui.config

   color = color or config.color_panel

   graphics.draw_rect(x, y, width, height, config.color_outline)

   if width > 2 and height > 2 then
      graphics.draw_rect(x + 1, y + 1, width - 2, height - 2, color)
   end
end

--- Draw horizontally and vertically centered wrapped text.
-- Resets text alignment to left after drawing.
-- @function imgui.centered_text
-- @param text string: Text to display.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
function cb.imgui.centered_text(text, x, y, width, height, color)
   if text == "" then
      return
   end

   local text_width = math.max(1, width)
   local _, text_height = graphics.measure_text_wrap(text, text_width)
   local text_y = math.floor(y + (height - text_height) / 2)

   graphics.set_text_alignment("center")
   graphics.draw_text_wrap(text, x, text_y, text_width, color or cb.imgui.config.color_text)
   graphics.set_text_alignment("left")
end

--- Draw a panel containing left-aligned text centered vertically.
-- @function imgui.label
-- @param text string: Text to display.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
function cb.imgui.label(text, x, y, width, height)
   local config = cb.imgui.config
   local _, text_height = graphics.measure_text(text)
   local text_y = math.floor(y + (height - text_height) / 2)

   cb.imgui.panel(x, y, width, height, config.color_label_background)
   graphics.draw_text(text, x + config.label_padding, text_y, config.color_label_text)
end

--- Draw a button and update its hover and active state.
-- @function imgui.button
-- @param id number|string: Explicit non-zero widget ID, unique within the frame.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
-- @return boolean: True when released over the button after activation.
-- @return boolean: True while the active button is held down.
-- @raise The widget ID is nil or 0.
function cb.imgui.button(id, x, y, width, height)
   require_id(id)

   local pressed = false

   if mouse_in_bounds(x, y, width, height) then
      cb.imgui.hot_id = id
   end

   if cb.imgui.hot_id == id and cb.imgui.mouse_pressed then
      if cb.imgui.text_edit_id ~= 0 then
         cb.imgui.text_edit_id = 0
         input.stop_text()
      end

      cb.imgui.active_id = id
   end

   if cb.imgui.active_id == id and cb.imgui.mouse_released then
      if cb.imgui.hot_id == id then
         pressed = true
      end

      cb.imgui.active_id = 0
   end

   local state = widget_state(id)
   local color = cb.imgui.config.color_cold

   if state == "active" then
      color = cb.imgui.config.color_active
   elseif state == "hot" then
      color = cb.imgui.config.color_hot
   end

   cb.imgui.panel(x, y, width, height, color)

   local held = cb.imgui.active_id == id and cb.imgui.mouse_down

   return pressed, held
end

--- Draw a checkbox and toggle its value when clicked.
-- @function imgui.checkbox
-- @param id number|string: Explicit non-zero widget ID, unique within the frame.
-- @param value boolean: Current checkbox value.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @return boolean: Updated checkbox value.
-- @raise The value is not boolean or the widget ID is nil or 0.
function cb.imgui.checkbox(id, value, x, y)
   if type(value) ~= "boolean" then
      error("IMGUI checkbox value must be a boolean", 2)
   end

   local config = cb.imgui.config
   local size = config.checkbox_size
   local pressed = cb.imgui.button(id, x, y, size, size)

   if pressed then
      value = not value
   end

   if value then
      local padding = config.checkbox_padding
      local inner_size = size - padding * 2

      if inner_size > 0 then
         graphics.draw_rect(x + padding, y + padding, inner_size, inner_size, config.color_checkbox_checked)
      end
   end

   return value
end

--- Draw a vertical scrollbar and update its scroll position while dragging.
-- @function imgui.scrollbar
-- @param id number|string: Explicit non-zero widget ID, unique within the frame.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
-- @param scroll number: Current scroll position.
-- @param visible_size number: Visible content size.
-- @param content_size number: Total content size.
-- @return number: Updated scroll position, clamped to the content range.
-- @raise The widget ID is nil or 0.
function cb.imgui.scrollbar(id, x, y, width, height, scroll, visible_size, content_size)
   require_id(id)

   local config = cb.imgui.config
   local max_scroll = math.max(content_size - visible_size, 0)

   if max_scroll == 0 then
      scroll = 0
   else
      scroll = math.max(0, math.min(scroll, max_scroll))
   end

   local thumb_size = height

   if content_size > 0 then
      thumb_size = math.min(height, math.max(config.scrollbar_min_thumb_size, height * visible_size / content_size))
   end

   local travel = height - thumb_size
   local thumb_y = y

   if max_scroll > 0 and travel > 0 then
      thumb_y = y + travel * scroll / max_scroll
   end

   local _, held = cb.imgui.button(id, x, thumb_y, width, thumb_size)

   if cb.imgui.mouse_pressed and cb.imgui.active_id == id then
      cb.imgui.scrollbar_drag_offset = cb.imgui.mouse_y - thumb_y
   end

   if held and max_scroll > 0 and travel > 0 then
      local thumb_offset = math.max(0, math.min(cb.imgui.mouse_y - y - cb.imgui.scrollbar_drag_offset, travel))
      scroll = max_scroll * thumb_offset / travel
      thumb_y = y + thumb_offset
   end

   local state = widget_state(id)
   local thumb_color = config.color_scrollbar_thumb_cold

   if state == "active" then
      thumb_color = config.color_scrollbar_thumb_active
   elseif state == "hot" then
      thumb_color = config.color_scrollbar_thumb_hot
   end

   cb.imgui.panel(x, y, width, height, config.color_scrollbar_track)
   cb.imgui.panel(x, thumb_y, width, thumb_size, thumb_color)

   return scroll
end

--- Draw a button containing centered wrapped text.
-- @function imgui.text_button
-- @param id number|string: Explicit non-zero widget ID, unique within the frame.
-- @param text string: Text to display.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
-- @return boolean: True when clicked.
-- @raise The widget ID is nil or 0.
function cb.imgui.text_button(id, text, x, y, width, height)
   local pressed = cb.imgui.button(id, x, y, width, height)

   cb.imgui.centered_text(text, x, y, width, height, widget_text_color(widget_state(id)))

   return pressed
end

--- Draw a button containing an image scaled to fit.
-- @function imgui.image_button
-- @param id number|string: Explicit non-zero widget ID, unique within the frame.
-- @param image userdata: Newt image handle.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
-- @return boolean: True when clicked.
-- @raise The widget ID is nil or 0.
function cb.imgui.image_button(id, image, x, y, width, height)
   local pressed = cb.imgui.button(id, x, y, width, height)

   local image_width, image_height = graphics.get_image_size(image)
   local scale = math.min(width / image_width, height / image_height)

   local draw_width = image_width * scale
   local draw_height = image_height * scale

   local draw_x = math.floor(x + (width - draw_width) / 2)
   local draw_y = math.floor(y + (height - draw_height) / 2)

   graphics.begin_transform()
   graphics.set_translation(draw_x, draw_y)
   graphics.set_scale(scale)
   graphics.draw_image(image, 0, 0)
   graphics.end_transform()

   local state = widget_state(id)

   if state == "hot" then
      graphics.draw_rect(x, y, width, height, cb.imgui.config.color_image_hot)
   elseif state == "cold" then
      graphics.draw_rect(x, y, width, height, cb.imgui.config.color_image_cold)
   end

   return pressed
end

--- Draw a read-only text panel with character wrapping.
-- @function imgui.text_box
-- @param text string: Text to display.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
function cb.imgui.text_box(text, x, y, width, height)
   local padding = cb.imgui.config.text_padding

   local draw_x = x + padding
   local draw_y = y + padding

   local right = x + width - padding
   local bottom = y + height - padding

   local line_height = graphics.get_font_line_skip()

   cb.imgui.panel(x, y, width, height)

   for character_index = 1, #text do
      local character = text:sub(character_index, character_index)

      local character_width = graphics.measure_text(character)

      if character == "\n" then
         draw_x = x + padding
         draw_y = draw_y + line_height
      else
         if draw_x + character_width > right then
            draw_x = x + padding
            draw_y = draw_y + line_height
         end

         if draw_y + line_height > bottom then
            break
         end

         graphics.draw_text(character, draw_x, draw_y, cb.imgui.config.color_text)

         draw_x = draw_x + character_width
      end
   end
end

--- Draw an editable single-line text field with a caret and horizontal scrolling.
-- Supports backspace, left/right arrows, Alt word movement, and Command line movement.
-- @function imgui.text_field
-- @param id number|string: Explicit non-zero widget ID, unique within the frame.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
-- @param text string: Current field value; editing uses byte offsets.
-- @return string: Updated text.
-- @raise The text is not a string or the widget ID is nil or 0.
function cb.imgui.text_field(id, x, y, width, height, text)
   require_id(id)

   if type(text) ~= "string" then
      error("IMGUI text field value must be a string", 2)
   end

   local inside = mouse_in_bounds(x, y, width, height)
   local text_changed = false
   local caret_moved = false

   -- Focus.
   if inside then
      cb.imgui.hot_id = id
   end

   if cb.imgui.hot_id == id and cb.imgui.mouse_pressed then
      if cb.imgui.text_edit_id ~= 0 and cb.imgui.text_edit_id ~= id then
         input.stop_text()
      end

      cb.imgui.active_id = id
      cb.imgui.text_edit_id = id
      cb.imgui.caret = #text
      cb.imgui.text_scroll = 0
      cb.imgui.caret_timer = 0
      cb.imgui.caret_visible = true

      input.start_text()
   elseif cb.imgui.active_id == id and cb.imgui.mouse_pressed and not inside then
      cb.imgui.active_id = 0
      cb.imgui.text_edit_id = 0

      input.stop_text()
   end

   -- Edit.
   if cb.imgui.active_id == id then
      cb.imgui.caret = math.min(cb.imgui.caret, #text)

      local entered = input.get_text()
      local backspace = input.pressed("backspace") or input.repeated("backspace")
      local move_left = input.pressed("left") or input.repeated("left")
      local move_right = input.pressed("right") or input.repeated("right")

      local option = input.down("lalt") or input.down("ralt")
      local command = input.down("lsuper") or input.down("rsuper")

      -- Insert text.
      if entered ~= "" then
         text = text:sub(1, cb.imgui.caret) .. entered .. text:sub(cb.imgui.caret + 1)
         cb.imgui.caret = cb.imgui.caret + #entered

         text_changed = true
         caret_moved = true
      end

      -- Backspace.
      if backspace and cb.imgui.caret > 0 then
         if command then
            text = text:sub(cb.imgui.caret + 1)
            cb.imgui.caret = 0
         elseif option then
            local delete_from = cb.imgui.caret

            while delete_from > 0 and text:sub(delete_from, delete_from):match("%s") do
               delete_from = delete_from - 1
            end

            while delete_from > 0 and text:sub(delete_from, delete_from):match("[%w_]") do
               delete_from = delete_from - 1
            end

            text = text:sub(1, delete_from) .. text:sub(cb.imgui.caret + 1)
            cb.imgui.caret = delete_from
         else
            text = text:sub(1, cb.imgui.caret - 1) .. text:sub(cb.imgui.caret + 1)
            cb.imgui.caret = cb.imgui.caret - 1
         end

         text_changed = true
         caret_moved = true
      end

      -- Move left.
      if move_left and cb.imgui.caret > 0 then
         if command then
            cb.imgui.caret = 0
         elseif option then
            local position = cb.imgui.caret

            while position > 0 and text:sub(position, position):match("%s") do
               position = position - 1
            end

            while position > 0 and text:sub(position, position):match("[%w_]") do
               position = position - 1
            end

            cb.imgui.caret = position
         else
            cb.imgui.caret = cb.imgui.caret - 1
         end

         caret_moved = true
      end

      -- Move right.
      if move_right and cb.imgui.caret < #text then
         if command then
            cb.imgui.caret = #text
         elseif option then
            local position = cb.imgui.caret + 1

            while position <= #text and text:sub(position, position):match("[%w_]") do
               position = position + 1
            end

            while position <= #text and text:sub(position, position):match("%s") do
               position = position + 1
            end

            cb.imgui.caret = position - 1
         else
            cb.imgui.caret = cb.imgui.caret + 1
         end

         caret_moved = true
      end

      -- Finish editing.
      if input.pressed("return") then
         cb.imgui.active_id = 0
         cb.imgui.text_edit_id = 0
         input.stop_text()
      end

      if text_changed or caret_moved then
         cb.imgui.caret_timer = 0
         cb.imgui.caret_visible = true
      end
   end

   -- Field.
   local state = widget_state(id)
   local color = cb.imgui.config.color_cold

   if state == "active" then
      color = cb.imgui.config.color_active
   elseif state == "hot" then
      color = cb.imgui.config.color_hot
   end

   cb.imgui.panel(x, y, width, height, color)

   -- Scroll.
   local padding = cb.imgui.config.text_padding
   local inner_width = width - padding * 2
   local _, text_height = graphics.measure_text(text ~= "" and text or "A")
   local draw_y = math.floor(y + (height - text_height) / 2)
   local text_scroll = 0

   if cb.imgui.text_edit_id == id then
      if cb.imgui.caret < cb.imgui.text_scroll then
         cb.imgui.text_scroll = cb.imgui.caret
      end

      while cb.imgui.text_scroll < cb.imgui.caret do
         local visible_to_caret = text:sub(cb.imgui.text_scroll + 1, cb.imgui.caret)
         local visible_width = graphics.measure_text(visible_to_caret)

         if visible_width + 1 <= inner_width then
            break
         end

         cb.imgui.text_scroll = cb.imgui.text_scroll + 1
      end

      while cb.imgui.text_scroll > 0 do
         local previous_scroll = cb.imgui.text_scroll - 1
         local visible_to_caret = text:sub(previous_scroll + 1, cb.imgui.caret)
         local visible_width = graphics.measure_text(visible_to_caret)

         if visible_width + 1 > inner_width then
            break
         end

         cb.imgui.text_scroll = previous_scroll
      end

      text_scroll = cb.imgui.text_scroll
   end

   -- Text.

   local draw_x = x + padding
   local right = x + width - padding

   for character_index = text_scroll + 1, #text do
      local character = text:sub(character_index, character_index)
      local character_width = graphics.measure_text(character)

      if cb.imgui.active_id == id and cb.imgui.caret == character_index - 1 and cb.imgui.caret_visible then
         graphics.draw_rect(draw_x, draw_y, 1, text_height, widget_text_color(state))
      end

      if draw_x + character_width > right then
         break
      end

      graphics.draw_text(character, draw_x, draw_y, widget_text_color(state))
      draw_x = draw_x + character_width
   end

   if cb.imgui.active_id == id and cb.imgui.caret == #text and cb.imgui.caret_visible and draw_x < right then
      graphics.draw_rect(draw_x, draw_y, 1, text_height, widget_text_color(state))
   end

   return text
end

--- Procedural camera transforms and coordinate conversion.
-- @table camera
cb.camera = {}

--- Clamp the camera position if bounds have been configured.
-- @local
-- @param camera_state table: Camera state returned by camera.new_camera.
local function clamp_camera_to_bounds(camera_state)
   if camera_state.min_x == nil then
      return
   end

   camera_state.x = math.max(camera_state.min_x, math.min(camera_state.x, camera_state.max_x))
   camera_state.y = math.max(camera_state.min_y, math.min(camera_state.y, camera_state.max_y))
end

--- Create a plain camera state table.
-- @function camera.new_camera
-- @param x number|nil: Initial world x position; defaults to 0.
-- @param y number|nil: Initial world y position; defaults to 0.
-- @param zoom number|nil: Initial zoom; defaults to 1.
-- @return table: Camera position, zoom, and optional position bounds.
function cb.camera.new_camera(x, y, zoom)
   return {
      x = x or 0,
      y = y or 0,
      zoom = zoom or 1,

      min_x = nil,
      min_y = nil,
      max_x = nil,
      max_y = nil,
   }
end

--- Begin a graphics transform for the camera with pixel-snapped translation.
-- Pair with camera.stop_camera.
-- @function camera.start_camera
-- @param camera_state table: Camera state returned by camera.new_camera.
function cb.camera.start_camera(camera_state)
   local x = math.floor(camera_state.x * camera_state.zoom + 0.5)
   local y = math.floor(camera_state.y * camera_state.zoom + 0.5)

   graphics.begin_transform()
   graphics.set_translation(-x, -y)
   graphics.set_scale(camera_state.zoom, camera_state.zoom)
end

--- End the current camera graphics transform.
-- @function camera.stop_camera
function cb.camera.stop_camera()
   graphics.end_transform()
end

--- Move the camera and clamp its position to any configured bounds.
-- @function camera.move_camera
-- @param camera_state table: Camera state returned by camera.new_camera.
-- @param dx number: Horizontal movement in world units.
-- @param dy number: Vertical movement in world units.
function cb.camera.move_camera(camera_state, dx, dy)
   camera_state.x = camera_state.x + dx
   camera_state.y = camera_state.y + dy

   clamp_camera_to_bounds(camera_state)
end

--- Set the camera position and clamp it to any configured bounds.
-- @function camera.set_camera_position
-- @param camera_state table: Camera state returned by camera.new_camera.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
function cb.camera.set_camera_position(camera_state, x, y)
   camera_state.x = x
   camera_state.y = y

   clamp_camera_to_bounds(camera_state)
end

--- Add an amount to the camera zoom without clamping.
-- @function camera.zoom_camera
-- @param camera_state table: Camera state returned by camera.new_camera.
-- @param amount number: Change to the current zoom.
function cb.camera.zoom_camera(camera_state, amount)
   camera_state.zoom = camera_state.zoom + amount
end

--- Set the camera zoom without clamping.
-- @function camera.set_camera_zoom
-- @param camera_state table: Camera state returned by camera.new_camera.
-- @param zoom number: Camera scale; use a positive non-zero value.
function cb.camera.set_camera_zoom(camera_state, zoom)
   camera_state.zoom = zoom
end

--- Convert world coordinates to screen coordinates using the camera state.
-- Does not include other graphics transforms or canvas scaling.
-- @function camera.world_to_screen
-- @param camera_state table: Camera state returned by camera.new_camera.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @return number: Screen x coordinate before pixel snapping.
-- @return number: Screen y coordinate before pixel snapping.
function cb.camera.world_to_screen(camera_state, x, y)
   local screen_x = (x - camera_state.x) * camera_state.zoom
   local screen_y = (y - camera_state.y) * camera_state.zoom

   return screen_x, screen_y
end

--- Convert screen coordinates to world coordinates using the camera state.
-- Does not include other graphics transforms or canvas scaling; zoom must be non-zero.
-- @function camera.screen_to_world
-- @param camera_state table: Camera state returned by camera.new_camera.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @return number: World x coordinate.
-- @return number: World y coordinate.
function cb.camera.screen_to_world(camera_state, x, y)
   local world_x = x / camera_state.zoom + camera_state.x
   local world_y = y / camera_state.zoom + camera_state.y

   return world_x, world_y
end

--- Set inclusive camera position bounds and clamp the current position.
-- @function camera.set_camera_bounds
-- @param camera_state table: Camera state returned by camera.new_camera.
-- @param min_x number: Minimum camera x position.
-- @param min_y number: Minimum camera y position.
-- @param max_x number: Maximum camera x position.
-- @param max_y number: Maximum camera y position.
function cb.camera.set_camera_bounds(camera_state, min_x, min_y, max_x, max_y)
   camera_state.min_x = min_x
   camera_state.min_y = min_y
   camera_state.max_x = max_x
   camera_state.max_y = max_y

   clamp_camera_to_bounds(camera_state)
end

--- Remove camera position bounds.
-- @function camera.clear_camera_bounds
-- @param camera_state table: Camera state returned by camera.new_camera.
function cb.camera.clear_camera_bounds(camera_state)
   camera_state.min_x = nil
   camera_state.min_y = nil
   camera_state.max_x = nil
   camera_state.max_y = nil
end

--- Logical canvas scaling and mouse coordinate conversion.
-- @table res
-- @field width number: Logical canvas width; initially 1280.
-- @field height number: Logical canvas height; initially 720.
-- @field scale number: Current window-to-canvas scale.
-- @field offset_x number: Horizontal canvas offset in window pixels.
-- @field offset_y number: Vertical canvas offset in window pixels.
-- @field mouse_x number: Mouse x in logical canvas coordinates.
-- @field mouse_y number: Mouse y in logical canvas coordinates.
cb.res = {
   width = 1280,
   height = 720,

   scale = 1,
   offset_x = 0,
   offset_y = 0,

   mouse_x = 0,
   mouse_y = 0,
}

--- Set the logical canvas dimensions and update its scale and mouse coordinates.
-- @function res.initialise
-- @param width number: Width in pixels.
-- @param height number: Height in pixels.
function cb.res.initialise(width, height)
   cb.res.width = width
   cb.res.height = height
   cb.res.update()
end

--- Recalculate the centered canvas scale, offsets, and logical mouse coordinates.
-- @function res.update
function cb.res.update()
   local window_width, window_height = window.get_size()

   cb.res.scale = math.min(window_width / cb.res.width, window_height / cb.res.height)

   local render_width = cb.res.width * cb.res.scale
   local render_height = cb.res.height * cb.res.scale

   cb.res.offset_x = (window_width - render_width) / 2
   cb.res.offset_y = (window_height - render_height) / 2

   local mouse_x, mouse_y = input.get_mouse_position()

   cb.res.mouse_x = (mouse_x - cb.res.offset_x) / cb.res.scale
   cb.res.mouse_y = (mouse_y - cb.res.offset_y) / cb.res.scale
end

--- Begin the graphics transform for the scaled logical canvas.
-- Pair with res.end_canvas.
-- @function res.begin_canvas
function cb.res.begin_canvas()
   graphics.begin_transform()
   graphics.set_translation(cb.res.offset_x, cb.res.offset_y)
   graphics.set_scale(cb.res.scale, cb.res.scale)
end

--- End the logical canvas graphics transform.
-- @function res.end_canvas
function cb.res.end_canvas()
   graphics.end_transform()
end

--- Sprite atlases, animation, and palette replacement.
-- @table spr
-- @field atlas table|nil: Active sprite atlas, or nil when none is set.
cb.spr = {
   atlas = nil,
}

--- Load a sprite atlas and retain its CPU pixelmap and GPU image.
-- @function spr.load_sprite_atlas
-- @param path string: File path.
-- @param sprite_width number: Sprite width in pixels.
-- @param sprite_height number: Sprite height in pixels.
-- @return table: Atlas dimensions, tile dimensions, row and column counts, pixelmap, and image.
-- @raise The pixelmap cannot be loaded.
function cb.spr.load_sprite_atlas(path, sprite_width, sprite_height)
   local pixelmap, image_width, image_height = raster.load_pixelmap(path)

   if not pixelmap then
      error("Failed to load sprite atlas '" .. path .. "'")
   end

   local image = graphics.new_image_from_pixelmap(pixelmap)

   return {
      pixelmap = pixelmap,
      image = image,
      image_width = image_width,
      image_height = image_height,
      sprite_width = sprite_width,
      sprite_height = sprite_height,
      columns = math.floor(image_width / sprite_width),
      rows = math.floor(image_height / sprite_height),
   }
end

--- Set or clear the active sprite atlas.
-- @function spr.set_sprite_atlas
-- @param atlas table|nil: Atlas returned by spr.load_sprite_atlas, or nil to clear it.
function cb.spr.set_sprite_atlas(atlas)
   cb.spr.atlas = atlas
end

--- Draw a sprite from the active atlas.
-- @function spr.draw_sprite
-- @param index number: Zero-based sprite index.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param flip_x boolean|nil: Flip horizontally; defaults to false.
-- @param flip_y boolean|nil: Flip vertically; defaults to false.
-- @param colour number|nil: Packed RGBA modulation colour; defaults to opaque white.
-- @raise No sprite atlas is set.
function cb.spr.draw_sprite(index, x, y, flip_x, flip_y, colour)
   local atlas = cb.spr.atlas

   if not atlas then
      error("No sprite atlas set")
   end

   local atlas_x = index % atlas.columns
   local atlas_y = math.floor(index / atlas.columns)
   local source_x = atlas_x * atlas.sprite_width
   local source_y = atlas_y * atlas.sprite_height

   colour = colour or 0xFFFFFFFF

   if flip_x or flip_y then
      local centre_x = x + atlas.sprite_width / 2
      local centre_y = y + atlas.sprite_height / 2

      graphics.begin_transform()
      graphics.set_translation(centre_x, centre_y)
      graphics.set_scale(flip_x and -1 or 1, flip_y and -1 or 1)
      graphics.set_origin(centre_x, centre_y)
   end

   graphics.draw_image_region(atlas.image, source_x, source_y, atlas.sprite_width, atlas.sprite_height, x, y, colour)

   if flip_x or flip_y then
      graphics.end_transform()
   end
end

--- Draw an animation frame from a contiguous sprite range using os.clock().
-- @function spr.animate_sprites
-- @param first_index number: First zero-based sprite index.
-- @param last_index number: Last zero-based sprite index, at least first_index.
-- @param fps number: Animation frames per second.
-- @param x number: X coordinate in pixels.
-- @param y number: Y coordinate in pixels.
-- @param flip_x boolean|nil: Flip horizontally; defaults to false.
-- @param flip_y boolean|nil: Flip vertically; defaults to false.
-- @param colour number|nil: Packed RGBA modulation colour; defaults to opaque white.
-- @raise No sprite atlas is set.
function cb.spr.animate_sprites(first_index, last_index, fps, x, y, flip_x, flip_y, colour)
   local frame_count = last_index - first_index + 1
   local frame = math.floor(os.clock() * fps) % frame_count
   local index = first_index + frame

   cb.spr.draw_sprite(index, x, y, flip_x, flip_y, colour)
end

--- Replace every exact occurrence of a colour in the active sprite atlas.
-- @function spr.swap_colour
-- @param from_colour number: Exact packed RGBA colour to replace.
-- @param to_colour number: Replacement packed RGBA colour.
-- @raise No sprite atlas is set.
function cb.spr.swap_colour(from_colour, to_colour)
   local atlas = cb.spr.atlas

   if not atlas then
      error("No sprite atlas set")
   end

   local width, height = raster.get_pixelmap_size(atlas.pixelmap)

   for y = 0, height - 1 do
      for x = 0, width - 1 do
         if raster.get_pixel(atlas.pixelmap, x, y) == from_colour then
            raster.set_pixel(atlas.pixelmap, x, y, to_colour)
         end
      end
   end

   graphics.update_image_from_pixelmap(atlas.image, atlas.pixelmap)
end

--- Tween progress and easing functions.
-- @table tween
cb.tween = {}

--- Create a plain tween state table.
-- @function tween.new_tween
-- @param duration number: Duration in seconds; must be greater than zero.
-- @return table: Tween duration, elapsed time, and completion flag.
-- @raise The duration is not greater than zero.
function cb.tween.new_tween(duration)
   assert(duration > 0, "Tween duration must be greater than zero")

   return {
      duration = duration,
      elapsed = 0,
      finished = false,
   }
end

--- Advance a tween and mark it finished when its duration is reached.
-- @function tween.update_tween
-- @param tween_state table: State returned by tween.new_tween.
-- @param delta_time number: Elapsed seconds to add.
function cb.tween.update_tween(tween_state, delta_time)
   if tween_state.finished then
      return
   end

   tween_state.elapsed = tween_state.elapsed + delta_time

   if tween_state.elapsed >= tween_state.duration then
      tween_state.elapsed = tween_state.duration
      tween_state.finished = true
   end
end

--- Reset a tween to zero elapsed time and clear its completion flag.
-- @function tween.reset_tween
-- @param tween_state table: State returned by tween.new_tween.
function cb.tween.reset_tween(tween_state)
   tween_state.elapsed = 0
   tween_state.finished = false
end

--- Get the normalized progress of a tween.
-- @function tween.get_tween_time
-- @param tween_state table: State returned by tween.new_tween.
-- @return number: Progress clamped to the range 0 to 1.
function cb.tween.get_tween_time(tween_state)
   return cb.maths.clamp(tween_state.elapsed / tween_state.duration, 0, 1)
end

--- Return linear easing for a normalized time.
-- @function tween.linear
-- @param time number: Normalized time, normally between 0 and 1.
-- @return number: Unmodified time.
function cb.tween.linear(time)
   return time
end

--- Calculate sine easing that starts slowly.
-- @function tween.sine_in
-- @param time number: Normalized time, normally between 0 and 1.
-- @return number: Eased amount.
function cb.tween.sine_in(time)
   return 1 - math.cos((time * math.pi) / 2)
end

--- Calculate sine easing that ends slowly.
-- @function tween.sine_out
-- @param time number: Normalized time, normally between 0 and 1.
-- @return number: Eased amount.
function cb.tween.sine_out(time)
   return math.sin((time * math.pi) / 2)
end

--- Calculate sine easing that starts and ends slowly.
-- @function tween.sine_in_out
-- @param time number: Normalized time, normally between 0 and 1.
-- @return number: Eased amount.
function cb.tween.sine_in_out(time)
   return -(math.cos(math.pi * time) - 1) / 2
end

--- Calculate a parabolic hop that peaks halfway through.
-- @function tween.hop
-- @param maximum_height number: Height at time 0.5.
-- @param time number: Normalized time, normally between 0 and 1.
-- @return number: Hop height.
function cb.tween.hop(maximum_height, time)
   return 4 * maximum_height * time * (1 - time)
end

--- Calculate a sine-eased bump that peaks halfway through.
-- @function tween.bump
-- @param maximum_distance number: Distance at time 0.5.
-- @param time number: Normalized time, normally between 0 and 1.
-- @return number: Bump distance.
function cb.tween.bump(maximum_distance, time)
   if time <= 0.5 then
      return maximum_distance * cb.tween.sine_out(time * 2)
   end

   return maximum_distance * cb.tween.sine_in((1 - time) * 2)
end

--- Calculate a sine-eased pulse from a minimum to a maximum and back.
-- @function tween.pulse
-- @param minimum_value number: Lower bound.
-- @param maximum_value number: Upper bound.
-- @param time number: Normalized time, normally between 0 and 1.
-- @return number: Pulsed value.
function cb.tween.pulse(minimum_value, maximum_value, time)
    local value_range = maximum_value - minimum_value

    if time <= 0.5 then
        return minimum_value + value_range * cb.tween.sine_out(time * 2)
    end

    return minimum_value + value_range * cb.tween.sine_in((1 - time) * 2)
end


-- CSV tools ----------------------------------------------------------------------------------------------------------
-- --------------------------------------------------------------------------------------------------------------------
cb.csv = {}

--- Parse CSV text into a table of rows.
-- Each row contains an array of string values.
-- Does not support quoted fields or embedded commas.
-- @function csv.parse_csv
-- @param text string: CSV content to parse.
-- @return table: Array of rows containing string values.
function cb.csv.parse_csv(text)
   local rows = {}

   for line in text:gmatch("[^\r\n]+") do
      local row = {}
      for value in (line .. ","):gmatch("(.-),") do
         row[#row + 1] = value
      end
      rows[#rows + 1] = row
   end

   return rows
end

--- Load a CSV file into a table of named definitions.
-- Uses the first row as field names and the "id" column as the table key.
-- Automatically converts numeric and boolean values.
-- @function csv.load_csv_defs
-- @param path string: Path to the CSV file.
-- @return table|nil: Definitions indexed by ID, or nil on failure.
-- @return string|nil: Error message if the file could not be opened.
function cb.csv.load_csv_defs(path)
    local file, err = io.open(path, "rb")
    if not file then return nil, err end

    local rows = cb.csv.parse_csv(file:read("*a"))
    file:close()

    local headers, defs = table.remove(rows, 1), {}

    for _, row in ipairs(rows) do
        local def = {}
        for i, key in ipairs(headers) do
            local value = row[i]
            if value == "true" then
                value = true
            elseif value == "false" then
                value = false
            else
                value = tonumber(value) or value
            end
            def[key] = value
        end

        defs[def.id] = def
        def.id = nil
    end
    return defs
end

return cb
