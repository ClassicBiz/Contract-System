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
    itemMappingFile = "item_mapping.json", -- Path to the item mapping file

    -- Load item mappings from file
    loadMappings = function()
        if fs.exists(sharedAPI.ItemAPI.itemMappingFile) then
            local file = fs.open(sharedAPI.ItemAPI.itemMappingFile, "r")
            if file then
                local data = file.readAll()
                sharedAPI.ItemAPI.items = textutils.unserializeJSON(data) or {}
                file.close()
                return sharedAPI.ItemAPI.items
            end
        end
        return false, "Item mapping file not found."
    end,

    -- Save current item mappings to file
    saveMappings = function()
        local file = fs.open(sharedAPI.ItemAPI.itemMappingFile, "w")
        if file then
            -- Prepare JSON output with proper formatting
            local formattedJSON = "{\n"
            for key, value in pairs(sharedAPI.ItemAPI.items) do
                if type(value) == "table" and value.name then
                    -- Serialize valid item mappings into JSON format
                    formattedJSON = formattedJSON .. '  "' .. key .. '": ' .. textutils.serializeJSON(value) .. ",\n"
                elseif type(value) == "string" then
                    -- Convert string to table format before serializing
                    formattedJSON = formattedJSON .. '  "' .. key .. '": { "name": "' .. value .. '" },\n'
                else
                    -- Log and skip invalid entries
                    print("Skipping invalid entry for key:", key, "value type:", type(value))
                end
            end
    
            -- Remove the last comma and add closing bracket
            if #formattedJSON > 2 then
                formattedJSON = formattedJSON:sub(1, -3) .. "\n"
            end
            formattedJSON = formattedJSON .. "}"
    
            -- Write to file
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

    -- Get item name by ID
    getItemName = function(itemID)
        return sharedAPI.ItemAPI.items[itemID], "Item not found."
    end,

    -- Get item ID by name
    getItemID = function(itemName)
        for id, name in pairs(sharedAPI.ItemAPI.items) do
            if name == itemName then
                return id
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
    THIS_CHANNEL = 100, -- Set this to the appropriate channel for this PC
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
        return response
    end,

    handlePing = function()
        local message = sharedAPI.CommunicationAPI.receiveMessage()
        if message and message.type == "PING" then
            sharedAPI.CommunicationAPI.sendMessage(message.sender, "PONG", {})
        end
    end,
}

return sharedAPI