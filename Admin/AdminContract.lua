local basalt = require("/API/basalt")
local sharedAPI = require("/API/ContAPI")
local startingID = 1001
local currentID = startingID
local maxID = 9999
local startingContractorID = 19041000
local currentContractorID = startingContractorID
local maxContractorID = 19049999
local blockList = {}

local function findWirelessModem()
    local peripherals = peripheral.getNames()
    for _, name in ipairs(peripherals) do
        if peripheral.getType(name) == "modem" then
            local modem = peripheral.wrap(name)
            if modem and modem.isWireless() then
                return name 
            end
        end
    end
    return nil 
end

local wirelessModemName = findWirelessModem()
if wirelessModemName then
    print("Wireless modem found: " .. wirelessModemName)

    local modem = peripheral.wrap(wirelessModemName)
    local adminChannel = 100
    local SERVER_PC = 200
    sharedAPI.CommunicationAPI.THIS_PC_ID = "ADMIN_PC"
    modem.open(adminChannel)

    modem.transmit(adminChannel, SERVER_PC, "Test message from ADMIN_PC")
else
    error("No wireless modem found. Please connect one.")
end




-- Function to find the next available ID
local function getNextID(current, direction, takenIDs)
    local step = direction == "right" and 1 or -1
    local nextID = current + step

    while table.find(takenIDs, nextID) do
        nextID = nextID + step
    end

    return math.max(nextID, startingID) -- Ensure ID doesn't go below startingID
end

local mainFrame = basalt.createFrame("mainFrame")
local sub = { 
    mainFrame:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"), 
    mainFrame:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(),
    mainFrame:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(),
}

local function openSubFrame(id)
    if sub[id] ~= nil then
        for _, v in pairs(sub) do
            v:hide()
        end
        sub[id]:show()
    end
end

local menubar = mainFrame:addMenubar():setScrollable()
    :setSize("parent.w")
    :setSelectionColor(colors.gray, colors.orange)
    :setBackground(colors.gray)
    :setForeground(colors.yellow)
    :onChange(function(self, val)
        openSubFrame(self:getItemIndex())
    end)
    :addItem("| Admin Menu |")
    :addItem("| Debug Log |")
    :addItem("| Item Mappings |")
    
    adminFrame = sub[1]:addFrame()
    :setPosition(1, 1)
    :setSize(51, 21)
    :setBackground(colors.white)
    adminFrame:addLabel():setText("Server"):setPosition(44, 2):setForeground(colors.lightGray)
    adminFrame:addLabel():setText("Status"):setPosition(44, 3):setForeground(colors.gray)

    debugFrame = sub[2]:addFrame()
    :setPosition(1, 1)
    :setSize(51, 21)
    :setBackground(colors.white)
    local debugField = debugFrame:addTextfield():setSize("parent.w - 2", 10):setPosition(2, 4)
    local pingField = debugFrame:addTextfield():setSize("parent.w - 2", 2):setPosition(2, 14)

    local mappingFrame = sub[3]:addFrame():setBackground(colors.white)
    :setPosition(1, 1)
    :setSize(51, 21)

mappingFrame:addProgram():setSize("parent.w", "parent.h"):setPosition(1, 1):execute("ItemMapping.lua")
local networkThread = adminFrame:addThread()
local contractFrame = sub[1]:addFrame():hide()
    :setPosition(1, 1)
    :setSize(51, 21)

local idFrame = sub[1]:addFrame():hide()
    :setPosition(1, 1)
    :setSize(51, 21)

local createContractFrame = sub[1]:addFrame():setBackground(colors.white):hide()
    :setPosition(1, 1)
    :setSize(51, 21)
    local validationMessage = createContractFrame:addLabel():setPosition(35, 10):setForeground(colors.red):setText("")

local editContractFrame = sub[1]:addFrame():setBackground(colors.white):hide()
    :setPosition(1, 1)
    :setSize(51, 21)
    local validationEditMessage = editContractFrame:addLabel():setPosition(35, 10):setForeground(colors.red):setText("")

local removeContractFrame = sub[1]:addFrame():setBackground(colors.white):hide()
    :setPosition(1, 1)
    :setSize(51, 21)

local viewContractFrame = sub[1]:addFrame():setBackground(colors.white):hide()
    :setPosition(1, 1)
    :setSize(51, 21)
local viewContractField = viewContractFrame:addTextfield():setSize("parent.w - 2", 12):setPosition(2, 4):setBackground(colors.white):setForeground(colors.black)

local createIDFrame = sub[1]:addFrame():setBackground(colors.white):hide()
    :setPosition(1, 1)
    :setSize(51, 21)

local resetPasscodeFrame = sub[1]:addFrame():setBackground(colors.white):hide()
    :setPosition(1, 1)
    :setSize(51, 21)

