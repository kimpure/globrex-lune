local regexp = require("../luau_packages/luau_regexp")

local isWin = require("@lune/process").os == "windows"
local SEP = if isWin then "\\\\+" else "\\/"
local SEP_ESC = if isWin then "\\\\" else "/"
local GLOBSTAR = "((?:[^/]*(?:/|$))*)"
local WILDCARD = "([^/]*)"
local GLOBSTAR_SEGMENT = `((?:[^{SEP_ESC}]*(?:{SEP_ESC}|$))*)`
local WILDCARD_SEGMENT = `([^{SEP_ESC}]*)`

type Array<T> = { [number]: T }

type RegExp = {
	_innerRegEx: any,
	global: boolean,
	ignoreCase: boolean,
	multiline: boolean,
	source: string,
	exec: (self: regexp.RegExp, input: string) -> regexp.RegExp?,
	test: (self: regexp.RegExp, input: string) -> boolean,
}

export type Globrex = {
	regex: RegExp,
	path: {
		globstar: RegExp,
		regex: RegExp,
		segments: Array<RegExp>,
	}?,
}

function globrex(
	glob: string,
	option: { extended: boolean?, globstar: boolean?, strict: boolean?, filepath: boolean?, flags: string? }?
)
	option = if option then option else {}
	local extended = if (option :: any).extended then (option :: any).extended else false
	local globstar = if (option :: any).globstar then (option :: any).globstar else false
	local strict = if (option :: any).strict then (option :: any).strict else false
	local filepath = if (option :: any).filepath then (option :: any).filepath else false
	local flags = if (option :: any).flags then (option :: any).flags else ""

	local regex = ""
	local segment = ""
	local path = { regex = "" :: string | regexp.RegExp, segments = {} }

	local inGroup = false
	local inRange = false

	local ext = {}

	local function add(str: string, split: boolean?, last: boolean?, only: string?)
		if only ~= "path" then
			regex = `{regex}{str}`
		end
		if not (filepath and only ~= "regex") then
			return
		end
		path.regex = `{path.regex}{if str == "\\/" then SEP else str}`
		if not split then
			segment = `{segment}{str}`
			return
		end
		if last then
			segment = `{segment}{str}`
		end
		if segment ~= "" then
			if not (flags :: string):find("g") then
				segment = `^{segment}$`
			end
			table.insert(path.segments, regexp.new(segment, flags))
		end
		segment = ""
	end

	local c, n
	local i = 0
	while i <= #glob do
		i += 1
		c = glob:sub(i, i)
		n = glob:sub(i + 1, i + 1)

		if table.find({ "\\", "$", "^", ".", "=" }, c) then
			add(`\\{c}`)
			continue
		end

		if c == "/" then
			add(`\\{c}`, true)
			if (n == "/") and not strict then
				regex = `{regex}?`
			end
			continue
		end

		if c == "(" then
			if #ext ~= 0 then
				add(c)
				local type = table.remove(ext) :: string
				if type == "@" then
					add("{1}")
				elseif type == "!" then
					add("([^/]*)")
				else
					add(type)
				end
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "|" then
			if #ext ~= 0 then
				add(c)
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "+" then
			if n == "(" and extended then
				table.insert(ext, c)
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "@" and extended then
			if n == "(" then
				table.insert(ext, c)
				continue
			end
		end

		if c == "!" then
			if not extended then
				add(`\\{c}`)
				continue
			end
			if inRange then
				add("^")
				continue
			end
			if n == "(" then
				table.insert(ext, c)
				add("(?!")
				i += 1
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "?" then
			if not extended then
				add(`\\{c}`)
				continue
			end
			if n == "(" then
				table.insert(ext, c)
			else
				add(".")
			end
			continue
		end

		if c == "[" then
			if inRange and n == ":" then
				i += 1
				local value = ""
				while glob:sub(i + 1, i + 1) ~= ":" do
					value = `{value}{glob:sub(i, i)}`
					i += 1
				end
				if value == "alnum" then
					add("(\\w|\\d)")
				elseif value == "space" then
					add("\\s")
				elseif value == "digit" then
					add("\\d")
				end
				i += 1
				continue
			end
			if extended then
				inRange = true
				add(c)
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "]" then
			if extended then
				inRange = false
				add(c)
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "{" then
			if extended then
				inGroup = true
				add("(")
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "}" then
			if extended then
				inGroup = false
				add(")")
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "," then
			if inGroup then
				add("|")
				continue
			end
			add(`\\{c}`)
			continue
		end

		if c == "*" then
			if n == "(" and extended then
				table.insert(ext, c)
				continue
			end

			local prevChar = glob:sub(i - 1, i - 1)
			local starCount = 1
			while glob:sub(i + 1, i + 1) == "*" do
				starCount += 1
				i += 1
			end
			local nextChar = glob:sub(i + 1, i + 1)
			if not globstar then
				add(".*")
			else
				local isGlobstar = if (
						starCount > 1
						and (prevChar == "/" or prevChar == string.sub("w", 0, 0))
						and (nextChar == "/" or nextChar == string.sub("w", 0, 0))
					)
					then true
					else false
				if isGlobstar then
					add(GLOBSTAR, nil, nil, "regex")
					add(GLOBSTAR_SEGMENT, true, true, "path")
					i += 1
				else
					add(WILDCARD, nil, nil, "regex")
					add(WILDCARD_SEGMENT, nil, nil, "path")
				end
			end
			continue
		end

		add(c)
	end

	if not (flags :: string):find("g") then
		regex = `^{regex}$`
		segment = `^{segment}$`
		if filepath then
			path.regex = `^{path.regex}$`
		end
	end

	local result = { regex = (regexp.new(regex, flags) :: any) :: RegExp, path = nil :: any }

	if filepath then
		table.insert(path.segments, regexp.new(segment, flags))
		path.regex = (regexp.new(path.regex, flags) :: any) :: regexp.RegExp
		path.globstar =
			regexp.new(if not (flags :: string):find("g") then `^{GLOBSTAR_SEGMENT}$` else GLOBSTAR_SEGMENT, flags)
		result.path = path
	end

	return result :: Globrex
end

return globrex
