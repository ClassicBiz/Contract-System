local sharedAPI = require("/API/ContAPI")
local basalt = require("/API/basalt")
local modem = peripheral.find("modem")  -- Find the modem
local serverChannel = 200              -- Server communication channel
local serverRunning = false  -- Track server state


-- Ensure modem is connected
if not modem then
    error("No modem found! Please connect a wired modem.")
end


main = basalt.createFrame():setTheme({FrameBG = colors.lightGray, FrameFG = colors.black})

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
    :onChange(function(self, val)
        openSubFrame(self:getItemIndex())
    end)
    :addItem("Server Commands")
    :addItem("Console Log")
    :addItem("Server Utilities")


-- Add content to the "View Mappings" subframe
sub[2]:addLabel():setText("View Console Log"):setPosition(2, 2)
logList = sub[2]:addTextfield():setSize("parent.w - 2", 12):setPosition(2, 4)
pingList = sub[2]:addTextfield():setSize("parent.w - 2", 2):setPosition(2, 16)
local mainThread = main:addThread()

-- Add content to the "Map Inventory" subframe
sub[3]:addLabel():setText("Server utilites Option"):setPosition(2, 2)



    


modem.open(serverChannel)  -- Open the server's communication channel
logList:addLine("Server is now online and listening on channel:".. serverChannel)
sharedAPI.ContractAPI.loadContracts()
sharedAPI.PlayerAPI.loadPlayers()
sharedAPI.ItemAPI.loadMappings()
local function handleAdminRequest(decodedMessage, replyChannel)
    
    if decodedMessage.type == "NEW_CONTRACT" then
        logList:addLine("Creating new contract:".. textutils.serialize(decodedMessage.payload))
        -- Save the new contract using sharedAPI
        local contractID = decodedMessage.payload.id
        local details = decodedMessage.payload
        logList:addLine("Contract ID:".. contractID)
        local success, errorMsg = sharedAPI.ContractAPI.createContract(contractID, details)
        
        -- Respond with the result
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACT_CREATED",
            payload = { status = success and "success" or "error", message = errorMsg }
        }
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT_CREATED", response.payload)
        
    elseif decodedMessage.type == "UPDATE_CONTRACT" then
        logList:addLine("Updating contract:".. textutils.serialize(decodedMessage.payload))
        local contractID = decodedMessage.payload.id
        local newDetails = decodedMessage.payload
        logList:addLine("Contract ID:".. contractID.. textutils.serialize(newDetails))
        local success, errorMsg = sharedAPI.ContractAPI.updateContract(contractID, newDetails)
        if not success then
            logList:addLine("Error updating contract")
        else
            logList:addLine("updating contract success")
        end
        
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACT_UPDATED",
            payload = { status = success and "success" or "error", message = errorMsg }
        }
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT_UPDATED", response.payload)
        
    elseif decodedMessage.type == "DELETE_CONTRACT" then
        logList:addLine("Deleting contract:".. textutils.serialize(decodedMessage.payload))
        local contractID = decodedMessage.payload.id
        local success, errorMsg = sharedAPI.ContractAPI.deleteContract(contractID)
        
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACT_DELETED",
            payload = { status = success and "success" or "error", message = errorMsg }
        }
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT_DELETED", response.payload)
        
    elseif decodedMessage.type == "FETCH_CONTRACTS" then
        logList:addLine("Fetching all contracts...")
        local contracts = sharedAPI.ContractAPI.getAllContracts()
        
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACT_LIST",
            payload = contracts
        }
        logList:addLine(textutils.serialize(response))
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT_LIST", response.payload)

    elseif decodedMessage.type == "FETCH_CONTRACT" then
        logList:addLine("Fetching [".. decodedMessage.payload.id .. "] contract...")
        local contractID = decodedMessage.payload.id
        local contract = sharedAPI.ContractAPI.getContract(contractID)
        
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACT",
            payload = contract
        }
        logList:addLine(textutils.serialize(response))
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT", response.payload)
        
      -- New: Handle Contractor ID Management
    elseif decodedMessage.type == "REGISTER_CONTRACTOR" then
        logList:addLine("Registering new contractor ID:".. textutils.serialize(decodedMessage.payload))
        local contractorID = decodedMessage.payload.id
        local passcode = decodedMessage.payload.passcode
        local data = decodedMessage.payload.data or {}
        local success, errorMsg = sharedAPI.PlayerAPI.registerContractor(contractorID, passcode, data)
        
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACTOR_REGISTERED",
            payload = { status = success and "success" or "error", message = errorMsg }
        }
        logList:addLine("Sending response:".. textutils.serialize(response))
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACTOR_REGISTERED", response.payload)
        
    elseif decodedMessage.type == "VERIFY_CONTRACTOR" then
        logList:addLine("Verifying contractor ID:".. decodedMessage.payload.id)
        local contractorID = decodedMessage.payload.id
        local passcode = decodedMessage.payload.passcode
        local username = decodedMessage.payload.username
        local contractorData = sharedAPI.PlayerAPI.verifyContractor(contractorID, passcode, username)
        
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACTOR_VERIFIED",
            payload = { 
                status = "success" or "error", 
                message = "Verification successful" or "Verification Failed",
                data = contractorData or nil
            }
        }
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACTOR_VERIFIED", response.payload)
        
    elseif decodedMessage.type == "FETCH_CONTRACTOR" then
        logList:addLine("Fetching contractor ID:".. textutils.serialise(decodedMessage))
        local contractorID = decodedMessage.payload.id
        local contractorData, errorMsg = sharedAPI.PlayerAPI.fetchContractor(contractorID)
        
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACTOR",
            payload = contractorData or { status = "error", message = errorMsg }
        }
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACTOR", response.payload)
    elseif decodedMessage.type == "FETCH_CONTRACTORS" then
        logList:addLine("Fetching all contractor ID's...")
        local contractorIds = sharedAPI.PlayerAPI.getAllContractorIDs()
        
        local response = {
            sender = "SERVER_PC",
            type = "ID_LIST",
            payload = contractorIds
        }
        logList:addLine(textutils.serialize(response))
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "ID_LIST", response.payload)
        
    elseif decodedMessage.type == "DELETE_CONTRACTOR" then
        logList:addLine("Deleting contractor ID: " .. tostring(decodedMessage.payload.id))
        local contractorID = decodedMessage.payload.id
    
        if not sharedAPI.PlayerAPI.players[contractorID] then
            logList:addLine("Failed to delete contractor ID: " .. tostring(contractorID) .. " (does not exist)")
            local response = {
                sender = "SERVER_PC",
                type = "CONTRACTOR_DELETED",
                payload = { status = "error", message = "Contractor ID does not exist." }
            }
            sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACTOR_DELETED", response.payload)
            return
        end
        sharedAPI.PlayerAPI.players[contractorID] = nil
        sharedAPI.PlayerAPI.savePlayers()
        logList:addLine("Successfully deleted contractor ID: " .. tostring(contractorID))
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACTOR_DELETED",
            payload = { status = "success" }
        }
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACTOR_DELETED", response.payload)

    elseif decodedMessage.type == "RESET_PASSCODE" then
        logList:addLine("Resetting passcode for contractor ID: " .. tostring(decodedMessage.payload.id))

        local contractorID = decodedMessage.payload.id
        local username = decodedMessage.payload.username
        local newPasscode = decodedMessage.payload.newPasscode
        local contractorData = sharedAPI.PlayerAPI.players[contractorID]
        logList:addLine(tostring(contractorID))
        if not contractorData then
            logList:addLine("Failed to reset passcode: Contractor ID does not exist.")
            local response = {
                sender = "SERVER_PC",
                type = "PASSCODE_RESET",
                payload = { status = "error", message = "Contractor ID does not exist." }
            }
            sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "PASSCODE_RESET", response.payload)
            return
        end
        if contractorData.data.username ~= username then
            logList:addLine("Failed to reset passcode: Username mismatch.")
            local response = {
                sender = "SERVER_PC",
                type = "PASSCODE_RESET",
                payload = { status = "error", message = "Username does not match Contractor ID." }
            }
            sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "PASSCODE_RESET", response.payload)
            return
        end
    
        -- Update passcode
        contractorData.passcode = newPasscode
        sharedAPI.PlayerAPI.savePlayers()
    
        logList:addLine("Passcode reset successfully for Contractor ID: " .. tostring(contractorID))
        local response = {
            sender = "SERVER_PC",
            type = "PASSCODE_RESET",
            payload = { status = "success" }
        }
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "PASSCODE_RESET", response.payload)

    elseif decodedMessage.type == "FETCH_MAPPINGS" then
        logList:addLine("Admin requesting Item_mappings file...")
        local mapList = sharedAPI.ItemAPI.getAllItems()
        logList:addLine(textutils.serializeJSON(mapList))
        local items = textutils.serializeJSON(mapList)
        local response = {
            sender = "SERVER_PC",
            type = "MAPPING_LIST",
            payload = items,
        }
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "MAPPING_LIST", response.payload)

    elseif decodedMessage.type == "UPDATE_MAPPING" then
        logList:addLine("Updating MAPPING:".. decodedMessage.payload)
        local receivedMapping = decodedMessage.payload
        local receivedItems = textutils.unserializeJSON(receivedMapping) or {}

        for itemID, itemName in pairs(receivedItems) do
            -- If the item is not already in the server's local mapping, add it
            if not sharedAPI.ItemAPI.items[itemID] then
                sharedAPI.ItemAPI.items[itemID] = itemName
            end
        end
        local bool, msg = sharedAPI.ItemAPI.saveMappings()
        local response = {
            sender = "SERVER_PC",
            type = "UPDATE_MAPPING",
            payload = { status = bool and "success" or "error", message = msg }
        }
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "UPDATE_MAPPING", response.payload)
    else
        logList:addLine("Unknown Admin request type:".. decodedMessage.type)
    end
