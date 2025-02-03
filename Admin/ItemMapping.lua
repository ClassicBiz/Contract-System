local basalt = require("/API/basalt")  -- Ensure Basalt is required correctly
local sharedAPI = require("/API/ContAPI") 
local itemMappingFile = "item_mapping.json"
local itemMapping = {}  -- Store item mappings
local inventory = peripheral.find("inventory")
-- sharedAPI.CommunicationAPI.initialize(100) -- Set Client PC channel to 50

local function loadItemMappings()
    -- Load the local item mappings if the file exists
    if fs.exists(itemMappingFile) then
        local file = fs.open(itemMappingFile, "r")
        if file then
            local data = file.readAll()
            sharedAPI.ItemAPI.items = textutils.unserializeJSON(data) or {}
            itemMapping = sharedAPI.ItemAPI.items
            file.close()
        end
    else
        itemMapping = sharedAPI.ItemAPI.items or {}
    end

    -- Request the latest item mappings from the server
    sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_MAPPINGS")
    local serverData = sharedAPI.CommunicationAPI.receiveMessage(3)
    if serverData then
      local serverReply = textutils.serialize(serverData)
        if serverReply and serverReply.payload then
            local serverMapping = textutils.unserializeJSON(serverReply.payload) or {}

            -- Merge server mapping into local mapping
            for item, details in pairs(serverMapping) do
                if type(details) == "string" then
                    -- Convert old format (string) to new format (table)
                    itemMapping[item] = { name = details }
                elseif type(details) == "table" and details.name then
                    -- Retain valid table format
                    itemMapping[item] = details
                else
                    print("Warning: Invalid format for item:", item)
                end
            end
        else
        end
    end

    sharedAPI.ItemAPI.saveMappings()
end

local function saveItemMappings()
    local file = fs.open(itemMappingFile, "w")
    if file then
        local formattedJSON = "{\n"
        for key, value in pairs(sharedAPI.ItemAPI.items) do
            if type(value) == "string" then
                value = { name = value }
            end
            formattedJSON = formattedJSON .. '  "' .. key .. '": ' .. textutils.serializeJSON(value) .. ",\n"
        end
        if #formattedJSON > 2 then
            formattedJSON = formattedJSON:sub(1, -3) .. "\n"
        end
        formattedJSON = formattedJSON .. "}"
        file.write(formattedJSON)
        file.close()

        -- Send updated mapping to the server
        sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "UPDATE_MAPPING", formattedJSON)
    end
end

local function generateItemName(itemID)
    local name = itemID:match(":[^:]+$"):sub(2)  -- Extract part after the colon and remove it
    name = name:gsub("_", " "):gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper()..rest:lower()
    end)
    return name
end

local function submitMapping()
    local itemID = inputID:getValue()
    local newName = newInput:getValue()
    editList:clear()
    if itemMapping[itemID] then
        local currentName = itemMapping[itemID]
        editList:addLine("Editing " .. itemID)
        editList:addLine("Current Name: " .. currentName)
        editList:addLine("Editing " .. itemID)
        editList:addLine("New Name: " .. newName)
        itemMapping[itemID] = newName
        saveItemMappings()
        
        editList:addLine("Mapping updated: " .. itemID .. " -> " .. newName)
    else
        editList:addLine("No mapping found for ".. itemID)
    end
    inputID:setValue("")
    newInput:setValue("")

end

-- Check the inventory for items and add mappings if necessary
local function checkInventory()
    invList:clear()
    if not inventory then
        invList:editLine(4, "No inventory found! Please connect a chest or other container.")
        return
    end
    invList:editLine(1,"Checking Chest For items...")
    local items = inventory.list()  -- Get all items in the inventory
    os.sleep(0.4)
    for _, item in pairs(items) do
        local itemID = item.name
        if not itemMapping[itemID] then  -- If the item isn't already mapped
            invList:editLine(1,"Found item: " .. itemID .. " not mapped.")
            
            -- Generate a name for the item if it doesn't already have one
            local itemName = generateItemName(itemID)

            -- Ask user if they want to manually edit the generated name
            invList:addLine((itemID .. ": " .. itemName))

            itemMapping[itemID] = itemName
            saveItemMappings()
        else
            invList:addLine(itemID .. " is already mapped.")
        end

    end

end

-- Display all mappings
local function viewMappingsEdit()
    editList:clear()
    editList:addLine("Current Item Mappings:")
    for id, name in pairs(itemMapping) do
        editList:addLine(string.format("%s -> %s", id, name))
    end
end

local function viewMappings()
    mappingsList:clear()
    mappingsList:addLine("Current Item Mappings:")
    for id, name in pairs(itemMapping) do
        local textname = textutils.serialise(name)
        mappingsList:addLine(string.format("%s -> %s", id, textname))
    end
end

-- Initialize Basalt main frame
main = basalt.createFrame():setTheme({FrameBG = colors.white, FrameFG = colors.gray})
local networkThread = main:addThread()

