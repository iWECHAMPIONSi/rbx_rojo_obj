local roblox_types = {}
local data = require("roblox_insert.data")
local brick_colors = data.colors
local enums = data.raw.Enums

local function handle_nil(t)
	if t == "nil" then
		return true
	end
	return false
end

local function clamp(v, min, max, default)
	return math.max(min, math.min(max, tonumber(v) or default or min))
end

local function verify_enum(enum, field)
	return enums[enum][field] ~= nil, enums[enum][field]
end

local function verify_color_3(t)
	local return_val = {}
	if t.Hex then
		if type(t.Hex) == "string" then
			if string.match(t.Hex, "^%x%x%x%x%x%x$") then
				return_val = {
					math.min(tonumber(string.sub(t.Hex, 1, 2), 16), 255) / 255.0,
					math.min(tonumber(string.sub(t.Hex, 3, 4), 16), 255) / 255.0,
					math.min(tonumber(string.sub(t.Hex, 5, 6), 16), 255) / 255.0,
				}
				return true, return_val
			end
		end
	end
	local indexes = 0
	for k, i in pairs(t) do
		indexes = indexes + 1
		if tonumber(i) == nil and k ~= "Hex" then
			return false, nil
		end
		return_val[k] = tonumber(i)
	end
	if indexes == 3 and return_val.Hex == nil or indexes == 4 then
		return_val = {
			clamp(return_val.R, 0, 255) / 255.0,
			clamp(return_val.G, 0, 255) / 255.0,
			clamp(return_val.B, 0, 255) / 255.0,
		}
		return true, return_val
	end
	return false
end

local function verify_vector_3(t)
	local return_val = {}
	local indexes = 0
	for k, i in pairs(t) do
		indexes = indexes + 1
		if tonumber(i) == nil then
			return false, nil
		end
		return_val[k] = tonumber(i)
	end
	if indexes == 3 then
		return_val = {
			return_val.X,
			return_val.Y,
			return_val.Z,
		}
		return true, return_val
	end
	return false, nil
end

local function verify_vector_2(t)
	local return_val = {}
	local indexes = 0
	for k, i in pairs(t) do
		indexes = indexes + 1
		if tonumber(i) == nil then
			return false, nil
		end
		return_val[k] = tonumber(i)
	end
	if indexes == 2 then
		return_val = {
			return_val.X,
			return_val.Y,
		}
		return true, return_val
	end
	return false, nil
end

roblox_types.Axes = {
	lua_type = "table",
	fields = {
		"X",
		"Y",
		"Z",
	},
	verification = function(t)
		local return_val = {}
		if t.X == "true" then
			table.insert(return_val, "X")
		end
		if t.Y == "true" then
			table.insert(return_val, "Y")
		end
		if t.Z == "true" then
			table.insert(return_val, "Z")
		end
		return true, return_val
	end,
}

roblox_types.BinaryString = {
	lua_type = "string",
	fields = {
		"",
	},
	verification = function(t)
		if type(t) ~= "string" or not string.match(t, "^[%w+/]*=?=?$") then
			return false, nil
		end
		return true, t
	end,
}

roblox_types.BrickColor = {
	lua_type = "string|number",
	fields = {
		"Color",
	},
	verification = function(t)
		local number = tonumber(t)

		if number then
			return brick_colors[number] ~= nil, number
		end

		return brick_colors[t] ~= nil, brick_colors[t]
	end,
}

roblox_types.CFrame = {
	lua_type = "table",
	fields = {
		"X",
		"Y",
		"Z",
		"R00",
		"R01",
		"R02",
		"R10",
		"R11",
		"R12",
		"R20",
		"R21",
		"R22",
	},
	verification = function(t)
		local return_val = {}
		local indexes = 0
		for k, i in pairs(t) do
			indexes = indexes + 1
			if tonumber(i) == nil then
				return false, nil
			end
			return_val[k] = tonumber(i)
		end
		if indexes == 3 then
			if return_val.X ~= nil and return_val.Y ~= nil and return_val.Z ~= nil then
				return_val = {
					position = { return_val.X, return_val.Y, return_val.Z },
					orientation = {
						{ 0.0, 0.0, 0.0 },
						{ 0.0, 0.0, 0.0 },
						{ 0.0, 0.0, 0.0 },
					},
				}
				return true, return_val
			end
			return false, nil
		elseif indexes == 12 then
			return_val = {
				position = { return_val.X, return_val.Y, return_val.Z },
				orientation = {
					{ return_val.R00, return_val.R01, return_val.R02 },
					{ return_val.R10, return_val.R11, return_val.R12 },
					{ return_val.R20, return_val.R21, return_val.R22 },
				},
			}
			return true, return_val
		end
		return false
	end,
}
roblox_types.Color3 = {
	lua_type = "table",
	fields = {
		"Hex",
		"R",
		"G",
		"B",
	},
	verification = function(t)
		return verify_color_3(t)
	end,
}