end

local function handleClientRequest(decodedMessage, replyChannel)
    sharedAPI.ContractAPI.loadContracts()
    sharedAPI.PlayerAPI.loadPlayers()
    sharedAPI.ItemAPI.loadMappings()
    if decodedMessage.type == "GET_CONTRACTS" then
        logList:addLine("Client requesting available contracts...")
        local contracts = sharedAPI.ContractAPI.getAllContracts()
        
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACT_LIST",
            payload = contracts
        }
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT_LIST", response.payload)

    elseif decodedMessage.type == "FETCH_MAPPINGS" then
            logList:addLine("Client requesting Item_mappings file...")
            local mapList, msg = sharedAPI.ItemAPI.getAllItems()
            logList:addLine(textutils.serializeJSON(mapList))
            local items = textutils.serializeJSON(mapList)
            local response = {
                sender = "SERVER_PC",
                type = "MAPPING_LIST",
                payload = items,
            }
            logList:addLine(response.items)
            sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "MAPPING_LIST", response.payload)
        
    elseif decodedMessage.type == "ACCEPT_CONTRACT" then
        logList:addLine("Client accepting contract:".. decodedMessage.payload.contractID)
        local contractID = tonumber(decodedMessage.payload.contractID)
        local contractorID = tonumber(decodedMessage.payload.contractorID)
        local contractor = sharedAPI.PlayerAPI.players[contractorID]
        if not contractor then
            logList:addLine("Error: Contractor does not exist.")

            local response = {
                sender = "SERVER_PC",
                type = "CONTRACT_ACCEPTED",
                payload = { status = "error", message = "Contractor does not exist." }
            }
            sharedAPI.CommunicationAPI.sendMessage(response.sender, "CONTRACT_ACCEPTED", response.payload)
            return
        end
        if contractor.data.contract then
            logList:addLine("Error: Contractor already has an active contract.")
            local response = {
                sender = "SERVER_PC",
                type = "CONTRACT_ACCEPTED",
                payload = { status = "error", message = "Contractor already has an active contract." }
            }
            sharedAPI.CommunicationAPI.sendMessage(response.sender, "CONTRACT_ACCEPTED", response.payload)
            return
        end
        local success, errorMsg = sharedAPI.ContractAPI.acceptContract(contractID)
        if not success then
            logList:addLine("Error: " .. errorMsg)
            local response = {
                sender = "SERVER_PC",
                type = "CONTRACT_ACCEPTED",
                payload = { status = "error", message = errorMsg }
            }
            sharedAPI.CommunicationAPI.sendMessage(response.sender, "CONTRACT_ACCEPTED", response.payload)
            return
        end
        contractor.data.contract = contractID
        sharedAPI.PlayerAPI.savePlayers()
        local success, errorMsg = sharedAPI.ContractAPI.acceptContract(contractID)

        logList:addLine("Contract " .. contractID .. " assigned to contractor " .. contractorID)
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACT_ACCEPTED",
            payload = { status = "success", message = "Contract accepted and assigned." }
        }
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT_ACCEPTED", response.payload)
        
    elseif decodedMessage.type == "COMPLETE_CONTRACT" then
        logList:addLine(tostring(decodedMessage.payload.contractorID).. " completing contract:".. tostring(decodedMessage.payload.id))
        local contractID = tonumber(decodedMessage.payload.id)
        local contractorID = tonumber(decodedMessage.payload.contractorID)
        local success, errorMsg = sharedAPI.ContractAPI.completeContract(contractID, contractorID)
        logList:addLine(tostring(success)..tostring(errorMsg))
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACT_COMPLETED",
            payload = { status = success and "success" or "error", message = errorMsg }
        }
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT_LIST", response.payload)

    elseif decodedMessage.type == "UPDATE_CONTRACT" then
        logList:addLine("Updating contract:".. textutils.serialize(decodedMessage.payload))
        local contractID = decodedMessage.payload.id
        local newDetails = decodedMessage.payload
        logList:addLine("Contract ID:".. contractID.. textutils.serialize(newDetails))
        local success, errorMsg = sharedAPI.ContractAPI.updateContract(contractID, newDetails)
        if not success then
            logList:addLine("Error updating contract")
        else
            logList:addLine("updating contract success")
        end
        
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACT_UPDATED",
            payload = { status = success and "success" or "error", message = errorMsg }
        }
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT_UPDATED", response.payload)

    elseif decodedMessage.type == "FETCH_CONTRACTOR" then
        logList:addLine("Fetching contractor ID:".. textutils.serialise(decodedMessage.payload.id))
        local contractorID = tonumber(decodedMessage.payload.id)
        local contractorData, errorMsg = sharedAPI.PlayerAPI.fetchContractor(contractorID)
        logList:addLine(textutils.serialize(contractorData) .."|" .. errorMsg)
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACTOR",
            payload = contractorData or { status = "error", message = errorMsg }
        }

        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT_LIST", response.payload)

    elseif decodedMessage.type == "VERIFY_CONTRACTOR" then
        logList:addLine("Verifying contractor ID:".. decodedMessage.payload.id)
        local rContractorID = tonumber(decodedMessage.payload.id)
        local rPasscode = tonumber(decodedMessage.payload.passcode)
        if decodedMessage.payload.username ~= nil then
            rUsername = decodedMessage.payload.username
        end
        local contractor = sharedAPI.PlayerAPI.players[rContractorID]
        if contractor ~= nil then
            id = tostring(contractor)
            pass = tonumber(contractor.passcode)
            if decodedMessage.payload.username ~= nil then
                user = tostring(contractor.data.username)
            end
        else
            logList:addLine("Failed to verify Contractor ID")
             return
        end
        if contractor then
            if decodedMessage.payload.username ~= nil then
                logList:addLine("|"..rUsername.."|"..rPasscode.."|"..rContractorID)
                logList:addLine("|"..user.."|"..pass.."|"..id)
            else
                logList:addLine("|"..rPasscode.."|"..rContractorID)
                logList:addLine("|"..pass.."|"..id)     
            end
        else
            return
        end
        if decodedMessage.payload.username ~= nil then
            if user ~= rUsername then
                logList:addLine("Failed login: Username mismatch.")
                local response = {
                    sender = "SERVER_PC",
                    type = "CONTRACTOR_VERIFIED",
                    payload = { status = "error", message = "Username does not match Contractor ID." }
                }
                sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT_LIST", response.payload)
                return
            end
        end
        if pass ~= rPasscode then
            logList:addLine("Failed login: passcode mismatch.")
            local response = {
                sender = "SERVER_PC",
                type = "CONTRACTOR_VERIFIED",
                payload = { status = "error", message = "passcode does not match Contractor ID." }
            }
            sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT_LIST", response.payload)
            return
        end
        local contractorData, errorMsg = sharedAPI.PlayerAPI.verifyContractor(rContractorID, rPasscode, rUsername)
        
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACTOR_VERIFIED",
            payload = { 
                status = "success" or errorMsg, 
                message = "Verification successful" or "Verification Failed",
                data = contractorData,
            }
        }
        logList:addLine(response.payload.status)
        logList:addLine(tostring(response.payload.data).. "|" ..tostring(errorMsg))
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT_LIST", response.payload)
    
    elseif decodedMessage.type == "FETCH_ACTIVE_CONTRACTS" then
        logList:addLine("Fetching all contracts...")
        local contracts, errorMsg = sharedAPI.ContractAPI.getActiveContracts()
        
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACT_LIST",
            payload = contracts,
        }
        logList:addLine("Active Contracts Response: " .. textutils.serialize(response))
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT_LIST", response.payload)

    elseif decodedMessage.type == "FETCH_CONTRACT" then
        if decodedMessage.payload.id ~= nil then
            logList:addLine("Fetching [".. decodedMessage.payload.id .. "] contract...")
            local contractID = tonumber(decodedMessage.payload.id)
            local contract, errorMsg = sharedAPI.ContractAPI.getContract(contractID)
        
        local response = {
            sender = "SERVER_PC",
            type = "CONTRACT",
            payload = contract,
        }
        logList:addLine(textutils.serialize(response).. "|".. errorMsg)
        sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "CONTRACT", response.payload)
        else
            return
        end
    elseif decodedMessage.type == "RESET_CONTRACT" then
            local contractorId = decodedMessage.payload.contractorId
            local contractId = decodedMessage.payload.contractId
        
            -- Fetch contractor data
            local contractor = sharedAPI.PlayerAPI.fetchContractor(contractorId)
            if not contractor then
                local response = {
                    sender = "SERVER_PC",
                    type = "RESET_CONTRACT",
                    payload = {
                        status = "error",
                        message = "contractor not found"
                    }
                }
                sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "RESET_CONTRACT", response.payload)
                return
            end
        
            -- Remove the contract from the contractor's data
            contractor.data.contract = nil
            sharedAPI.PlayerAPI.savePlayers()
        
            -- Reset the contract status
            local contract = sharedAPI.ContractAPI.getContract(contractId)
            if contract then
                sharedAPI.ContractAPI.resetContract(contractId)
                local response = {
                    sender = "SERVER_PC",
                    type = "RESET_CONTRACT",
                    payload = {
                        status = "success",
                        message = "Contract Reset Success"
                    }
                }
                sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "RESET_CONTRACT", response.payload)
                return
            else
                local payload = {
                        status = "failed",
                        message = "Contract Reset Failed, Contract Not Found"
                    }
                sharedAPI.CommunicationAPI.sendMessage(decodedMessage.sender, "RESET_CONTRACT", payload)
                return
            end
        
    else
        logList:addLine("Unknown Client request type:".. decodedMessage.type)
    end
