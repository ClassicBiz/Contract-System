local sharedAPI = {}

-- Contract API
sharedAPI.ContractAPI = {
    contracts = {},  -- In-memory contract table
    databaseFile = "/data/contracts.db",  -- File path for storing contract data

    -- Load contracts from file into memory
    loadContracts = function()
        if fs.exists(sharedAPI.ContractAPI.databaseFile) then
            local file = fs.open(sharedAPI.ContractAPI.databaseFile, "r")
            local content = file.readAll()
            file.close()
            sharedAPI.ContractAPI.contracts = textutils.unserialize(content) or {}
        else
            sharedAPI.ContractAPI.contracts = {}
        end
    end,

    -- Save in-memory contracts to file
    saveContracts = function()

        local file = fs.open(sharedAPI.ContractAPI.databaseFile, "w")
        file.write(textutils.serialize(sharedAPI.ContractAPI.contracts))
        file.close()
    end,

    -- Create a new contract
    createContract = function(contractID, details)
        if sharedAPI.ContractAPI.contracts[contractID] then
            return false, "Contract ID already exists."
        end
        sharedAPI.ContractAPI.contracts[contractID] = details
        sharedAPI.ContractAPI.saveContracts()  -- Persist the change
        return true
    end,

    -- Update an existing contract
    updateContract = function(contractID, newDetails)
        if not sharedAPI.ContractAPI.contracts[contractID] then
            return false, "Contract ID does not exist."
        end

        sharedAPI.ContractAPI.contracts[contractID] = newDetails
        sharedAPI.ContractAPI.saveContracts()  -- Persist the change
        return true
    end,

    -- Delete a contract
    deleteContract = function(contractID)
        print("Contract ID:",contractID)
        print(sharedAPI.ContractAPI.contracts[contractID])
        if not sharedAPI.ContractAPI.contracts[contractID] then
            print("Contract ID does not exist")
            return false
        end
        sharedAPI.ContractAPI.contracts[contractID] = nil
        sharedAPI.ContractAPI.saveContracts()  -- Persist the change
        return true
    end,

    -- Get all contracts
    getAllContracts = function()
        return sharedAPI.ContractAPI.contracts
    end,

    getContract = function(contractID)
        if sharedAPI.ContractAPI.contracts[contractID] then
            return sharedAPI.ContractAPI.contracts[contractID]
        else
            return nil, "Contract not found."
        end
    end,

    -- Assign a contractor to a contract
    assignContractorToContract = function(contractID, contractorID)
        local contract = sharedAPI.ContractAPI.contracts[contractID]
        if not contract then
            return false, "Contract ID does not exist."
        end
    
        if not sharedAPI.PlayerAPI.players[contractorID] then
            return false, "Contractor ID does not exist."
        end
    
        contract.contractorID = contractorID
        sharedAPI.ContractAPI.saveContracts()
        return true
    end,
    
        -- Fetch contracts assigned to a specific contractor
    getContractsByContractor = function(contractorID)
        local assignedContracts = {}
        for contractID, contract in pairs(sharedAPI.ContractAPI.contracts) do
            if contract.contractorID == contractorID then
                table.insert(assignedContracts, contract)
            end
        end
        return assignedContracts
    end,

    -- Accept a contract (example logic, may vary)
    acceptContract = function(contractID)
        local contract = sharedAPI.ContractAPI.contracts[contractID]
        if not contract then
            return false, "Contract ID does not exist."
        end

        if contract.status == "accepted" then
            return false, "Contract is already accepted."
        end

        contract.status = "accepted"
        sharedAPI.ContractAPI.saveContracts()  -- Persist the change
        return true
    end,

    -- Complete a contract (example logic, may vary)
    completeContract = function(contractID)
        local contract = sharedAPI.ContractAPI.contracts[contractID]
        if not contract then
            return false, "Contract ID does not exist."
        end

        if contract.status ~= "accepted" then
            return false, "Contract must be accepted before completing."
        end

        contract.status = "completed"
        sharedAPI.ContractAPI.saveContracts()  -- Persist the change
        return true
    end,
}