local viewIDFrame = sub[1]:addFrame():setBackground(colors.white):hide()
    :setPosition(1, 1)
    :setSize(51, 21)


local function clearInputs(inputFields)
    for _, input in pairs(inputFields) do
        input:setValue("")
    end
end

local function validateBlockInput(input)
    local items = sharedAPI.ItemAPI.loadMappings()
    
    for _, details in pairs(items) do
        if details.name:lower() == input:lower() then
            validationMessage:setText("o"):setForeground(colors.green)
            validationEditMessage:setText("o"):setForeground(colors.green):setPosition(30, 14)
            return true
        end
    end

    validationMessage:setText("x"):setForeground(colors.red)
    validationEditMessage:setText("x"):setForeground(colors.red):setPosition(30, 14)
    return false
end

local function fetchTakenContractIDs()
    sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_CONTRACTS")
    local message = sharedAPI.CommunicationAPI.receiveMessage(1)
    if not message then
        debugField:addLine("Error fetching contracts")
        return {}
    end
        debugField:addLine(tostring(message))

       -- local contracts = textutils.unserialize(message)
       local contracts = message
        id = contracts.payload
    debugField:addLine(tostring(id) .." :: " .. textutils.serialize(contracts))
    local ids = {}
    for _, contract in pairs(id) do
        ids[contract.id] = true
    end
    return ids
end

local function getNextContractID(current, direction, takenIDs, maxID, startingID)
    local step = direction == "right" and 1 or -1
    local newID = current
    repeat
        newID = (newID + step - startingID) % (maxID - startingID + 1) + startingID
        if not takenIDs[newID] then
            return newID
        end
    until newID == current -- Break if we loop back to the starting point
    return current -- No available ID found
end

local function fetchTakenIDs()
    sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_CONTRACTORS")
    local message = sharedAPI.CommunicationAPI.receiveMessage(1)
    if not message then
        debugField:addLine("Error fetching contractor ID")
        return {}
    end
    --    local contractID = textutils.unserialize(message)
        local contractID = message
        ContractorId = contractID.payload
    debugField:addLine(tostring(ContractorId) .." :: " .. textutils.serialize(contractID))
    local ids = {}
    for id, _ in pairs(ContractorId) do
        ids[id] = true
    end
    return ids
end

local function getNextID(current, direction, takenIDs, maxID, startingID)
    local step = direction == "right" and 1 or -1
    local newContractorID = current
    repeat
        newContractorID = (newContractorID + step - startingID) % (maxID - startingID + 1) + startingID
        if not takenIDs[newContractorID] then
            return newContractorID
        end
    until newContractorID == current -- Break if we loop back to the starting point
    return current -- No available ID found
end

local function viewContracts()
    viewContractFrame:addLabel():setText("View All Contracts"):setPosition(2, 2):setForeground(colors.gray)

    -- Fetch all contracts from the server
    sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_CONTRACTS")
    local response = sharedAPI.CommunicationAPI.receiveMessage(1) -- Wait for the response

    if not response then
        debugField:addLine("Failed to retrieve contracts.")
        return
    end

    local contractsData = response

    if not contractsData or type(contractsData.payload) ~= "table" then
        debugField:addLine("Invalid contracts data.")
        return
    end

    local contracts = contractsData.payload
    debugField:addLine("Contracts retrieved successfully.")

    -- Loop through each contract and display its details
    for id, contract in pairs(contracts) do
        viewContractField:addLine(string.format("ID: %s", tostring(contract.id or "N/A")))
        viewContractField:addLine(string.format("Title: %s", tostring(contract.title or "N/A")))
        viewContractField:addLine(string.format("Description: %s", tostring(contract.description or "N/A")))

        -- Display all blocks required for the contract
        if contract.blocks and type(contract.blocks) == "table" then
            viewContractField:addLine("Required Item(s):")
            for _, item in ipairs(contract.blocks) do
                viewContractField:addLine(string.format(" - %s x%s", item.block, item.amount))
            end
        else
            viewContractField:addLine("No items listed.")
        end

        viewContractField:addLine(string.format("Payout: %s", tostring(contract.payout or "N/A")))
        viewContractField:addLine(string.format("Status: %s", tostring(contract.status or "N/A")))
        viewContractField:addLine(string.format("Deadline: %s", tostring(contract.deadline or "N/A")))
        viewContractField:addLine("") -- Add a blank line for spacing
    end
end

