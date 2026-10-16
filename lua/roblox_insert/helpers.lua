local m = {}

local function levenshtein(a, b)
	a = a:lower()
	b = b:lower()

	local previous = {}

	for j = 0, #b do
		previous[j] = j
	end

	for i = 1, #a do
		local current = { [0] = i }

		for j = 1, #b do
			local cost = a:byte(i) == b:byte(j) and 0 or 1

			current[j] = math.min(
				previous[j] + 1, -- Deletion
				current[j - 1] + 1, -- Insertion
				previous[j - 1] + cost -- Substitution
			)
		end

		previous = current
	end

	return previous[#b]
end

m.levenshtein = levenshtein

return m
