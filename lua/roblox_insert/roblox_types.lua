local roblox_types = {}
local data = require("roblox_insert.data")
local brick_colors = data.colors
local enums = data.raw.Enums

local font_families = {
	["Accanthis ADF Std"] = "AccanthisADFStd",
	["Amatic SC"] = "AmaticSC",
	["Arimo"] = "Arimo",
	["Balthazar"] = "Balthazar",
	["Bangers"] = "Bangers",
	["Builder Extended"] = "BuilderExtended",
	["Builder Mono"] = "BuilderMono",
	["Builder Sans"] = "BuilderSans",
	["Comic Neue Angular"] = "ComicNeueAngular",
	["Creepster"] = "Creepster",
	["Denk One"] = "DenkOne",
	["Fondamento"] = "Fondamento",
	["Fredoka One"] = "FredokaOne",
	["Grenze Gotisch"] = "GrenzeGotisch",
	["Guru"] = "Guru",
	["Highway Gothic"] = "HighwayGothic",
	["Inconsolata"] = "Inconsolata",
	["Indie Flower"] = "IndieFlower",
	["Josefin Sans"] = "JosefinSans",
	["Jura"] = "Jura",
	["Kalam"] = "Kalam",
	["Luckiest Guy"] = "LuckiestGuy",
	["Merriweather"] = "Merriweather",
	["Michroma"] = "Michroma",
	["Montserrat"] = "Montserrat",
	["Nunito"] = "Nunito",
	["Oswald"] = "Oswald",
	["Patrick Hand"] = "PatrickHand",
	["Permanent Marker"] = "PermanentMarker",
	["Press Start 2P"] = "PressStart2P",
	["Roboto"] = "Roboto",
	["Roboto Condensed"] = "RobotoCondensed",
	["Roboto Mono"] = "RobotoMono",
	["Roman Antique"] = "RomanAntique",
	["Sarpanch"] = "Sarpanch",
	["Source Sans Pro"] = "SourceSansPro",
	["Special Elite"] = "SpecialElite",
	["Titillium Web"] = "TitilliumWeb",
	["Ubuntu"] = "Ubuntu",
	["Zekton"] = "Zekton",
}

-- Legacy Enum.Font names that differ from the family filename.
local font_aliases = {
	Antique = "RomanAntique",
	Arcade = "PressStart2P",
	Arial = "Arimo",
	ArialBold = "Arimo",
	ArimoBold = "Arimo",
	Bodoni = "AccanthisADFStd",
	BuilderSansMedium = "BuilderSans",
	BuilderSansBold = "BuilderSans",
	BuilderSansExtraBold = "BuilderSans",
	Cartoon = "ComicNeueAngular",
	Code = "Inconsolata",
	Fantasy = "Balthazar",
	Garamond = "Guru",
	Highway = "HighwayGothic",
	Legacy = "LegacyArial",
	SciFi = "Zekton",
	SourceSans = "SourceSansPro",
	SourceSansBold = "SourceSansPro",
	SourceSansItalic = "SourceSansPro",
	SourceSansLight = "SourceSansPro",
	SourceSansSemibold = "SourceSansPro",
}

local font_lookup = {}

for display_name, filename in pairs(font_families) do
	font_lookup[display_name] = filename
	font_lookup[filename] = filename
end

for alias, filename in pairs(font_aliases) do
	font_lookup[alias] = filename
end

local function verify_font(name)
	if type(name) ~= "string" then
		return false, nil
	end

	local filename = font_lookup[name]

	if not filename then
		return false, nil
	end

	return true, filename
end

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
				return true,
					return_val,
					{
						Hex = nil,
						R = tostring(return_val[1] * 255.0),
						G = tostring(return_val[2] * 255.0),
						B = tostring(return_val[3] * 255.0),
					}
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
		return true,
			return_val,
			{
				Hex = nil,
				R = tostring(return_val[1] * 255.0),
				G = tostring(return_val[2] * 255.0),
				B = tostring(return_val[3] * 255.0),
			}
	end
	return false
end

local function verify_vector_3(t)
	local return_val = {}
	local indexes = 0
	for k, i in pairs(t) do
		indexes = indexes + 1
		if tonumber(i) == nil then
			return false, nil, t
		end
		return_val[k] = tonumber(i)
	end
	if indexes == 3 then
		return_val = {
			return_val.X,
			return_val.Y,
			return_val.Z,
		}
		return true, return_val, t
	end
	return false, nil, t
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
		return true, return_val, t
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
		return true, return_val, t
	end,
}

roblox_types.BinaryString = {
	lua_type = "string",
	fields = {
		"",
	},
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
		if type(t) ~= "string" or not string.match(t, "^[%w+/]*=?=?$") then
			return false, nil
		end
		return true, t
	end,
}

