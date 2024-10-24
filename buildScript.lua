-- List of files to be concatenated, in the correct order based on dependencies.
local home = os.getenv("USERPROFILE")
local inputFiles = {
    "stringsExtended.lua", -- dependency
    "object.lua",          -- Base class definitions (needs to come first)
    "profile.lua",         -- Profile class, dependent on base classes
    "slot_functions.lua",  -- Slot functions definitions
    "button.lua",          -- Button class
    "thumbstickaxis.lua",  -- Thumbstick Axis class
    "controller.lua",      -- Controller class, depends on the above modules
    "xc.lua",              -- Main controller instantiation
}

local success, _, rc = os.execute("if lua tests.lua; then exit 0; else exit 1; fi")
if success and rc == 0 then

    local function mkdir(dirname)
    os.execute(string.format("if not exist %s mkdir %s", dirname, dirname))
    end

    mkdir(string.format("%s\\mach4\\build", home))

    for idx, file in ipairs(inputFiles) do
    inputFiles[idx] = string.format("%s\\mach4\\%s", home, file)
    end

    local outputFile = string.format("%s\\mach4\\build\\xc.lua", home)
    local precompiledOutput = string.format("%s\\mach4\\build\\combined.luac", home)
    local removeDevSections = true  -- Toggle to strip dev-specific code


    -- Function to remove tagged sections based on start and end markers
    local function stripTaggedSections(contents, startTag, endTag)
        local result = {}
        local skipping = false
        
        for line in contents:gmatch("[^\r\n]+") do
            
            if line:find(startTag) then
                skipping = true
            elseif line:find(endTag) then
                skipping = false
            elseif line:match("^%s*%-%-") then
                -- skip comments
            elseif not skipping then
                table.insert(result, line)
            end
        end
        return table.concat(result, "\n")
    end

    -- Function to concatenate files and handle preprocessing
    local function concatenateFiles()
        local combinedContent = ""
        for _, filePath in ipairs(inputFiles) do
            local file = io.open(filePath, "r")
            if file then
                local content = file:read("*a")
                file:close()

                -- Remove dev-specific sections if required
                if removeDevSections then
                    content = stripTaggedSections(content, "-- DEV_ONLY_START", "-- DEV_ONLY_END")
                end
                
                combinedContent = combinedContent .. content .. "\n"
            else
                print("Warning: Could not open file " .. filePath)
            end
        end

        -- Write combined content to output file
        local outputFileHandle = io.open(outputFile, "w+")
        if outputFileHandle then
            outputFileHandle:write(combinedContent)
            outputFileHandle:close()
        else
            error("Failed to open output file for writing: " .. outputFile)
        end

        --[[ Precompile the Lua script if needed
        local success, err = os.execute("luac -o " .. precompiledOutput .. " " .. outputFile)
        if not success then
            print("Error during precompilation: " .. (err or "unknown error"))
        end]]
    end

    -- Run the build process
    concatenateFiles()

    os.execute("darklua process C:\\Users\\Michael\\mach4\\build\\xc.lua C:\\Users\\Michael\\mach4\\build\\xc_dark.lua")
    os.execute("darklua minify C:\\Users\\Michael\\mach4\\build\\xc_dark.lua C:\\Users\\Michael\\mach4\\build\\xc_dark_min.lua")
else
    os.exit(1)
end