end

local function mainFunct()
    while true do
     -- Wait for a message
        local event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        
        if channel == serverChannel then
         --   logList:addLine(tostring(message))
            -- local serializedMessage = textutils.serialize(message)
            local decryptedMessage = sharedAPI.ServerAPI.xorEncrypt(message, sharedAPI.ServerAPI.key)
            local decodedMessage = textutils.unserialize(decryptedMessage)
            if decodedMessage == nil then
                logList:addLine("Invalid or corrupted message received.")
             --   logList:addLine(decodedMessage)
            else
                local sender = decodedMessage.sender
            --    logList:addLine(tostring(decodedMessage))
                pingList:addLine(tostring(sender).." | ".. tostring(decodedMessage.type))

                if decodedMessage and decodedMessage.sender then
                    if decodedMessage.sender == 100 then
                        decodedMessage.sender = "ADMIN_PC"
                    elseif decodedMessage.sender == 50 then
                        decodedMessage.sender = "CLIENT_PC"
                    end

                    if decodedMessage.type == "PING" then
                    -- Handle PING requests
                        local payload = {}
                            
                    --  logList:addLine(textutils.serialise(response))
                        sharedAPI.CommunicationAPI.sendMessage(sender, "PING", payload)

                    elseif decodedMessage.sender == "ADMIN_PC" then
                        handleAdminRequest(decodedMessage, replyChannel)
                    elseif decodedMessage.sender == "CLIENT_PC" then
                        handleClientRequest(decodedMessage, replyChannel)
                    else
                        logList:addLine("Unknown sender:".. decodedMessage.sender)
                    end
                else
                    logList:addLine("Invalid or corrupted message received.")
                    logList:addLine(decodedMessage)
                end
            end
        end
    end
end

local function startServer()
    if not serverRunning then
        mainThread:start(mainFunct)  -- Start the server thread
        serverRunning = true
        logList:addLine("Server started.")
    else
        logList:addLine("Server is already running.")
    end
end

local function pauseServer()
    if serverRunning then
        mainThread:stop()  -- Kill the server thread to pause
        serverRunning = false
        logList:addLine("Server paused.")
    else
        logList:addLine("Server is not running.")
    end
end

local function restartServer()
    logList:addLine("Restarting server...")
    os.sleep(1)  -- Optional delay for effect
    os.reboot()  -- Restart the entire computer
end

sub[1]:addLabel():setText("Server Commands Option"):setPosition(2, 2)
-- Start Server Button
sub[1]:addButton()
    :setPosition(3, 4)
    :setText("Start Server")
    :setSize(16, 1)
    :onClick(startServer)

-- Pause Server Button
sub[1]:addButton()
    :setPosition(3, 6)
    :setText("Pause Server")
    :setSize(16, 1)
    :onClick(pauseServer)

-- Restart Server Button
sub[1]:addButton()
    :setPosition(3, 8)
    :setText("Restart Server")
    :setSize(16, 1)
    :onClick(restartServer)


basalt.autoUpdate()