sharedAPI.PlayerAPI = {
    players = {},  -- In-memory player table
    databaseFile = "/data/players.db",  -- File path for storing player data

    -- Load player data from file
    loadPlayers = function()
        if fs.exists(sharedAPI.PlayerAPI.databaseFile) then
            local file = fs.open(sharedAPI.PlayerAPI.databaseFile, "r")
            local content = file.readAll()
            file.close()
            sharedAPI.PlayerAPI.players = textutils.unserialize(content) or {}
        else
            sharedAPI.PlayerAPI.players = {}
        end
    end,

    -- Save player data to file
    savePlayers = function()
        local file = fs.open(sharedAPI.PlayerAPI.databaseFile, "w")
        file.write(textutils.serialize(sharedAPI.PlayerAPI.players))
        file.close()
    end,

    -- Register a contractor with ID and passcode
    registerContractor = function(contractorID, passcode, data)
        if sharedAPI.PlayerAPI.players[contractorID] then
            return false, "Contractor ID already exists."
        end

        sharedAPI.PlayerAPI.players[contractorID] = {
            passcode = passcode,
            data = data
        }
        sharedAPI.PlayerAPI.savePlayers()
        return true
    end,

    -- Verify a contractor's ID and passcode
    verifyContractor = function(contractorID, passcode)
        local contractor = sharedAPI.PlayerAPI.players[contractorID]
        if contractor and contractor.passcode == passcode then
            return true, contractor.data
        else
            return false, "Invalid ID or passcode."
        end
    end,

    -- Fetch contractor details
    fetchContractor = function(contractorID)
        local contractor = sharedAPI.PlayerAPI.players[contractorID]
        if contractor then
            return contractor
        else
            return nil, "Contractor not found."
        end
    end,

    getAllContractorIDs = function()
        return sharedAPI.PlayerAPI.players
    end
}

