
local http = require("http.request")
local parser = require("htmlparser")
local baseUrl = "https://wiki.garrysmod.com"
local requestTimeout = 10
local dumpPath = "globals.txt"
local data = {}
local selectors = {
	Hooks = "ul li h2",
	Libraries = "ul li h2",
	Classes = "ul li h2",
	Global = "ul li a",
	Classes = "ul li h2",
	Panels = "ul li h2"
}

local function GetPageContents(segment)
	local url = baseUrl .. segment
	print(string.format("downloading content from %s...", url))

	local request = http.new_from_uri(url)
	local headers, stream = request:go(requestTimeout)

	if (not headers) then
		io.strerr:write(tostring(stream), "\n")
		os.exit(1)
	end

	local body, errorStatus = stream:get_body_as_string()

	if (not body and errorStatus) then
		io.stderr:write(tostring(errorStatus), "\n")
		os.exit(1)
	end

	return body
end

local function AddToData(entry)
	data[entry] = true
end

local function AssembleData()
	local result = string.format("stds.garrysmod = {}\r\nstds.garrysmod.read_globals = {\r\n\t-- Generated on %s\r\n", os.date("%c"))

	for k, v in pairs(data) do
		result = result .. string.format("\t\"%s\",\r\n", tostring(k))
	end

	result = result .. "\t-- End generated code\r\n}\r\n"
	return result
end

local function DumpSection(info)
	for k, v in ipairs(info) do
		AddToData(v:getcontent())
	end
end

local function DumpEnums(links)
	for k, v in ipairs(links) do
		local contents = GetPageContents(v.attributes.href)
		local root = parser.parse(contents, 2000000)
		local enums = root:select("table.wikitable.sortable tr")
		
		for k2, v2 in ipairs(enums) do
			local headerRow = v2:select("th")

			-- regular rows won't have th elements
			if (#headerRow == 0) then
				local tableClasses = v2.parent.classes

				-- if the parent table is a note, ignore it since it wont have a valid var
				if (tableClasses and tableClasses[1] and tableClasses[1] ~= "gmodwiki_note") then
					local columns = v2:select("td")
					local element = columns[1]

					if (element) then
						local value = element:getcontent():gsub("%s", "")
						local dot = value:find(".", 1, true)
						local breakStart, breakEnd = value:find("<br/>")

						-- if we found a dot, then it's a table enum
						if (dot) then
							value = value:sub(1, dot - 1)
						-- if we find a break, then add both lines
						elseif (breakStart) then
							local firstValue = value:sub(1, breakStart - 1)
							AddToData(firstValue)
							
							value = value:sub(breakEnd + 1, value:len())
						end

						AddToData(value)
					end
				end
			end
		end
	end
end

local function WriteDump()
	local file = assert(io.open(dumpPath, "w"))
		file:write(AssembleData())
	file:close()
end

local function Dump(contents, bWrite)
	contents = GetPageContents("/navbar")

	print("parsing html...")
	-- clean up some elements we don't need
	contents = contents:gsub("<a class='navbarlink' href='(.-)</a>", "")

	local root = parser.parse(contents, 2000000)
	local titles = root("h1")

	print("extracting data...")
	for k, v in ipairs(titles) do
		local section = v.parent
		local sectionName = v:getcontent()

		if (selectors[sectionName]) then
			DumpSection(section:select(selectors[sectionName]))
		elseif (sectionName == "Reference") then
			local subsections = section:select("ul li h2")

			for k2, v2 in ipairs(subsections) do
				if (v2:getcontent() == "Enumerations") then
					DumpEnums(v2.parent:select("ul li a"))
					break
				end
			end
		end
	end
	
	print("writing dump to disk...")
	WriteDump()
end

Dump()