local function viewContractorIDs()
    local contractorsList = viewIDFrame:addTextfield():setPosition(2, 4):setSize("parent.w - 2", 12):setBackground(colors.white)
    viewIDFrame:addLabel():setText("View All Contract IDs"):setPosition(2, 2)

    -- Send request to fetch contractor IDs from the server
    debugField:addLine("Fetching contractor IDs from Server PC...")
    contractorsList:addLine("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
    sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_CONTRACTORS")
    local response = sharedAPI.CommunicationAPI.receiveMessage(5) -- Wait for the response
    if not response then
        debugField:addLine("Failed to retrieve contractor IDs.")
        return
    end

    -- Parse and validate the response
    -- local contractorData = textutils.unserialize(response)
    local contractorData = response
    if not contractorData or type(contractorData.payload) ~= "table" then
        debugField:addLine("Invalid contractor data received.")
        return
    end

    local contractors = contractorData.payload
    local data = textutils.serialize(contractors)
    debugField:addLine("Contractor IDs retrieved successfully.")
    debugField:addLine(tostring(data))

    -- Populate the scrollable frame with contractor details
    for id, data in pairs(contractors) do
        contractorsList:addLine(string.format("ID: %s", tostring(id or "N/A"))):setForeground(colors.black)
        contractorsList:addLine(string.format("Username: %s", tostring(data.data.username or "N/A"))):setForeground(colors.black)
        contractorsList:addLine("-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-")
    end
end


local function openContractsMenu()
    contractFrame:setBackground(colors.white)
    contractFrame:addLabel():setText("Server"):setPosition(44, 2):setForeground(colors.lightGray)
    contractFrame:addLabel():setText("Status"):setPosition(44, 3):setForeground(colors.gray)
    contractFrame:addLabel():setText("Contract Menu"):setPosition(2, 2):setForeground(colors.gray)
    createContractFrame:addLabel():setText("Create Contract"):setPosition(2, 2):setForeground(colors.gray)
    local success, message = sharedAPI.ItemAPI.loadMappings()
    if not success then
        debugField:addLine("Error loading item mappings: " .. message)
    else
        debugField:addLine("Item mappings loaded successfully.")
    end
    local takenIDs = fetchTakenContractIDs()
    currentID = getNextContractID(currentID, "right", takenIDs, maxID, startingID)
    createContractFrame:addLabel():setText("Contract ID:"):setPosition(2, 4)
    local idDisplay = createContractFrame:addLabel():setText("< " .. currentID .. " >"):setPosition(18, 4)

    local leftArrow = createContractFrame:addButton():setText("<"):setPosition(18, 4):setSize(2, 1):setBackground(colors.white)
    local rightArrow = createContractFrame:addButton():setText(">"):setPosition(25, 4):setSize(2, 1):setBackground(colors.white)
    createContractFrame:addLabel():setText("Block/Item:"):setPosition(2, 10):setForeground(colors.gray)
    local blockInput = createContractFrame:addInput():setPosition(18, 10):setSize(16, 1):setInputType("text")
    
    createContractFrame:addLabel():setText("Amount:"):setPosition(2, 12):setForeground(colors.gray)
    local amountInput = createContractFrame:addInput():setPosition(18, 12):setSize(16, 1):setInputType("text")
    local blockListDisplay = createContractFrame:addLabel():setText(""):setPosition(35, 4):setForeground(colors.gray)
    -- List to store multiple block-item entries
    local blockList = {}

        -- Function to update the display of added items
        local function updateBlockListDisplay()
            local displayText = "Added Items:\n"
            for _, entry in ipairs(blockList) do
                displayText = displayText .. entry.block .. " x" .. entry.amount .. "\n"
            end
            blockListDisplay:setText(displayText)
        end
    
    leftArrow:onClick(function()
        local takenIDs = fetchTakenContractIDs()
        currentID = getNextContractID(currentID, "left", takenIDs, maxID, startingID)
        idDisplay:setText("< " .. currentID .. " >")
    end)
    rightArrow:onClick(function()
        local takenIDs = fetchTakenContractIDs()
        currentID = getNextContractID(currentID, "right", takenIDs, maxID, startingID)
        idDisplay:setText("< " .. currentID .. " >")
    end)
-- Real-time validation for the block input
    blockInput:onChange(function(self)
        validateBlockInput(self:getValue())
    end)
    local inputs = {
        {label = "Title:", y = 6, inputKey = "title"},
        {label = "Description:", y = 8, inputKey = "description"},
        {label = "Payout:", y = 14, inputKey = "payout"},
        {label = "Deadline(seconds):", y = 16, inputKey = "deadline"}
    }
    local inputFields = {}
    for _, data in ipairs(inputs) do
        createContractFrame:addLabel():setText(data.label):setPosition(2, data.y):setForeground(colors.gray)
        inputFields[data.inputKey] = createContractFrame:addInput():setPosition(18, data.y):setSize(16, 1):setInputType("text")
    end

        -- Add Button for adding multiple block-item pairs
        local addButton = createContractFrame:addButton():setBackground(colors.gray):setForeground(colors.lightBlue):setText("Add"):setPosition(38, 10):setSize(6, 1)
        addButton:onClick(function()
            local blockValue = blockInput:getValue()
            local amountValue = tonumber(amountInput:getValue())
    
            if not validateBlockInput(blockValue) or not amountValue or amountValue <= 0 then
                debugField:addLine("Error: Invalid block/item or amount.")
                return
            end
            
            table.insert(blockList, {block = blockValue, amount = amountValue})
            updateBlockListDisplay()
            
            -- Clear input fields after adding
            blockInput:setValue("")
            amountInput:setValue("")
        end)

    local submitButton = createContractFrame:addButton():setBackground(colors.gray):setForeground(colors.lightBlue):setText("Submit"):setPosition(18, 18):setSize(12, 1)
    submitButton:onClick(function()
        if #blockList == 0 then
            debugField:addLine("Error: At least one block/item must be added.")
            return
        end
        
        local allFieldsFilled = true
        for _, key in ipairs({"title", "description", "payout", "deadline"}) do
            if inputFields[key]:getValue() == "" then
                allFieldsFilled = false
                break
            end
        end

        if not allFieldsFilled then
            debugField:addLine("Error: All fields must be filled before submitting.")
            return
        end

        local newContract = {
            id = currentID,
            title = inputFields.title:getValue(),
            description = inputFields.description:getValue(),
            blocks = blockList, -- Store multiple block-item pairs
            payout = tonumber(inputFields.payout:getValue()),
            deadline = os.time() + tonumber(inputFields.deadline:getValue()),
            status = "active"
        }

        sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "NEW_CONTRACT", newContract)
        debugField:addLine("Contract created and sent to the server.")

        -- Clear inputs
        blockList = {}
        updateBlockListDisplay()
        clearInputs(inputFields)
        blockInput:setValue("")
        amountInput:setValue("")
        createContractFrame:hide()
        contractFrame:show()
    end)
 -----------------------------------------------------------------------------------------------------------------
    editContractFrame:addLabel():setText("Edit Contract"):setPosition(2, 2):setForeground(colors.gray)
        local editIDField = editContractFrame:addInput():setDefaultText("Contract ID to Edit"):setPosition(16, 3):setSize(19, 1):setInputType("number")
        local editButton = editContractFrame:addButton():setText("Fetch Contract"):setPosition(36, 3):setSize(14, 1)
        local submitEditButton = editContractFrame:addButton():setText("Submit Changes"):setPosition(18, 18):setSize(14, 1):setForeground(colors.yellow):hide()
        local blockListDisplay = editContractFrame:addLabel():setText(""):setPosition(35, 4):setForeground(colors.gray)

        local function clearBlockListDisplay()
            blockList = {} -- Reset the block list
            blockListDisplay:setText("         ") -- Clear the display text
        end
        -- Fetch Contract Button Logic
        editButton:onClick(function()
            contractID = tonumber(editIDField:getValue())
            clearBlockListDisplay()
            if not contractID then
                debugField:addLine("Invalid Contract ID.")
                return
            end

            -- Request contract data from the server
            sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_CONTRACT", {id = contractID})
            contractData = sharedAPI.CommunicationAPI.receiveMessage(1) -- Wait 1 second
        
            if not contractData or not contractData.payload then
                debugField:addLine("Failed to fetch contract data.")
                return
            end
            
            
            -- Function to update the block display
            local function updateBlockListDisplay()
                local displayText = "Current Items:\n"
                for _, entry in ipairs(blockList) do
                    displayText = displayText .. entry.block .. " x" .. entry.amount .. "\n"
                end
                blockListDisplay:setText(displayText)
            end
        
            -- Store contract data
            editContract = contractData.payload
        
            -- Load existing blocks into the block list
            if editContract.blocks then
                for _, blockData in ipairs(editContract.blocks) do
                    table.insert(blockList, {block = blockData.block, amount = blockData.amount})
                end
                updateBlockListDisplay()
            end
                    -- Input Fields for Adding New Blocks
                    editContractFrame:addLabel():setText("Block/Item:"):setPosition(2, 14):setForeground(colors.gray)
                    local blockInput = editContractFrame:addInput():setPosition(14, 14):setSize(16, 1):setInputType("text")
                    blockInput:onChange(function(self)
                        validateBlockInput(self:getValue())
                    end)

                    local function removeBlock(blockToRemove)
                        for i = #blockList, 1, -1 do  -- Iterate backwards to avoid index shift issues
                            if blockList[i].block == blockToRemove then
                                table.remove(blockList, i)
                                blockListDisplay:setText("         ")
                                updateBlockListDisplay()
                                debugField:addLine("Removed: " .. blockToRemove)
                                return
                            end
                        end
                        debugField:addLine("Error: Block not found.")
                    end
        
        editContractFrame:addLabel():setText("Amount:"):setPosition(2, 16):setForeground(colors.gray)
        local amountInput = editContractFrame:addInput():setPosition(14, 16):setSize(16, 1):setInputType("number")
        
        -- Add Button for new block entries
        local addButton = editContractFrame:addButton():setBackground(colors.gray):setForeground(colors.lightBlue):setText("Add"):setPosition(32, 14):setSize(6, 1)
        addButton:onClick(function()
            local blockValue = blockInput:getValue()
            local amountValue = tonumber(amountInput:getValue())
        
            if not validateBlockInput(blockValue) or not amountValue or amountValue <= 0 then
                debugField:addLine("Error: Invalid block/item or amount.")
                return
            end
        
            table.insert(blockList, {block = blockValue, amount = amountValue})
            updateBlockListDisplay()
            blockInput:setValue("") -- Clear inputs
            amountInput:setValue("")
        end)
        local removeButton = editContractFrame:addButton()
            :setBackground(colors.gray)
            :setForeground(colors.red)
            :setText("Remove")
            :setPosition(32, 16)  -- Placed below the "Add" button
            :setSize(6, 1)

            removeButton:onClick(function()
                local blockValue = blockInput:getValue()
    
                if blockValue == "" then
                    debugField:addLine("Error: Enter a block to remove.")
                    return
                end
                removeBlock(blockValue)
                blockInput:setValue("")  -- Clear input after removal
            end)
        
            -- Display existing contract values
            local editInputs = {
                {title = "New Title:", default = editContract.title, y = 6, key = "title"},
                {title = "New Desc:", default = editContract.description, y = 8, key = "description"},
                {title = "New Pay:", default = tostring(editContract.payout), y = 10, key = "payout"},
                {title = "New DL:", default = tostring(editContract.deadline), y = 12, key = "deadline"}
            }
        
            inputEditFields = {}
        
            for _, data in ipairs(editInputs) do
                editContractFrame:addLabel():setText(data.title):setPosition(2, data.y):setForeground(colors.gray)
                inputEditFields[data.key] = editContractFrame:addInput():setDefaultText(data.default):setPosition(14, data.y):setSize(16, 1):setInputType("text")
            end
        
            submitEditButton:show()
        end)

    
        
        -- Submit Button Logic
        submitEditButton:onClick(function()
            if not contractID then
                debugField:addLine("No contract selected for editing.")
                return
            end
        
            -- Create updated contract while keeping previous values
            local updatedContract = {
                id = contractID,
                status = editContract.status,
                title = inputEditFields.title:getValue() ~= "" and inputEditFields.title:getValue() or editContract.title,
                description = inputEditFields.description:getValue() ~= "" and inputEditFields.description:getValue() or editContract.description,
                payout = tonumber(inputEditFields.payout:getValue()) or editContract.payout,
                deadline = tonumber(inputEditFields.deadline:getValue()) or editContract.deadline,
                blocks = blockList
            }
        
            -- Send updated contract to the server
            sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "UPDATE_CONTRACT", updatedContract)
            debugField:addLine("Contract updated on the server: " .. textutils.serialize(updatedContract))
            debugField:addLine("Blocks to submit: " .. textutils.serialize(blocks))
        
            -- Clear fields and close frame
            clearInputs(inputEditFields)
            clearBlockListDisplay()
            editContractFrame:hide()
            contractFrame:show()
        end)
        
 -----------------------------------------------------------------------------------------------------------------
    removeContractFrame:addLabel():setText("Remove A Contract"):setPosition(2, 2):setForeground(colors.gray)
    removeContractFrame:addLabel():setText("Contract ID to Remove:"):setPosition(2, 4)
    
    local removeIDField = removeContractFrame:addInput():setPosition(25, 4):setSize(16, 1):setInputType("number"):setDefaultText("  Contract ID")
    local validationMessage = removeContractFrame:addLabel():setPosition(6, 7):setForeground(colors.red):setText("")
    local removeButton = removeContractFrame:addButton():setText("Remove Contract"):setPosition(20, 18):setSize(17, 1):setForeground(colors.orange)

    removeButton:onClick(function()
        -- Fetch the current list of taken IDs
        local takenIDs = fetchTakenContractIDs()
        local contractID = tonumber(removeIDField:getValue())
    
        -- Validate the entered ID
        if not contractID then
            validationMessage:setText("Invalid input. Enter a valid number.")
            return
        end
        if not takenIDs[contractID] then
            validationMessage:setText("Error: Contract ID not found.")
            return
        end
    
        -- Send the delete message
        sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "DELETE_CONTRACT", {id = contractID})
        debugField:addLine("Remove request sent to the server.")
    
        -- Clear the input field and reset
        removeIDField:setValue("")
        validationMessage:setText("")
        removeContractFrame:hide()
        contractFrame:show()
    end)

    local backButton = createContractFrame:addButton():setText("Back"):setPosition(5, 18):setSize(10, 1):setBackground(colors.gray):setForeground(colors.red)
    backButton:onClick(function()
        createContractFrame:hide()
        contractFrame:show()
    end)
    local backEditButton = editContractFrame:addButton():setText("Back"):setPosition(5, 18):setSize(10, 1):setBackground(colors.gray):setForeground(colors.red)
    backEditButton:onClick(function()
        editContractFrame:hide()
        editIDField:setValue("")
        contractFrame:show()
    end)
    local backRemoveButton = removeContractFrame:addButton():setText("Back"):setPosition(5, 18):setSize(10, 1):setBackground(colors.gray):setForeground(colors.red)
    backRemoveButton:onClick(function()
        removeContractFrame:hide()
        contractFrame:show()
    end)
    local backViewButton = viewContractFrame:addButton():setText("Back"):setPosition(5, 18):setSize(10, 1):setBackground(colors.gray):setForeground(colors.red)
    backViewButton:onClick(function()
        viewContractFrame:hide()
        viewContractField:clear()
        contractFrame:show()
    end)

    local buttons = {
        {text = "Create Contract", y = 4, bColor = colors.gray, fColor = colors.lime, action = function()
            contractFrame:hide()
            createContractFrame:show()
        end},
        {text = "Edit Contract", y = 6, bColor = colors.gray, fColor = colors.yellow, action = function()
            contractFrame:hide()
            editContractFrame:show()
        end},
        {text = "Remove Contract", y = 8, bColor = colors.gray, fColor = colors.orange, action = function()
            contractFrame:hide()
            removeContractFrame:show()
        end},
        {text = "View Contracts", y = 10, bColor = colors.gray, fColor = colors.lightBlue, action = function()
            contractFrame:hide()
            viewContractFrame:show()
            viewContracts()
        end},
        {text = "Back", y = 12, bColor = colors.gray, fColor = colors.red, action = function()
            contractFrame:hide()
            adminFrame:show()
        end}
    }

    for _, button in ipairs(buttons) do
        contractFrame:addButton():setBackground(button.bColor):setForeground(button.fColor):setText(button.text):setPosition(2, button.y):setSize(18, 1):onClick(button.action)
    end
    contractFrame:show()
    adminFrame:hide()
