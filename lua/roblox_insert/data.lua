local t = {}

local category_keys = require("roblox_insert.category_data")

local function get_plugin_root()
	local source = debug.getinfo(1, "S").source:gsub("^@", "")

	local module_directory = assert(vim.fs.dirname(source), "Unable to locate roblox_insert module directory")

	local lua_directory = assert(vim.fs.dirname(module_directory), "Unable to locate the plugin's lua directory")

	return assert(vim.fs.dirname(lua_directory), "Unable to locate the plugin root directory")
end

---@param path string
---@return string?, string?
local function read_file(path)
	local file, open_error = io.open(path, "rb")

	if file == nil then
		return nil, string.format("Attempt to open data.json failed: %s", tostring(open_error))
	end

	local contents = file:read("*a")

	if contents == nil then
		file:close()

		return nil, string.format("Attempt to read data.json failed: %s", path)
	end

	local close_success, close_error = file:close()

	if close_success == nil then
		return nil, string.format("Attempt to close data.json failed: %s", tostring(close_error))
	end

	return contents, nil
end

---@return table?, string?
function t.load()
	path = vim.fs.joinpath(get_plugin_root(), "data", "data.json")

	local contents, read_error = read_file(path)

	if contents == nil then
		return nil, read_error
	end

	local decode_success, decoded = pcall(vim.json.decode, contents)

	if not decode_success then
		return nil, string.format("Could not decode Roblox class data file '%s': %s", path, tostring(decoded))
	end

	if type(decoded) ~= "table" then
		return nil, string.format("Roblox class data file '%s' did not contain a JSON object", path)
	end
	return decoded, nil
end

local raw, err = t.load()

t.raw = {}
t.err = err

if not raw then
	return t
end

t.raw.Classes, t.raw.Enums = raw.Classes, raw.Enums

local iter_table = {}

local tempkeys = {}
local permkeys = {}

for name, _ in pairs(raw.Classes) do
	tempkeys[name] = true
end

local cat = nil
local super = nil
local classes = nil

local to_remove = {}

for _, category in ipairs(category_keys) do
	cat = category.Category
	iter_table[cat] = {}
	table.insert(permkeys, cat)
	super = category.Superclasses
	for _, class in ipairs(super) do
		for name, _ in pairs(tempkeys) do
			for _, superclass in ipairs(raw.Classes[name].NestedClasses) do
				if superclass == class then
					table.insert(iter_table[cat], name)
					table.insert(to_remove, name)
					break
				end
			end
		end
		for _, name in ipairs(to_remove) do
			tempkeys[name] = nil
		end
		to_remove = {}
	end
	classes = category.Classes
	for _, class in ipairs(classes) do
		table.insert(iter_table[cat], class)
		for name, _ in pairs(tempkeys) do
			if name == class then
				table.insert(to_remove, name)
			end
		end
	end
	for _, name in ipairs(to_remove) do
		tempkeys[name] = nil
	end
	to_remove = {}
	table.sort(iter_table[cat], function(a, b)
		return a < b
	end)
end

t.categories = iter_table
t.catkeys = permkeys

local browsable_classes = {
	AccessoryDescription = true,
	Animation = true,
	AnimationController = true,
	Animator = true,
	Atmosphere = true,
	AudioAnalyzer = true,
	AudioChannelMixer = true,
	AudioChannelSplitter = true,
	AudioChorus = true,
	AudioCompressor = true,
	AudioDeviceInput = true,
	AudioDeviceOutput = true,
	AudioDistortion = true,
	AudioEcho = true,
	AudioEmitter = true,
	AudioEqualizer = true,
	AudioFader = true,
	AudioFilter = true,
	AudioFlanger = true,
	AudioGate = true,
	AudioLimiter = true,
	AudioListener = true,
	AudioPitchShifter = true,
	AudioPlayer = true,
	AudioReverb = true,
	AudioSpeechToText = true,
	AudioTextToSpeech = true,
	AudioTremolo = true,
	Beam = true,
	BindableEvent = true,
	BindableFunction = true,
	BodyPartDescription = true,
	Clouds = true,
	Configuration = true,
	ControllerManager = true,
	Dialog = true,
	DialogChoice = true,
	Explosion = true,
	FaceControls = true,
	Fire = true,
	ForceField = true,
	HapticEffect = true,
	Highlight = true,
	Humanoid = true,
	HumanoidDescription = true,
	HumanoidRigDescription = true,
	IKControl = true,
	InputAction = true,
	InputBinding = true,
	InputContex = true,
	LocalizationTable = true,
	MakeupDescription = true,
	MaterialVariant = true,
	NoCollisionConstraint = true,
	ParticleEmitter = true,
	PathfindingLink = true,
	PathfindingModifier = true,
	ProximityPrompt = true,
	RemoteFunction = true,
	Sky = true,
	Smoke = true,
	Sound = true,
	SoundGroup = true,
	Sparkles = true,
	StyleDerive = true,
	StyleLink = true,
	StyleQuery = true,
	SurfaceAppearance = true,
	Team = true,
	TextChannel = true,
	TextChatCommand = true,
	Trail = true,
	ViewportCamera = true,
	WeldConstraint = true,
	Wire = true,
}

local non_browsable_classes = {
	AdPortal = true,
	AdvancedDragger = true,
	AnimationNodeDefinition = true,
	AnimationRigData = true,
	Backpack = true,
	CompositeValueCurve = true,
	DataStoreGetOptions = true,
	DataStoreIncrementOptions = true,
	DataStoreOptions = true,
	DataStoreSetOptions = true,
	DigitsRigDescription = true,
	Dragger = true,
	EulerRotationCurve = true,
	ExperienceInviteOptions = true,
	FloatCurve = true,
	Keyframe = true,
	KeyframeMarker = true,
	MarkerCurve = true,
	RenderingTest = true,
	RotationCurve = true,
	StarterGear = true,
	TeleportOptions = true,
	TextGenerator = true,
	ValueCurve = true,
	Vector3Curve = true,
}

t.browsable_classes = browsable_classes
t.non_browsable_classes = non_browsable_classes

return t
