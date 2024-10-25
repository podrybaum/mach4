-- List of files to be concatenated, in the correct order based on dependencies.
local current_dir = os.getenv("CD") or "." 
package.path = package.path .. ";" .. current_dir .. "\\?.lua"


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

local success, _, rc = os.execute('if exist tests.lua lua53 tests.lua')
if success and rc == 0 then

    

    local outputFile = string.format("%s\\build\\xc.lua", (current_dir))
    --local precompiledOutput = string.format("%s\\build\\xc_compiled.luac", (current_dir))
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

    os.execute(string.format("darklua process %s %s_dark.lua", outputFile, outputFile))
    os.execute(string.format("darklua minify %._dark.lua %s_dark_min.lua", outputFile, outputFile))


    local commit_message = "Automated build: updating xc.lua, xc_dark.lua, and xc_dark_min.lua"
    os.execute('git add build/xc.lua build/xc_dark.lua build/xc_dark_min.lua')
    os.execute(string.format('git commit -m "%s"', commit_message))
    os.execute('git push origin HEAD')

    print("Build completed and changes pushed.")
else
    print("Tests failed. Exiting build process.")
    os.exit(1)
end