roblox_types.Bool = {
	lua_type = "bool",
	fields = {
		"",
	},
	verification = function(t)
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

roblox_types.BrickColor = {
	lua_type = "string|number",
	fields = {
		"Color",
	},
	verification = function(t)
		if handle_nil(t) then
			return true, nil
		end
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
		if indexes >= 3 then
			if return_val.X ~= nil and return_val.Y ~= nil and return_val.Z ~= nil then
				local copy = vim.deepcopy(return_val)
				return_val = {
					position = { return_val.X, return_val.Y, return_val.Z },
					orientation = {
						{ return_val.R00 or 1.0, return_val.R01 or 0.0, return_val.R02 or 0.0 },
						{ return_val.R10 or 0.0, return_val.R11 or 1.0, return_val.R12 or 0.0 },
						{ return_val.R20 or 0.0, return_val.R21 or 0.0, return_val.R22 or 1.0 },
					},
				}
				return true,
					return_val,
					{
						X = copy.X,
						Y = copy.Y,
						Z = copy.Z,
						R00 = copy.R00 or 1.0,
						R01 = copy.R01 or 0.0,
						R02 = copy.R02 or 0.0,
						R10 = copy.R10 or 0.0,
						R11 = copy.R11 or 1.0,
						R12 = copy.R12 or 0.0,
						R20 = copy.R20 or 0.0,
						R21 = copy.R21 or 0.0,
						R22 = copy.R22 or 1.0,
					}
			end
			return false, nil
		end
		return false, nil
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
		local correct = {}
		for _, keypoint in ipairs(t) do
			local valid, k, corrected =
				verify_color_3({ R = keypoint.R, G = keypoint.G, B = keypoint.B, Hex = keypoint.Hex })
			if valid then
				if not corrected then
					error("unreachable state reached")
				end
				local time = clamp(keypoint.time, 0.0, 1.0)
				table.insert(correct, { time = tostring(time), R = corrected.R, G = corrected.G, B = corrected.B })
				table.insert(return_val, {
					time = time,
					color = k,
				})
			else
				return false, nil
			end
		end
		return #return_val >= 2, { keypoints = return_val }, correct
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
		return true, return_val, t
	end,
}

roblox_types.Float32 = {
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

roblox_types.Float64 = {
	lua_type = "number",
	fields = {
		"",
	},
	verification = function(t)
		return tonumber(t) ~= nil, tonumber(t)
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
		local tmp = vim.deepcopy(t)
		local family = t.family
		if family then
			local return_val = {}

			local valid
			valid, family = verify_font(family)
			tmp.family = t.family
			if valid then
				return_val.family = "rbxasset://fonts/families/" .. family .. ".json"
			else
				return false, nil
			end

			local weight = t.weight or "Regular"
			tmp.weight = weight
			valid, _ = verify_enum("FontWeight", weight)
			if valid then
				return_val.weight = weight
			else
				return_val.weight = "Regular"
				tmp.weight = "Regular"
			end

			local style = t.style or "Normal"
			tmp.style = style
			valid, _ = verify_enum("FontStyle", style)
			if valid then
				return_val.style = style
			else
				return_val.style = "Normal"
				tmp.style = "Normal"
			end
			return true, return_val, tmp
		end
		return false, nil
	end,
}

roblox_types.Int32 = {
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

roblox_types.Int64 = {
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
		return true, { min, max }, t
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
		local tmp = vim.deepcopy(t)
		local return_val = {}
		for _, keypoint in ipairs(tmp) do
			local value = tonumber(keypoint.value)
			if value ~= nil then
				local time = clamp(keypoint.time, 0.0, 1.0)
				local envelope = tonumber(keypoint.envelope) or 0.0
				table.insert(return_val, {
					time = time,
					value = value,
					envelope = envelope,
				})
				keypoint.envelope = tostring(envelope)
				keypoint.time = tostring(time)
			else
				return false, nil
			end
		end
		return #return_val >= 2, { keypoints = return_val }, tmp
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
		local tmp = vim.deepcopy(t)
		if next(t) == nil then
			return true, "Default"
		end
		local return_val = {}
		return_val.density = clamp(t.density, 0.0001, 100.0, 0.5)
		tmp.density = tostring(return_val.density)
		return_val.friction = clamp(t.friction, 0.0, 2.0, 1.0)
		tmp.friction = tostring(return_val.friction)
		return_val.elasticity = clamp(t.elasticity, 0.0, 1.0, 0.0)
		tmp.elasticity = tostring(return_val.elasticity)
		return_val.frictionWeight = clamp(t.frictionWeight, 0.0, 100.0, 50.0)
		tmp.frictionWeight = tostring(return_val.frictionWeight)
		return_val.elasticityWeight = clamp(t.elasticityWeight, 0.0, 100.0, 25.0)
		tmp.elasticityWeight = tostring(return_val.elasticityWeight)
		return_val.acousticAbsorption = clamp(t.acousticAbsorption, 0.0, 1.0, 1.0)
		tmp.acousticAbsorption = tostring(return_val.acousticAbsorption)
		return true, return_val, tmp
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
		return true, return_val, t
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
		return true, { corner0, corner1 }, t
	end,
}

roblox_types.String = {
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
			return true, return_val, t
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
			return true, return_val, t
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

return roblox_types