end

local function checkServerStatus()
    local serverOnline = false 
    local response = sharedAPI.CommunicationAPI.checkConnection("SERVER_PC")
    local ping = response
    if ping then
        local sender = ping.sender
        local type = ping.type
        pingField:addLine(tostring(sender).. " | ".. tostring(type))
        serverOnline = response 
    end
    return serverOnline
end

local function ping()
    while true do
        local isOnline = checkServerStatus()
        if isOnline then
            adminFrame:addLabel():setText("o"):setPosition(50, 3):setForeground(colors.lime)
            contractFrame:addLabel():setText("o"):setPosition(50, 3):setForeground(colors.lime)
            idFrame:addLabel():setText("o"):setPosition(50, 3):setForeground(colors.lime)
        else
            adminFrame:addLabel():setText("x"):setPosition(50, 3):setForeground(colors.red)
            contractFrame:addLabel():setText("x"):setPosition(50, 3):setForeground(colors.red)
            idFrame:addLabel():setText("x"):setPosition(50, 3):setForeground(colors.red)
        end
        os.sleep(5) -- Check every 5 seconds
    end
end

-- Function to open contractor ID menu
local function openContractorIDMenu()
    idFrame:setBackground(colors.white)
    idFrame:addLabel():setText("Server"):setPosition(44, 2):setForeground(colors.lightGray)
    idFrame:addLabel():setText("Status"):setPosition(44, 3):setForeground(colors.gray)
    idFrame:addLabel():setText("Contractor ID Menu"):setPosition(2, 2):setForeground(colors.gray)
 -----------------------------------------------------------------------------------------------------------------
    createIDFrame:addLabel():setText("Create Contractor ID"):setPosition(2, 2):setForeground(colors.gray)
    createIDFrame:addLabel():setText("Contractor ID:"):setPosition(2, 4)
    local takenIDs = fetchTakenIDs()
    currentContractorID = getNextID(currentContractorID, "right", takenIDs, maxContractorID, startingContractorID)
    local idDisplay = createIDFrame:addLabel():setText("< " .. currentContractorID .. " >"):setPosition(18, 4)
    local leftArrow = createIDFrame:addButton():setText("<"):setPosition(18, 4):setSize(2, 1):setBackground(colors.white)
    local rightArrow = createIDFrame:addButton():setText(">"):setPosition(29, 4):setSize(2, 1):setBackground(colors.white)
    leftArrow:onClick(function()
        local takenIDs = fetchTakenIDs()
        currentContractorID = getNextID(currentContractorID, "left", takenIDs, maxContractorID, startingContractorID)
        idDisplay:setText("< " .. currentContractorID .. " >")
    end)
    rightArrow:onClick(function()
        local takenIDs = fetchTakenIDs()
        currentContractorID = getNextID(currentContractorID, "right", takenIDs, maxContractorID, startingContractorID)
        idDisplay:setText("< " .. currentContractorID .. " >")
    end)

    createIDFrame:addLabel():setText("Name:"):setPosition(2, 6)
    local userInput = createIDFrame:addInput():setPosition(18, 6):setSize(16, 1):setInputType("text")

    createIDFrame:addLabel():setText("Passcode:"):setPosition(2, 8)
    local passcodeInput = createIDFrame:addInput():setPosition(18, 8):setSize(16, 1):setInputType("password")

    local createButton = createIDFrame:addButton():setText("Create ID"):setPosition(18, 10):setSize(12, 1):setForeground(colors.lime)

    createButton:onClick(function()
        local contractorID = currentContractorID
        local passcode = passcodeInput:getValue()
        local username = userInput:getValue()

        -- Validation
        if contractorID == "" or passcode == "" then
            debugField:addLine("Contractor ID and Passcode cannot be empty.")
        return
        end

        -- Check if the ID already exists
        sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_CONTRACTOR", {id = contractorID})
        local response = sharedAPI.CommunicationAPI.receiveMessage(2)
		if response then
        	exists = response
			debugField:addLine(tostring(response))
		else
			createIDFrame:addLabel():setText("Error: Unable to reach Server."):setPosition(6,12):setForeground(colors.red)
			debugField:addLine(tostring(response))
			return
		end
    -- Send create request to server
        sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "REGISTER_CONTRACTOR", {id = contractorID, passcode = passcode, data = {username = username},})
        local createResponse = sharedAPI.CommunicationAPI.receiveMessage(1)
        local response = createResponse
        if not response.payload.status == "sucess" then
            debugField:addLine("Failed to create Contractor ID.")
        else
            debugField:addLine("Contractor ID created successfully!")
            userInput:setValue("")
            passcodeInput:setValue("")
            createIDFrame:hide()
            idFrame:show()
        end
    end)
    local backCreateIDButton = createIDFrame:addButton():setBackground(colors.gray):setForeground(colors.red):setText("Back"):setPosition(5, 18):setSize(10, 1)
    backCreateIDButton:onClick(function()
        createIDFrame:hide()
        idFrame:show()
    end)
 ----------------------------------------------------------------------------------------------------------------- 
    resetPasscodeFrame:addLabel():setText("Reset Contracter's ID Passcode"):setPosition(2, 2)
    local backResetButton = resetPasscodeFrame:addButton():setBackground(colors.gray):setForeground(colors.red):setText("Back"):setPosition(5, 18):setSize(10, 1)
    resetPasscodeFrame:addLabel():setText("Contractor ID:"):setPosition(2, 5)
    local contractorIDField = resetPasscodeFrame:addInput():setPosition(18, 5):setSize(15, 1):setDefaultText("Contractor ID"):setInputType("number")

    resetPasscodeFrame:addLabel():setText("Username:"):setPosition(2, 7)
    local usernameField = resetPasscodeFrame:addInput():setPosition(18, 7):setSize(15, 1)

    resetPasscodeFrame:addLabel():setText("New Passcode:"):setPosition(2, 9)
    local newPasscodeField = resetPasscodeFrame:addInput():setPosition(18, 9):setSize(15, 1):setInputType("number")

    local submitResetPasscodeButton = resetPasscodeFrame:addButton():setBackground(colors.gray):setForeground(colors.yellow)
        :setText("Submit"):setPosition(14, 12):setSize(12, 1)

    submitResetPasscodeButton:onClick(function()
        local contractorID = tonumber(contractorIDField:getValue())
        local username = usernameField:getValue()
        local newPasscode = newPasscodeField:getValue()

        if not contractorID or username == "" or newPasscode == "" then
            debugField:addLine("Please fill in all fields correctly.")
            return
        end

        debugField:addLine("Sending passcode reset request for Contractor ID: " .. tostring(contractorID))
        sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "RESET_PASSCODE", {
            id = contractorID,
            username = username,
            newPasscode = newPasscode
        })

        -- Await server response
        local message = sharedAPI.CommunicationAPI.receiveMessage(5)
        if not message then
            debugField:addLine("Error: No response from the server.")
            return
        end

        local response = message
        if response and response.payload.status == "success" then
            debugField:addLine("Passcode reset successfully for Contractor ID: " .. tostring(contractorID))
            resetPasscodeFrame:hide()
            idFrame:show()
        else
            local errorMsg = response and response.payload.message or "Unknown error."
            debugField:addLine("Failed to reset passcode: " .. errorMsg)
        end
    end)
    backResetButton:onClick(function()
        resetPasscodeFrame:hide()
        idFrame:show()
    end)
 -----------------------------------------------------------------------------------------------------------------
    removeIDFrame = sub[1]:addFrame():setBackground(colors.white):hide()
    :setPosition(1, 1)
    :setSize(51, 21)
    removeIDFrame:addLabel():setText("Remove A Contractor's ID"):setPosition(2, 2)
    local inputField = removeIDFrame:addInput():setPosition(5, 6):setSize(40, 1):setBackground(colors.black):setForeground(colors.orange)
    inputField:setDefaultText("Enter Contractor ID to remove")

    local removeIDButton = removeIDFrame:addButton():setBackground(colors.gray):setForeground(colors.orange):setText("Remove ID"):setPosition(5, 8):setSize(15, 1)
    removeIDButton:onClick(function()
        local contractorID = inputField:getValue()
        sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_CONTRACTOR", {id = contractorID})
        local response = sharedAPI.CommunicationAPI.receiveMessage(1)
		if not response then
			removeIDFrame:addLabel():setText("Error:Unable to reach Server"):setForeground(colors.red):setPosition(4,12)
			return
		end
        local contractData = response
        local verifyContractor = tostring(contractData.payload.id)
        debugField:addLine(verifyContractor)
        local contractorID = tonumber(inputField:getValue())
        if not contractorID == verifyContractor then
            debugField:addLine("Invalid Contractor ID")
            return
        end
    
        sharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "DELETE_CONTRACTOR", { id = contractorID })
        local message = sharedAPI.CommunicationAPI.receiveMessage(1)
        if not message then
            debugField:addLine("Error communicating with Server PC.")
            return
        end
    
        local response = message
        if response.payload.status == "success" then
            debugField:addLine("Successfully removed Contractor ID: " .. contractorID)
            removeIDFrame:hide()
            idFrame:show()
        else
            debugField:addLine("Failed to remove Contractor ID: " .. (response.payload.message or "Unknown error"))
        end
    end)
    local backRemoveIDButton = removeIDFrame:addButton():setBackground(colors.gray):setForeground(colors.red):setText("Back"):setPosition(5, 18):setSize(10, 1)
    backRemoveIDButton:onClick(function()
        removeIDFrame:hide()
        idFrame:show()
    end)
 -----------------------------------------------------------------------------------------------------------------

    local backViewIDButton = viewIDFrame:addButton():setBackground(colors.gray):setForeground(colors.red):setText("Back"):setPosition(5, 18):setSize(10, 1)
    backViewIDButton:onClick(function()
        viewIDFrame:hide()
        idFrame:show()
    end)
 -----------------------------------------------------------------------------------------------------------------
    local buttons = {
        {text = "Create ID", y = 4, bColor = colors.gray, fColor = colors.lime, action = function()
            idFrame:hide()
			networkThread:start(ping)
            createIDFrame:show()
        end},
        {text = "Reset Passcode", y = 6, bColor = colors.gray, fColor = colors.yellow, action = function()
            idFrame:hide()
			networkThread:start(ping)
            resetPasscodeFrame:show()
        end},
        {text = "Remove ID", y = 8, bColor = colors.gray, fColor = colors.orange, action = function()
            idFrame:hide()
			networkThread:start(ping)
            removeIDFrame:show()
        end},
        {text = "View IDs", y = 10, bColor = colors.gray, fColor = colors.lightBlue, action = function()
            idFrame:hide()
            viewContractorIDs()
            viewIDFrame:show()
        end},
        {text = "Back", y = 12, bColor = colors.gray, fColor = colors.red, action = function()
            idFrame:hide()
            adminFrame:show()
        end}
    }

    for _, button in ipairs(buttons) do
        idFrame:addButton():setBackground(button.bColor):setForeground(button.fColor):setText(button.text):setPosition(2, button.y):setSize(18, 1):onClick(button.action)
    end

    idFrame:show()
    adminFrame:hide()
end
-- Main Menu GUI
adminFrame:addLabel():setText("Admin PC Main Menu"):setPosition(2, 2):setForeground(colors.gray)
local mainMenuButtons = {
    {text = "Contracts", y = 4, bColor = colors.gray, fColor = colors.orange, action = openContractsMenu},
    {text = "Contractor IDs", y = 6, bColor = colors.gray, fColor = colors.orange, action = openContractorIDMenu},
    {text = "Exit", y = 8, bColor = colors.gray, fColor = colors.red, action = function()
		shell.run("startup")
        basalt.stop()
    end}
}
for _, button in ipairs(mainMenuButtons) do
    adminFrame:addButton():setBackground(button.bColor):setForeground(button.fColor):setText(button.text):setPosition(2, button.y):setSize(18, 1):onClick(button.action)
end
networkThread:start(ping)
basalt.autoUpdate()