-- Create subframes for each menu option
local sub = { 
    main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"), 
    main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(),
    main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(),
}

-- Function to show the selected subframe
local function openSubFrame(id)
    if sub[id] ~= nil then
        for _, v in pairs(sub) do
            v:hide()
        end
        sub[id]:show()
    end
end

-- Create the menubar
local menubar = main:addMenubar():setScrollable()
    :setSize("parent.w")
    :setBackground(colors.lightGray)
    :setForeground(colors.white)
    :setSelectionColor(colors.lightGray, colors.lime)
    :onChange(function(self, val)
        openSubFrame(self:getItemIndex())
    end)
    :addItem("| Edit Mapping")
    :addItem("| View Mappings |")
    :addItem("Map Inventory |")

    mapFrame = sub[1]:addFrame()
    :setPosition(1, 1)
    :setSize("parent.w", "parent.h")
    :setTheme({FrameBG = colors.white})
    

    
    inputID = mapFrame:addInput():setPosition(4,4)
        inputID:setInputType("text")
        inputID:setDefaultText("    Item ID")
        inputID:setSize(16,1)

    newInput = mapFrame:addInput():setPosition(4,6)
        newInput:setInputType("text")
        newInput:setDefaultText(" New Item name")
        newInput:setSize(16,1)

-- Add content to the "Edit Mapping" subframe
mapFrame:addLabel():setText("Edit Mapping Option"):setPosition(2, 2):setForeground(colors.gray)
editList = mapFrame:addTextfield():setSize("parent.w - 1", 5):setPosition(2, 13):setBackground(colors.white):setForeground(colors.black)
mapFrame:addButton():setBackground(colors.gray):setForeground(colors.lightBlue):setText("Submit"):setPosition(4, 8):setSize(16, 1):onClick(submitMapping)
mapFrame:addButton():setBackground(colors.gray):setForeground(colors.lime):setText("Refresh"):setPosition(4, 10):setSize(16, 1):onClick(viewMappingsEdit)
mapFrame:addLabel():setText("Click refresh to view the mapping information."):setPosition(3, 12):setForeground(colors.lightGray)

-- Add content to the "View Mappings" subframe
sub[2]:addLabel():setText("View Item Mappings"):setPosition(2, 2):setForeground(colors.gray)
mappingsList = sub[2]:addTextfield():setSize("parent.w - 1", 14):setPosition(2, 6):setBackground(colors.white):setForeground(colors.black)
sub[2]:addLabel():setText("Click refresh to view the mapping information."):setPosition(2, 4):setForeground(colors.lightGray)
sub[2]:addButton():setBackground(colors.gray):setForeground(colors.lime):setText("Refresh"):setPosition(38, 2):setSize(9, 1):onClick(viewMappings)


-- Add content to the "Map Inventory" subframe
sub[3]:addLabel():setText("Map Inventory Option"):setPosition(2, 2):setForeground(colors.gray)
invList = sub[3]:addTextfield():setSize("parent.w", 14):setPosition(1, 6):setBackground(colors.white):setForeground(colors.black)
sub[3]:addLabel():setText("Click refresh to Map ID's of items in Chest."):setPosition(2, 4):setForeground(colors.lightGray)
sub[3]:addButton():setBackground(colors.gray):setForeground(colors.lime):setText("Refresh"):setPosition(38, 2):setSize(9, 1):onClick(checkInventory)


local function checkStatus()
    while true do
        local isServerOnline = sharedAPI.CommunicationAPI.checkConnection("SERVER_PC")
            mapFrame:addLabel():setText("Server"):setPosition(38, 1):setForeground(colors.lightGray)
            mapFrame:addLabel():setText("Status"):setPosition(44, 1):setForeground(colors.gray)
            sub[2]:addLabel():setText("Server"):setPosition(38, 1):setForeground(colors.lightGray)
            sub[2]:addLabel():setText("Status"):setPosition(44, 1):setForeground(colors.gray)
            sub[3]:addLabel():setText("Server"):setPosition(38, 1):setForeground(colors.lightGray)
            sub[3]:addLabel():setText("Status"):setPosition(44, 1):setForeground(colors.gray)
        if isServerOnline then 
            mapFrame:addLabel():setText("o"):setPosition(50, 1):setForeground(colors.lime)
            sub[2]:addLabel():setText("o"):setPosition(50, 1):setForeground(colors.lime)
            sub[3]:addLabel():setText("o"):setPosition(50, 1):setForeground(colors.lime)
       -- invList:addLine("Server is Online: o")
        else
            mapFrame:addLabel():setText("x"):setPosition(50, 1):setForeground(colors.red)
            sub[2]:addLabel():setText("x"):setPosition(50, 1):setForeground(colors.red)
            sub[3]:addLabel():setText("x"):setPosition(50, 1):setForeground(colors.red)
      --  invList:addLine("Unable to connect to server: x")
        end
        os.sleep(0.5)
    end
end

-- Start the Basalt event loop

loadItemMappings()
networkThread:start(checkStatus)
basalt.autoUpdate()