-- Item API
sharedAPI.ItemAPI = {
    items = {}, -- Item mapping table
    itemMappingFile = "/data/item_mapping.json", -- Path to the item mapping file

    -- Load item mappings from file
    loadMappings = function()
        if fs.exists(sharedAPI.ItemAPI.itemMappingFile) then
            local file = fs.open(sharedAPI.ItemAPI.itemMappingFile, "r")
            if file then
                local data = file.readAll()
                sharedAPI.ItemAPI.items = textutils.unserializeJSON(data) or {}
                file.close()
                return sharedAPI.ItemAPI.items, "Item mappings loaded successfully."
            end
        end
        return false, "Item mapping file not found."
    end,

    -- Save current item mappings to file
    saveMappings = function()
        local file = fs.open(sharedAPI.ItemAPI.itemMappingFile, "w")
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
            return true, "Item mappings saved successfully."
        end
        return false, "Failed to save item mappings."
    end,

    -- Add or update an item mapping
    addItemMapping = function(itemID, itemName)
        sharedAPI.ItemAPI.items[itemID] = itemName
        return sharedAPI.ItemAPI.saveMappings()
    end,

    -- Remove an item mapping
    removeItemMapping = function(itemID)
        if sharedAPI.ItemAPI.items[itemID] then
            sharedAPI.ItemAPI.items[itemID] = nil
            return sharedAPI.ItemAPI.saveMappings()
        end
        return false, "Item ID not found."
    end,

    getItemCount = function(chestName, itemID)
        if not peripheral.isPresent(chestName) then
            return false, "peripheral not found."
        end
        local chest = peripheral.wrap(chestName)
        local count = 0
        for slot, item in pairs(chest.list()) do
            if item.name == itemID then
                count = count + item.count
            end
        end
        return count
    end,

    -- Get item name by ID
    getItemName = function(itemID)
        return sharedAPI.ItemAPI.items[itemID]
    end,

    -- Get item ID by name
    getItemID = function(itemName)
        local lowerInputName = string.lower(itemName)
        for id, details in pairs(sharedAPI.ItemAPI.items) do
            -- Check if details is a table and has a `name` field
            if type(details) == "table" and details.name then
                if string.lower(details.name) == lowerInputName then
                    return id
                end
            elseif type(details) == "string" then
                -- Fallback for older mappings, if any
                if string.lower(details) == lowerInputName then
                    return id
                end
            end
        end
        return nil, "Item not found."
    end,

    -- Verify if an item ID exists
    isItemIDValid = function(itemID)
        return sharedAPI.ItemAPI.items[itemID] ~= nil
    end,

    -- Verify if an item name exists
    isItemNameValid = function(itemName)
        for _, name in pairs(sharedAPI.ItemAPI.items) do
            if name == itemName then
                return true
            end
        end
        return false
    end,

    -- Get all items as a table for dropdowns or listings
    getAllItems = function()
        return sharedAPI.ItemAPI.items
    end,

    checkDispenserItems = function(dispenserName, requiredItemID, requiredAmount)
        local dispenser = peripheral.wrap(dispenserName)
        if not dispenser then
            return false, "Dispenser not found."
        end
    
        -- Initialize counters
        local itemCount = 0
        local itemMatched = false
    
        -- Iterate over slots in the dispenser
        for slot = 1, dispenser.size() do
            local item = dispenser.getItemDetail(slot)
    
            if item then
                local dispenserItemID = tostring(item.name) -- Ensure item.name is treated as a string
                local requiredID = tostring(requiredItemID) -- Ensure requiredItemID is treated as a string
    
                -- Debugging log to compare the two values
                print(string.format("Slot %d: Checking %s against %s", slot, dispenserItemID, requiredID))
    
                -- Compare the dispenser item ID with the required item ID
                if dispenserItemID == requiredID then
                    itemCount = itemCount + item.count
                    itemMatched = true
                end
            end
        end
    
        -- Check results
        if not itemMatched then
            return false, "Required item not found in dispenser."
        elseif itemCount < tonumber(requiredAmount) then
            return false, string.format(
                "Item count mismatch: Found %d, Required %d.",
                itemCount,
                requiredAmount
            )
        end
    
        return true, "Items verified successfully."
    end,

    payPlayer = function(dispenserName, chestName, payout)
        local chest = peripheral.wrap(chestName)
        local dispenser = peripheral.wrap(dispenserName)
    
        if not chest then
            return false, "Chest not found."
        end
        if not dispenser then
            return false, "Dispenser not found."
        end
    
        -- Ensure payout is valid
        if not payout or payout <= 0 then
            return false, "Invalid payout amount."
        end
    
        -- Filter items with value from the item mapping
        local paymentItems = {}
        for itemID, details in pairs(sharedAPI.ItemAPI.items) do
            if details.value then
                table.insert(paymentItems, { id = itemID, name = details.name, value = details.value })
            end
        end
    
        -- Sort items by value in descending order
        table.sort(paymentItems, function(a, b) return a.value > b.value end)
    
        -- Read chest inventory
        local chestInventory = chest.list()
        if not chestInventory then
            return false, "Failed to read chest inventory."
        end
    
        local remainingAmount = payout
        local usedItems = {} -- Track items used for the payout
    
        for _, item in ipairs(paymentItems) do
            if remainingAmount <= 0 then break end
    
            -- Look for the item in the chest inventory
            for slot, details in pairs(chestInventory) do
                if details.name == item.id then
                    local itemValue = item.value
                    while remainingAmount >= itemValue and details.count > 0 do
                        -- Transfer items to the dispenser
                        chest.pushItems(dispenserName, slot, 1)
                        remainingAmount = remainingAmount - itemValue
                        details.count = details.count - 1 -- Update the local count
                        -- Track used items
                        if usedItems[item.id] then
                            usedItems[item.id] = usedItems[item.id] + 1
                        else
                            usedItems[item.id] = 1
                        end
    
                        if remainingAmount <= 0 then break end
                    end
                end
            end
        end
    
        -- Verify if the payout was fulfilled
        if remainingAmount > 0 then
            return false, "Not enough items to complete the payout."
        end
    
        return true, usedItems
    end,
    
    
    

    retrieveItemsFromDispenser = function(dispenserName, chestName, requiredItemID, requiredAmount)
        local dispenser = peripheral.wrap(dispenserName)
        local chest = peripheral.wrap(chestName)
    
        if not dispenser then
            return false, "Dispenser not found."
        end
    
        if not chest then
            return false, "Chest not found."
        end
    
        local retrievedCount = 0
    
        -- Iterate over slots in the dispenser
        for slot = 1, dispenser.size() do
            local item = dispenser.getItemDetail(slot)
    
            if item then
                local dispenserItemID = tostring(item.name) -- Ensure item.name is treated as a string
                local requiredID = tostring(requiredItemID) -- Ensure requiredItemID is treated as a string
    
                -- Debugging log to compare item IDs
             --   print(string.format("Slot %d: Checking %s against %s", slot, dispenserItemID, requiredID))
    
                if dispenserItemID == requiredID then
                    local toTake = math.min(item.count, requiredAmount - retrievedCount)
    
                    -- Attempt to move items
                    if toTake > 0 then
                        local transferred = dispenser.pushItems(chestName, slot, toTake)
    
                        -- Debug transfer attempt
                     --   print(string.format(
                     --       "Attempting to transfer %d items from slot %d. Transferred: %d",
                     --       toTake, slot, transferred
                     --   ))
    
                        if transferred > 0 then
                            retrievedCount = retrievedCount + transferred
                        end
                    end
    
                    -- Stop when the required amount is retrieved
                    if retrievedCount >= requiredAmount then
                        break
                    end
                end
            end
        end
    
        if retrievedCount < requiredAmount then
            return false, string.format(
                "Failed to retrieve enough items: Retrieved %d, Required %d.",
                retrievedCount,
                requiredAmount
            )
        end
    
        return true, string.format("Successfully retrieved %d items.", retrievedCount)
    end,
}


