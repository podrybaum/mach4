local inputFiles = {
	"C:\\Mach4Hobby\\Modules\\button.lua",
    "C:\\Mach4Hobby\\Modules\\signal_slot.lua",
    "C:\\Mach4Hobby\\Modules\\thumbstickaxis.lua",
    "C:\\Mach4Hobby\\Modules\\descriptor.lua",
	    "C:\\Mach4Hobby\\Modules\\xc.lua",

}

local outputFile = "C:\\Users\\Michael\\mach4\\combined.lua"
local precompiledOutput = "C:\\Users\\Michael\\mach4\\combined.luac"
local removeDevSections = false  -- Toggle this to strip dev-specific code

-- Function to remove dev-specific sections
local function stripDevSections(contents)
    local devOnlyStart = "-- DEV_ONLY_START"
    local devOnlyEnd = "-- DEV_ONLY_END"
    
    local result = {}
    local skipping = false
    
    for line in contents:gmatch("[^\r\n]+") do
        if line:find(devOnlyStart) then
            skipping = true
        elseif line:find(devOnlyEnd) then
            skipping = false
        elseif not skipping then
            table.insert(result, line)
        end
    end
    print("returning stripped output")
    return table.concat(result, "\n")
end

-- Function to combine all modules into one
local function combineModules(inputFiles, outputFile, removeDevSections)
    local outfile = io.open(outputFile, "w")
    if outfile ~= nil then
        for _, filename in ipairs(inputFiles) do
            local infile = io.open(filename, "r")
            if infile then
                local content = infile:read("*all")
                infile:close()

                if removeDevSections then
                    content = stripDevSections(content)
                end

                outfile:write("-- Start of ", filename, "\n")
                outfile:write(content, "\n")
                outfile:write("-- End of ", filename, "\n\n")
            else
                print("Warning: Could not open file " .. filename)
            end
        end

        outfile:close()
        print("Combined modules written to " .. outputFile)
    end
end

local function minify()
    local command = string.format("lua C:\\users\\michael\\mach4\\luasrcdiet --maximum %s -o C:\\users\\michael\\mach4\\min_combined.lua --noopt-binequiv", outputFile)
    print("Minifying source")
    local result = os.execute(command)

    if result == 0 then
        print("Successfully minified source")
    else
        print("Error during source minification.")
    end
end

-- Function to call the Lua compiler
local function compileToBytecode(inputFile, outputFile)
    local command = string.format("luac -o %s %s", outputFile, inputFile)
    print("Running command: " .. command)
    local result = os.execute(command)

    if result == 0 then
        print("Successfully compiled " .. inputFile .. " to " .. outputFile)
    else
        print("Error compiling " .. inputFile)
    end
end

-- Combine the modules and precompile them
combineModules(inputFiles, outputFile, removeDevSections)
minify()
compileToBytecode(outputFile, precompiledOutput)