roblox_types.ColorSequence = {
	lua_type = "nested table",
	fields = {
		"time",
		"Hex",
		"R",
		"G",
		"B",
	},
	verification = function(t)
		local return_val = {}
		for _, keypoint in ipairs(t) do
			local valid, k = verify_color_3({ R = keypoint.R, G = keypoint.G, B = keypoint.B, Hex = keypoint.Hex })
			if valid then
				table.insert(return_val, {
					time = clamp(keypoint.time, 0.0, 1.0),
					color = k,
				})
			else
				return false, nil
			end
		end
		return #return_val >= 2, { keypoints = return_val }
	end,
}

roblox_types.Content = {
	lua_type = "number",
	fields = {
		"rbxassetid://",
	},
	verification = function(t)
		local i = tonumber(t)
		if i == nil then
			return false
		end
		return math.floor(i) == i, "rbxassetid://" .. (i or "")
	end,
}

roblox_types.ContentId = {
	lua_type = "number",
	fields = {
		"rbxassetid://",
	},
	verification = function(t)
		local i = tonumber(t)
		if i == nil then
			return false
		end
		return math.floor(i) == i, "rbxassetid://" .. (i or "")
	end,
}

roblox_types.Enum = {
	lua_type = "enum",
	fields = {
		"",
	},
	verification = function(enum, field)
		if handle_nil(field) then
			return true, nil
		end
		return verify_enum(enum, field)
	end,
}

roblox_types.Faces = {
	lua_type = "table",
	fields = {
		"Right",
		"Top",
		"Back",
		"Left",
		"Bottom",
		"Front",
	},
	verification = function(t)
		local return_val = {}

		for face, value in pairs(t) do
			if value == "true" then
				table.insert(return_val, face)
			end
		end
		return true, return_val
	end,
}

roblox_types.Font = {
	lua_type = "table",
	fields = {
		"family",
		"weight",
		"style",
	},
	verification = function(t)
		local family = t.family
		if family then
			local return_val = {}

			local valid
			valid, _ = verify_enum("Font", family)
			if valid then
				return_val.family = "rbxasset://fonts/families/" .. family .. ".json"
			else
				return false, nil
			end

			local weight = t.weight or "Regular"
			valid, _ = verify_enum("FontWeight", weight)
			if valid then
				return_val.weight = weight
			else
				return_val.weight = "Regular"
			end

			local style = t.style or "Normal"
			valid, _ = verify_enum("FontStyle", style)
			if valid then
				return_val.style = style
			else
				return_val.style = "Normal"
			end
			return true, return_val
		end
		return false, nil
	end,
}

roblox_types.NumberRange = {
	lua_type = "table",
	fields = {
		"Min",
		"Max",
	},
	verification = function(t)
		local min = tonumber(t.Min)
		local max = tonumber(t.Max)
		if min == nil or max == nil then
			return false, nil
		end
		return true, { min, max }
	end,
}

roblox_types.NumberSequence = {
	lua_type = "nested table",
	fields = {
		"time",
		"value",
		"envelope",
	},
	verification = function(t)
		local return_val = {}
		for _, keypoint in ipairs(t) do
			local value = tonumber(keypoint.value)
			if value ~= nil then
				local time = clamp(keypoint.time, 0.0, 1.0)
				local envelope = tonumber(keypoint.envelope) or 0.0
				table.insert(return_val, {
					time = time,
					value = value,
					envelope = envelope,
				})
			else
				return false, nil
			end
		end
		return #return_val >= 2, { keypoints = return_val }
	end,
}

roblox_types.PhysicalProperties = {
	lua_type = "table",
	fields = {
		"density",
		"friction",
		"elasticity",
		"frictionWeight",
		"elasticityWeight",
		"acousticAbsorption",
	},
	verification = function(t)
		if next(t) == nil then
			return true, "Default"
		end
		local return_val = {}
		return_val.density = clamp(t.density, 0.0001, 100.0, 0.5)
		return_val.friction = clamp(t.friction, 0.0, 2.0, 1.0)
		return_val.elasticity = clamp(t.elasticity, 0.0, 1.0, 0.0)
		return_val.frictionWeight = clamp(t.frictionWeight, 0.0, 100.0, 50.0)
		return_val.elasticityWeight = clamp(t.elasticityWeight, 0.0, 100.0, 25.0)
		return_val.acousticAbsorption = clamp(t.acousticAbsorption, 0.0, 1.0, 1.0)
		return true, return_val
	end,
}

