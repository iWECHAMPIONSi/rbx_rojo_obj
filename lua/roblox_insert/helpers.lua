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

local function refine_search(list, query)
	local return_val = {}
	for i, class in ipairs(list) do
		if class.lower_class == query then
			table.insert(return_val, class)
			table.remove(list, i)
			break
		end
	end
	local starts_with = {}
	local indexes = {}

	for i, class in ipairs(list) do
		local start, _ = string.find(class.lower_class, query, 1, true)
		if start then
			table.insert(starts_with, { name = class.name, lower_class = class.lower_class, index = start })
			table.insert(indexes, 1, i)
		end
	end
	for _, i in ipairs(indexes) do
		table.remove(list, i)
	end

	indexes = {}

	table.sort(starts_with, function(a, b)
		if a.index == b.index then
			return a.name < b.name
		end
		return a.index < b.index
	end)

	for _, pair in ipairs(starts_with) do
		table.insert(return_val, { name = pair.name, lower_class = pair.lower_class })
	end

	local fuzzy = vim.fn.matchfuzzy(list, query, { key = "lower_class" })
	for _, class in ipairs(fuzzy) do
		for i, pair in ipairs(list) do
			if pair.name == class.name then
				table.insert(indexes, i)
			end
		end
	end
	table.sort(indexes, function(a, b)
		return a > b
	end)

	for index, i in ipairs(indexes) do
		table.insert(return_val, fuzzy[index])
		table.remove(list, i)
	end
	local l = {}

	for _, class in ipairs(list) do
		local score = levenshtein(class.lower_class, query)
		if score <= 3 then
			table.insert(l, { name = class.name, lower_class = class.lower_class, score = score })
		end
	end
	table.sort(l, function(a, b)
		return a.score < b.score
	end)

	for _, class in ipairs(l) do
		table.insert(return_val, { name = class.name, lower_class = class.lower_class })
	end
	return return_val
end

m.refine_search = refine_search

return m