-- Server API
sharedAPI.ServerAPI = {
    serverOnline = true,  -- Simulate server status
    key = "ContractForLuminance",

    checkServerStatus = function()
        return sharedAPI.ServerAPI.serverOnline
    end,

    sendData = function(data)
        if sharedAPI.ServerAPI.serverOnline then
            print("Data sent to server:", textutils.serialize(data))
            return true
        else
            return false, "Server offline"
        end
    end,
    xorEncrypt = function(data, key)
        local encrypted = {}
        for i = 1, #data do
            local char = string.byte(data, i)
            local keyChar = string.byte(key, (i - 1) % #key + 1)
            table.insert(encrypted, string.char(bit.bxor(char, keyChar)))
        end
        return table.concat(encrypted)
    end,

    receiveData = function()
        if sharedAPI.ServerAPI.serverOnline then
            -- Simulate receiving data
            return {status = "success", data = "example"}
        else
            return nil, "Server offline"
        end
    end,
}

-- Communication API
sharedAPI.CommunicationAPI = {
    adminChannel = 100, -- Replace with the channel number you are using
    SERVER_PC = 200,
    THIS_CHANNEL = 50, -- Set this to the appropriate channel for this PC
    modem = peripheral.find("modem"),

    initialize = function(channel)
        sharedAPI.CommunicationAPI.THIS_CHANNEL = channel
        if not sharedAPI.CommunicationAPI.modem then
            error("No modem found! Please connect a wired modem.")
        end
        sharedAPI.CommunicationAPI.modem.open(channel)
    end,

    sendMessage = function(targetChannel, messageType, payload)
        if not sharedAPI.CommunicationAPI.modem then
            return false, "Modem not found or not initialized"
        end
			if targetChannel == "SERVER_PC" then
				targetChannel = 200
			elseif targetChannel == "ADMIN_PC" then
				targetChannel = 100
			elseif targetChannel == "CLIENT_PC" then
				targetChannel = 50
			end

        local message = {
            sender = sharedAPI.CommunicationAPI.THIS_CHANNEL,
            type = messageType,
            payload = payload
        }
        local serializedMessage = textutils.serialize(message)
        local encryptedMessage = sharedAPI.ServerAPI.xorEncrypt(serializedMessage, sharedAPI.ServerAPI.key)
        sharedAPI.CommunicationAPI.modem.transmit(targetChannel, sharedAPI.CommunicationAPI.THIS_CHANNEL, encryptedMessage)
        return true
    end,

    receiveMessage = function(timeout)
        if not sharedAPI.CommunicationAPI.modem then
            return nil, "Modem not found or not initialized"
        end

        local timer = os.startTimer(timeout or 5)
        while true do
            local event, side, channel, replyChannel, message = os.pullEvent()

            if event == "modem_message" and channel == sharedAPI.CommunicationAPI.THIS_CHANNEL then
                local decryptedMessage = sharedAPI.ServerAPI.xorEncrypt(message, sharedAPI.ServerAPI.key)    
                local unserializedMessage = textutils.unserialize(decryptedMessage)
                return unserializedMessage
            elseif event == "timer" and side == timer then
                return nil, "Timeout"
            end
        end
    end,

    checkConnection = function(targetChannel)
        sharedAPI.CommunicationAPI.sendMessage(targetChannel, "PING", {})
        local response = sharedAPI.CommunicationAPI.receiveMessage(2)
        return response and response.type == "PONG"
    end,

    handlePing = function()
        local message = sharedAPI.CommunicationAPI.receiveMessage()
        if message and message.type == "PING" then
            sharedAPI.CommunicationAPI.sendMessage(message.sender, "PONG", {})
        end
    end,
}

return sharedAPI




