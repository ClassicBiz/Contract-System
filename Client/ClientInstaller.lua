-- Installer Program for Contract Client PC
local github_files = {
    startup = "https://raw.githubusercontent.com/ClassicBiz/ContractClient/main/startup.lua",
    api = "https://raw.githubusercontent.com/ClassicBiz/ContractClient/main/API/SharedAPI.lua"
}

local peripheralsTable = {}

function downloadFile(url, savePath)
    print("Downloading from: " .. url)
    local response = http.get(url)
    if response then
        local file = fs.open(savePath, "w")
        file.write(response.readAll())
        file.close()
        print("Downloaded and saved to " .. savePath)
    else
        print("Failed to download from " .. url)
    end
end

function createDirectory(dir)
    if not fs.exists(dir) then
        fs.makeDir(dir)
        print("Created directory: " .. dir)
    end
end

function installBasalt()
    print("Installing Basalt UI...")
    shell.run("wget run https://basalt.madefor.cc/install.lua release latest.lua")
end

function moveBasaltToAPI()
    local basaltFile = "basalt.lua"
    local targetPath = "API/basalt.lua"
    
    createDirectory("API")
    
    if fs.exists(basaltFile) then
        local success, err = pcall(function() fs.move(basaltFile, targetPath) end)
        if success then
            print("Moved Basalt UI into /API/")
        else
            print("Error moving file: " .. err)
        end
    else
        print("Basalt UI file not found, skipping move.")
    end
end

function scanPeripherals()
    local peripheralNames = peripheral.getNames()
    local labels = {
        ["minecraft:chest"] = {"Inventory", "cashChest"},
        ["minecraft:dispenser"] = {"dispenser"}
    }

    local labelIndex = {
        ["minecraft:chest"] = 1,
        ["minecraft:dispenser"] = 1
    }

    for _, name in ipairs(peripheralNames) do
        local peripheralType = peripheral.getType(name)
        if name == "bottom" then
            print("skip")
        else
            if labels[peripheralType] then
                local currentLabelIndex = labelIndex[peripheralType]
                local label = labels[peripheralType][currentLabelIndex]

                if label then
                    local number = tonumber(name:match("_(%d+)$")) or name
                    table.insert(peripheralsTable, {
                        type = peripheralType,
                        name = number,
                        label = label
                    })

                    print("Assigned " .. peripheralType .. " " .. name .. " as " .. label)
                    labelIndex[peripheralType] = currentLabelIndex + 1
                end
            end
        end
    end
    
    local file = fs.open("peripherals.json", "w")
    file.write(textutils.serialize(peripheralsTable))
    file.close()
end

function runInstaller()
    createDirectory("/API/")
    downloadFile(github_files.startup, "startup.lua")
    downloadFile(github_files.api, "/API/ContAPI.lua")
    installBasalt()
    moveBasaltToAPI()
    scanPeripherals()
    print("Installation complete.")
    print("Peripherals found:", #peripheralsTable)
end

runInstaller()