roblox_types.ProtectedString = {
	lua_type = "string",
	fields = {
		"",
	},
	verification = function(t)
		if type(t) == "string" then
			return string.len(t) > 0, t
		end
		return false, nil
	end,
}

roblox_types.Ray = {
	lua_type = "table",
	fields = {
		"originX",
		"originY",
		"originZ",
		"directionX",
		"directionY",
		"directionZ",
	},
	verification = function(t)
		local return_val = {}
		local verify
		verify, return_val.origin = verify_vector_3({ X = t.originX, Y = t.originY, Z = t.originZ })
		if not verify then
			return false, nil
		end
		verify, return_val.direction = verify_vector_3({ X = t.directionX, Y = t.directionY, Z = t.directionZ })
		if not verify then
			return false, nil
		end
		return true, return_val
	end,
}

roblox_types.Rect = {
	lua_type = "table",
	fields = {
		"X0",
		"Y0",
		"X1",
		"Y1",
	},
	verification = function(t)
		local verify
		local corner0
		verify, corner0 = verify_vector_2({ X = t.X0, Y = t.Y0 })
		if not verify then
			return false, nil
		end
		local corner1
		verify, corner1 = verify_vector_2({ X = t.X1, Y = t.Y1 })
		if not verify then
			return false, nil
		end
		return true, { corner0, corner1 }
	end,
}

roblox_types.UDim = {
	lua_type = "table",
	fields = {
		"Scale",
		"Offset",
	},
	verification = function(t)
		local return_val = {}
		local indexes = 0
		for k, i in pairs(t) do
			indexes = indexes + 1
			if tonumber(i) == nil then
				return false, nil
			end
			return_val[k] = tonumber(i)
		end
		if indexes == 2 then
			return_val = { return_val.Scale, return_val.Offset }
			return true, return_val
		end
		return false
	end,
}

roblox_types.UDim2 = {
	lua_type = "table",
	fields = {
		"xScale",
		"xOffset",
		"yScale",
		"yOffset",
	},
	verification = function(t)
		local return_val = {}
		local indexes = 0
		for k, i in pairs(t) do
			indexes = indexes + 1
			if tonumber(i) == nil then
				return false, nil
			end
			return_val[k] = tonumber(i)
		end
		if indexes == 4 then
			return_val = { { return_val.xScale, return_val.xOffset }, { return_val.yScale, return_val.yOffset } }
			return true, return_val
		end
		return false
	end,
}

roblox_types.Vector2 = {
	lua_type = "table",
	fields = {
		"X",
		"Y",
	},
	verification = function(t)
		return verify_vector_2(t)
	end,
}

roblox_types.Vector3 = {
	lua_type = "table",
	fields = {
		"X",
		"Y",
		"Z",
	},
	verification = function(t)
		return verify_vector_3(t)
	end,
}
roblox_types.bool = {
	lua_type = "bool",
	fields = {
		"",
	},
	verification = function(t)
		vim.print(type(t))
		if handle_nil(t) then
			return true, nil
		end
		if t == "true" or t == "false" then
			if t == "true" then
				return true, true
			else
				return true, false
			end
		end
		return false, nil
	end,
}

roblox_types.double = {
	lua_type = "number",
	fields = {
		"",
	},
	verification = function(t)
		return tonumber(t) ~= nil, tonumber(t)
	end,
}

roblox_types.float = {
	lua_type = "number",
	fields = {
		"",
	},
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
		return tonumber(t) ~= nil, tonumber(t)
	end,
}

roblox_types.int = {
	lua_type = "number",
	fields = {
		"",
	},
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
		local i = tonumber(t)
		if i == nil then
			return false
		end
		return math.floor(i) == i, i
	end,
}

roblox_types.int64 = {
	lua_type = "number",
	fields = {
		"",
	},
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
		local i = tonumber(t)
		if i == nil then
			return false
		end
		return math.floor(i) == i, i
	end,
}

roblox_types.string = {
	lua_type = "string",
	fields = {
		"",
	},
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
		if type(t) == "string" then
			return true, t
		end
		return false, nil
	end,
}

return roblox_types
