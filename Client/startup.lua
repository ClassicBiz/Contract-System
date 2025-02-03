local basalt = require("/API/basalt")
local SharedAPI = require("API/ContAPI")
local selectedContract = nil
SharedAPI.CommunicationAPI.initialize(50) -- Set Client PC channel to 50
SharedAPI.ItemAPI.loadMappings()
local  itemMapping = SharedAPI.ItemAPI.items

local main = basalt.createFrame():setTheme({FrameBG = colors.white, FrameFG = colors.gray})
local termThread = main:addThread()

local sub = {
    main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"),
    main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(),
    main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(),
    main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(),
}

local function openSubFrame(id)
    if sub[id] ~= nil then
        for _, v in pairs(sub) do
            v:hide()
        end
        sub[id]:show()
    end
end
local menubar = main:addMenubar():setScrollable()
    :setSize("parent.w")
    :setBackground(colors.gray)
    :setForeground(colors.lightBlue)
    :setSelectionColor(colors.gray, colors.blue)
    :onChange(function(self, val)
        openSubFrame(self:getItemIndex())
    end)
    :addItem("Contracts Menu")
    :addItem("Contractor Profile")
    :addItem("C.S.S.")
  --  :addItem("Logs")

    local DebugFrame = sub[4]:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h")
        DebugFrame:addLabel():setText("Contracts Tab"):setPosition(2, 2)
        local debugField = DebugFrame:addTextfield():setPosition(3, 3):setSize(40, 12)
            debugField:addLine(" ")
    local contractsFrame = sub[1]:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h")
        contractsFrame:addLabel():setText("Contracts Menu"):setPosition(2, 2)
        local contractDebug = contractsFrame:addTextfield():setSize(50, 1):setPosition(2,18):setBackground(colors.white):setForeground(colors.red)
            contractDebug:addLine(" ")
        local contractsList = contractsFrame:addList()
            :setPosition(2, 4)
            :setSize("parent.w - 4", "parent.h - 8") -- Adjust size for better fit
            :setBackground(colors.white)
            :setForeground(colors.lightGray)
            :setScrollable(true) -- Enable scrolling for long lists
            :setSelectionColor(colors.white, colors.lightBlue)

    local contractorIDFrame = sub[2]:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h")
        local subframe = {
            contractorIDFrame:addFrame():setPosition(6, 6):setSize(39, 12),
            contractorIDFrame:addFrame():setPosition(6, 6):setSize(39, 12):hide(),
        }
        local function openSubFrame2(id)
            if subframe[id] ~= nil then
                for _, v in pairs(subframe) do
                    v:hide()
                end
                subframe[id]:show()
            end
        end
        local contractmenubar = contractorIDFrame:addMenubar():setScrollable()
            :setSize(40,1)
            :setPosition(4, 5)
            :setBackground(colors.gray)
            :setForeground(colors.lightBlue)
            :setSelectionColor(colors.gray, colors.blue)
            :onChange(function(self, val)
                openSubFrame2(self:getItemIndex())
            end)
            :addItem("Current Contracts")
            :addItem("Completed contracts")
            contractorIDFrame:addLabel():setText("Contractor Profile"):setPosition(2, 2)
            local currentField = subframe[1]:addTextfield():setPosition(1, 1):setSize(38, 13):setBackground(colors.white):setForeground(colors.black)
            local completedField = subframe[2]:addTextfield():setPosition(1, 1):setSize(38, 13):setBackground(colors.white):setForeground(colors.black)

    local completeContractFrame = sub[3]:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h")

    function string.trim(s)
        return (s:gsub("^%s*(.-)%s*$", "%1"))
    end

    local function preventTerminate()
        while true do
            local event, key = os.pullEventRaw()
            if event == "terminate" then
                -- Suppress the terminate event
                os.reboot()
            end
        end
    end
    local function retrieveMappings()
        SharedAPI.ItemAPI.loadMappings()
        local itemMapping = SharedAPI.ItemAPI.items
        SharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_MAPPINGS")
        local serverData = SharedAPI.CommunicationAPI.receiveMessage(3)
    
        if not serverData then
            print("Error: No response from server during FETCH_MAPPINGS")
            return
        end
    
        local serverReply = serverData
        if not serverReply or not serverReply.payload then
            print("Error: Invalid server reply during FETCH_MAPPINGS")
            return
        end
    
        local serverMapping = textutils.unserializeJSON(serverReply.payload) or {}
        for item, details in pairs(serverMapping) do
            if type(details) == "string" then
                if not itemMapping[item] then
                    itemMapping[item] = { name = details }
                end
            elseif type(details) == "table" and details.name then
                if not itemMapping[item] then
                    itemMapping[item] = details
                else
                    for key, value in pairs(details) do
                        if not itemMapping[item][key] then
                            itemMapping[item][key] = value
                        end
                    end
                end
            else
                print("Warning: Skipping invalid mapping for item:", item)
            end
        end
    
        -- Save the updated local item mappings
        SharedAPI.ItemAPI.saveMappings()
    end
    

    local loginFrame = main:addFrame():setPosition(1, 1):setSize("parent.w", "parent.h"):setBackground(colors.white):show()
        termThread:start(preventTerminate)
        loginFrame:addLabel()
            :setText("Contractor Login")
            :setPosition("parent.w / 2 - 8", 2)
            :setForeground(colors.black)

        local contractorIDInput = loginFrame:addInput()
            :setPosition("parent.w / 2 - 10", 5)
            :setSize(20, 1)
            :setDefaultText("Contractor ID")
            :setBackground(colors.gray)
            :setForeground(colors.black)
            :setInputType("number")

        local userInput = loginFrame:addInput()
            :setPosition("parent.w / 2 - 10", 7)
            :setSize(20, 1)
            :setDefaultText("username")
            :setBackground(colors.gray)
            :setForeground(colors.black)

        local passcodeInput = loginFrame:addInput()
            :setPosition("parent.w / 2 - 10", 9)
            :setSize(20, 1)
            :setDefaultText("Passcode")
            :setBackground(colors.gray)
            :setForeground(colors.black)
            :setInputType("password")

        local loginStatus = loginFrame:addLabel()
            :setPosition("parent.w / 2 - 15", 11)
            :setForeground(colors.red):setText("")

        local loginButton = loginFrame:addButton()
            :setText("Login")
            :setPosition("parent.w / 2 - 5", 13)
            :setSize(10, 1)
            :setBackground(colors.green)
            :setForeground(colors.white)
            :onClick(function()
                local contractorID = contractorIDInput:getValue()
                local username = userInput:getValue()
                local passcode = passcodeInput:getValue()

        if contractorID == "" or passcode == "" or username == "" then
            loginStatus:setText("Error: all fields are required.")
            return
        end

        -- Send login details to the server for validation
        SharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_CONTRACTOR", {id = contractorID})
        local response = SharedAPI.CommunicationAPI.receiveMessage(3)
        if response then
            local verify = response
            local debuggin = textutils.serialise(verify.payload)
            if verify.payload.data == nil then
                loginStatus:setText("Error: Invalid credentials.")
                return
            end

            local userID = verify.payload.data.username
            if tonumber(verify.payload.passcode) == tonumber(passcode) and userID == username then
                -- Successful login
                contractorCredentials = {
                    id = contractorID,
                    passcode = passcode,
                }
                loginFrame:hide()
                main:show() -- Show main UI
                retrieveMappings()
                contractsFrame:show()
                contractorIDFrame:show()
                completeContractFrame:show()
                local function contractlist()
                    SharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_ACTIVE_CONTRACTS", {})
                    local response = SharedAPI.CommunicationAPI.receiveMessage(3)
                
                    if not response then
                        contractsList:clear()
                        contractsList:addItem("Error: Failed to retrieve contracts.")
                        return
                    end
                
                    local message = response
                    if not message or type(message.payload) ~= "table" then
                        contractsList:clear()
                        contractsList:addItem("Error: Invalid contract data.")
                        return
                    end
                
                    contracts = message.payload
                    contractsList:clear()
                
                    if not next(contracts) then
                        contractsList:addItem("No contracts available.") -- Inform if no contracts exist
                        return
                    end
                
                    for id, contract in pairs(contracts) do
                        -- Format the list of required items
                        local itemsString = "None"
                        if contract.blocks and type(contract.blocks) == "table" then
                            local itemList = {}
                            for _, item in ipairs(contract.blocks) do
                                table.insert(itemList, string.format("%s x%s", item.block, item.amount))
                            end
                            itemsString = table.concat(itemList, ", ") -- Join all items with commas
                        end
                
                        -- Add contract entry to the list
                        contractsList:addItem(
                            string.format(
                                "ID: %s | Title: %s | Status: %s | Payout: %s | Items: %s | Deadline: %s | Description: %s |",
                                tostring(contract.id or "N/A"),
                                tostring(contract.title or "Untitled"),
                                tostring(contract.status or "Unknown"),
                                tostring(contract.payout or "0"),
                                itemsString, -- Display all required items
                                tostring(contract.deadline or "0"),
                                tostring(contract.description or "N/A")
                            ),
                            nil,
                            nil,
                            {contract = contract} -- Attach the contract data as args
                        )
                    end
                
                    retrieveMappings()
                end
            
                local function showContractPopup(contract)
                    local popupFrame = main:addFrame():show()
                        :setPosition("parent.w / 8", "parent.h / 4")
                        :setSize("parent.w / 1.25", "parent.h / 1.5")
                        :setBackground(colors.gray)
                        :setZIndex(10)
                
                    popupFrame:addLabel()
                        :setText("Contract Details")
                        :setPosition(2, 2)
                        :setForeground(colors.white)
                
                    local contractField = popupFrame:addTextfield()
                        :setPosition(2, 4)
                        :setSize("parent.w, parent.h / 1.25")
                        :setBackground(colors.gray)
                        :setForeground(colors.white)
                
                    -- Format the list of required items
                    local itemsString = "NIL"
                    if contract.blocks == nil then
                        debugField:addLine("Debug: contract.blocks is nil")
                    elseif type(contract.blocks) ~= "table" then
                        debugField:addLine("Debug: contract.blocks is not a table, it is " .. type(contract.blocks))
                    else
                        debugField:addLine("Debug: contract.blocks has " .. tostring(#contract.blocks) .. " items")
                    end
                    if contract.blocks and type(contract.blocks) == "table" then
                        local itemList = {}
                        for _, item in ipairs(contract.blocks) do
                            table.insert(itemList, string.format("%s x%s", item.block, item.amount))
                        end
                        itemsString = table.concat(itemList, ", ") -- Join all items with commas
                    end
                
                    -- Add contract details
                    contractField:addLine("Contract ID: " .. tostring(contract.id))
                    contractField:addLine("Details: " .. tostring(contract.description))
                    contractField:addLine("Items: " .. itemsString) -- Updated to show all items
                    contractField:addLine("Payout: " .. tostring(contract.payout))
                    contractField:addLine("Deadline: " .. tostring(contract.deadline))
                    contractField:addLine("Status: " .. tostring(contract.status))
                
                    -- Cancel button
                    popupFrame:addButton()
                        :setText("Cancel")
                        :setPosition(2, "parent.h - 2")
                        :setSize("parent.w / 2 - 3", 1)
                        :setBackground(colors.red)
                        :setForeground(colors.white)
                        :onClick(function()
                            popupFrame:hide()
                        end)
                
                    -- Accept contract button
                    popupFrame:addButton()
                        :setText("Accept")
                        :setPosition("parent.w / 2 + 1", "parent.h - 2")
                        :setSize("parent.w / 2 - 3", 1)
                        :setBackground(colors.green)
                        :setForeground(colors.white)
                        :onClick(function()
                            local loginPopup = main:addFrame()
                                :setSize(30, 9)
                                :setBackground(colors.lightGray)
                                :setForeground(colors.white)
                                :setPosition(12,6)
                                :show()
                
                            loginPopup:addLabel()
                                :setText("Enter Contractor ID:")
                                :setPosition(2, 2)
                
                            local idInput = loginPopup:addInput()
                                :setPosition(2, 4)
                                :setSize(26, 1)
                                :setBackground(colors.white)
                                :setForeground(colors.black)
								:setInputType("number")
                                :setDefaultText("Login ID")
                
                            local passInput = loginPopup:addInput()
                                :setPosition(2, 6)
                                :setSize(26, 1)
                                :setBackground(colors.white)
                                :setForeground(colors.black)
								:setInputType("password")
                                :setDefaultText("Passcode")
                
                            -- Submit button
                            loginPopup:addButton()
                                :setText("Submit")
                                :setPosition(16, 8)
                                :setSize(12, 1)
                                :setBackground(colors.green)
                                :setForeground(colors.white)
                                :onClick(function()
                                    local enteredID = idInput:getValue()
                                    if enteredID and enteredID ~= "" then
                                        SharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_CONTRACTOR", {id = tostring(enteredID)})
                                        local response = SharedAPI.CommunicationAPI.receiveMessage(3)
                
                                        if not response or not response.payload then
                                            contractDebug:editLine(1, "Error: No response from server!")
                                            return
                                        end
                
                                        local verifyPass = tostring(response.payload.passcode)
                                        local pass = passInput:getValue()
                
                                        debugField:addLine(verifyPass .. " | " .. pass)
                
                                        if verifyPass == pass then
                                            -- Link contract to verified Contractor ID
                                            SharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "ACCEPT_CONTRACT", {
                                                contractorID = enteredID,
                                                contractID = contract.id
                                            })
                                            contractDebug:editLine(1, "Contract accepted by Contractor ID: " .. tostring(enteredID))
                                                :setForeground(colors.green)
                
                                            loginPopup:hide()
                                            popupFrame:hide()
                                            os.sleep(0.5)
                                            contractlist()
                                        else
                                            contractDebug:editLine(1, "Error: Invalid Contractor Pass!")
                                            loginPopup:addLabel()
                                                :setText("Invalid ID! Try again.")
                                                :setPosition(2, 6)
                                                :setForeground(colors.red)
                                        end
                                    else
                                        contractDebug:editLine(1, "Error: No ID entered!")
                                    end
                                end)
                
                            -- Cancel button
                            loginPopup:addButton()
                                :setText("Cancel")
                                :setPosition(2, 8)
                                :setSize(12, 1)
                                :setBackground(colors.red)
                                :setForeground(colors.white)
                                :onClick(function()
                                    loginPopup:hide()
                                end)
                        end)
                end                
                contractlist()
    contractsFrame:addButton()
    :setBackground(colors.lightGray)
    :setText("Refresh Contracts")
    :setSize(18, 1)
    :setForeground(colors.blue)
    :setPosition(35, 2) -- Ensure proper alignment below the list
    :onClick(function()
        contractlist()
    end)
    contractsList:onSelect(function(self, index, value)
        local selectedItem = value
        if selectedItem then
            local itemText = selectedItem.text
            local contractData = {}
            for key, val in string.gmatch(itemText, "([^:|]+): ([^|]+)") do
                contractData[key:trim()] = val:trim()
            end
            
            -- Handle blocks parsing as table
            local blocksData = contractData["Items"]
            local blocksTable = {}
            if blocksData then
                for blockInfo in string.gmatch(blocksData, "(%w+ x%d+)") do
                    local block, amount = string.match(blockInfo, "(%w+) x(%d+)")
                    if block and amount then
                        table.insert(blocksTable, {block = block, amount = tonumber(amount)})
                    end
                end
            end
            
            selectedContract = {
                id = contractData["ID"],
                title = contractData["Title"],
                status = contractData["Status"],
                payout = contractData["Payout"],
                blocks = blocksTable,  -- Store blocks as a table
                amount = contractData["Amount"],
                deadline = contractData["Deadline"],
                description = contractData["Description"],
            }
    
            showContractPopup(selectedContract)
        else
            contractDebug:addLine("Error: No item found at index " .. tostring(index))
        end
    end)
contractsFrame:addButton()
:setText("Logout")
:setSize(6,1)
:setForeground(colors.red)
:setPosition(46, 18)
:onClick(function()
    basalt.stop()
    shell.run("startup.lua")
end)



local function refreshContractList()
    SharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_CONTRACTOR", {id = contractorCredentials.id})
    local lMessage = SharedAPI.CommunicationAPI.receiveMessage(5)
    lResponse = lMessage
    if lResponse ~= nil then
        local lContractorID = tostring(lResponse.payload.id)
        lUsername = tostring(lResponse.payload.data.username)
        local contractor = lContractorID

        if not contractor then
            debugField:addLine("Error: Contractor data not found.")
            return
        end
    else
        return
    end
    local active = tostring(lResponse.payload.data.contract)
        debugField:addLine(active)
        contractorIDFrame:addLabel():setText("Contractor : "..contractorCredentials.id):setPosition(29,3):setForeground(colors.gray)
        contractorIDFrame:addLabel():setText("Welcome :" ..lUsername):setPosition(29,2):setForeground(colors.gray)
    if active ~= nil then
        local currentContractID = lResponse.payload.data.contract
        SharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_CONTRACT", {id = active})
            cMessage = SharedAPI.CommunicationAPI.receiveMessage(5)
            local cResponse = cMessage
        if cResponse.payload ~= nil then
            currentContract = cResponse.payload.id
            if currentContract then
                local itemsString = "unknown"
                if cResponse.payload.blocks and type(cResponse.payload.blocks) == "table" then
                    local itemList = {}
                    for _, item in ipairs(cResponse.payload.blocks) do
                        table.insert(itemList, string.format("%s x%s", item.block, item.amount))
                    end
                    itemsString = table.concat(itemList, ", ") -- Join all items with commas
                end
                currentField:addLine("Current Contract: " .. tostring(cResponse.payload.title or "Untitled"))
                currentField:addLine("  ID: " .. tostring(cResponse.payload.id or "N/A"))
                currentField:addLine("  Description: " .. tostring(cResponse.payload.description or "Untitled"))
                currentField:addLine("  Status: " .. tostring(cResponse.payload.status or "Unknown"))
                currentField:addLine("  Payout: " .. tostring(cResponse.payload.payout or "0"))
                currentField:addLine("  Item: " .. tostring(itemsString or "Unknown"))
                currentField:addLine("  Amount: " .. tostring(cResponse.payload.amount or "0"))
                currentField:addLine("  Deadline: " .. tostring(cResponse.payload.deadline or "N/A"))
            else
                currentField:addLine("No active contract found.")
            end
        else
            currentField:addLine("No active contract.")
        end
    else
        currentField:addLine("No active contract.")
    end
    completedField:addLine("Completed Contracts:")

    local completedContracts = lResponse.payload.data.completedContracts
    if completedContracts ~= nil then
    	if next(completedContracts) then
        	-- Fetch all contracts from the server
        	SharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "GET_CONTRACTS", {})
        	local allContractsResponse = SharedAPI.CommunicationAPI.receiveMessage(3)

        	if allContractsResponse and allContractsResponse.payload then
            	local allContracts = allContractsResponse.payload

            -- Create a lookup table for faster contract matching
            	local contractLookup = {}
            	for id, contract in pairs(allContracts) do -- Use `pairs` to iterate over dictionary-style table
                	contractLookup[tostring(id)] = contract -- Convert key to string for consistent matching
            	end

            -- Loop through completed contracts and check in lookup table
            	for _, contractID in ipairs(completedContracts) do
                	local contract = contractLookup[tostring(contractID)] -- Convert to string for matching

                -- Debugging output
           --     completedField:addLine(string.format("Checking contract ID: %s -> Found: %s", tostring(contractID), tostring(contract)))

                	if contract then
                -- Display matched completed contract details
                	completedField:addLine(
                    	string.format(
                        	"  ID: %s | Title: %s | Payout: %s",
                        	tostring(contract.id or "N/A"),
                        	tostring(contract.title or "Untitled"),
                        	tostring(contract.payout or "0")
                    		)
                		)
                	end
            	end
        	else
            	completedField:addLine("  Error: Unable to fetch contract data.")
        	end
    	else
        	completedField:addLine("  None")
    	end
    else
		return
	end
    local totalPaid = lResponse.payload.data.totalPaid or 0
    contractorIDFrame:addLabel():setText("Total Paid: " .. tonumber(totalPaid)):setPosition(29,4):setForeground(colors.green)
end
refreshContractList()


contractorIDFrame:addButton()
:setText("Refresh")
:setSize(8,1)
:setForeground(colors.blue)
:setBackground(colors.lightGray)
:setPosition(45, 5)
:onClick(function()
    currentField:clear()
    completedField:clear()
    refreshContractList()
end)


        contractorIDFrame:addButton()
            :setText("Logout")
            :setSize(6,1)
            :setForeground(colors.red)
            :setPosition(46, 18)
            :onClick(function()
                basalt.stop()
                shell.run("startup.lua")
            end)
        contractorIDFrame:addButton()
            :setText("Remove Contract")
            :setSize(15, 1)
            :setPosition(18, 18)
            :setForeground(colors.red)
            :onClick(function()
                if currentContract ~= nil then
                    SharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "RESET_CONTRACT", {contractorId = contractorID, contractId = currentContract})
                    currentField:clear()
                    currentContract = nil
                else
                    currentField:addLine("No Active Contract to Remove")
                end    
            end)

    local none = "N/A"
    completeContractFrame:addLabel():setText("Contract Submission System"):setPosition(12, 2):setForeground(colors.black)
    completeContractFrame:addButton()
        :setText("Submit Contract")
        :setPosition(18, 16)
        :setSize(15, 1)
        :onClick(function()
            currentField:clear()
            completedField:clear()
            refreshContractList()
            SharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "VERIFY_CONTRACTOR", {
                id = contractorID,
                passcode = passcode
            })
            local contractorResponse = SharedAPI.CommunicationAPI.receiveMessage(3)
            if contractorResponse ~= nil then
                currentState = contractorResponse
            else
                return
            end
            if not currentState or currentState.payload.status ~= "success" then
                debugField:addLine("Contractor verification failed. Please check your ID and passcode.")
                return
            end
            if currentContract == nil then
                completeContractFrame:addLabel():setForeground(colors.red):setText("No Active Contract Found."):setPosition(14, 5)
                completeContractFrame:addLabel():setText("                                               "):setPosition(16, 4):setForeground(colors.red)
                completeContractFrame:addLabel():setText("                                           "):setPosition(16, 6):setForeground(colors.red)
                local i = 0
                for i = 1, 8 do
                    completeContractFrame:addLabel():setText("                                                  "):setPosition(16, 7 + i):setForeground(colors.red)
                end
                
                return
            else
                -- Clear specific row if contract exists
                completeContractFrame:addLabel():setText("                            "):setPosition(12, 5)
            end
            SharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "FETCH_CONTRACT", { id = currentContract })
            local contractResponse = SharedAPI.CommunicationAPI.receiveMessage(3)
            
            if contractResponse ~= nil then
                local submitContract = contractResponse
                local ContractID = tostring(submitContract.payload.id)
                local status = tostring(submitContract.payload.status)
                local Payout = submitContract.payload.payout
                local dispenser = 28
                local cChest = 50
                local iChest = 51
                if status == "accepted" then
                    -- Initialize UI display
                    completeContractFrame:addLabel():setText("Contract ID: ".. ContractID):setPosition(16, 4)
                    completeContractFrame:addLabel():setText("   Total Payment: $".. tostring(Payout) or "None"):setPosition(13, 6)
            
                    -- Validate contract blocks table
                    if submitContract.payload.blocks == nil or type(submitContract.payload.blocks) ~= "table" then
                        debugField:addLine("Error: Contract does not have a valid blocks table.")
                        return
                    end
            
                    -- Store required blocks & progress tracking
                    local requiredBlocks = submitContract.payload.blocks
                    local contractUpdated = false  -- Track if any updates were made
                    local blocksValue = {} -- New table to correctly store updated block data

                    -- Copy requiredBlocks to blocksValue while keeping reference consistency
                    for i, item in ipairs(requiredBlocks) do
                        blocksValue[i] = {
                            block = item.block,
                            amount = item.amount
                        }
                    end

                    -- Loop through the blocks and update the contract directly
                    for i, item in ipairs(requiredBlocks) do
                        local requiredItem = item.block
                        local requiredAmount = item.amount
                        local requiredItemID = SharedAPI.ItemAPI.getItemID(requiredItem)

                        -- Initialize contract update for each block
                        completeContractFrame:addLabel():setText("Required Item " .. i .. ": ".. tostring(requiredItem) .. " x" .. tostring(requiredAmount)):setPosition(16, 6 + (i + 1))
    
                        -- Check and collect items progressively
                        debugField:addLine("Contract Verified. Checking dispenser items...")

                        local currentInDispenser, message = SharedAPI.ItemAPI.getItemCount("minecraft:dispenser_"..dispenser, requiredItemID)
						if currentInDispenser == false then
							debugField:addLine("Peripherals failed")
							return
						end
                        if currentInDispenser > 0 then
                            -- Determine how much we can take
                            local amountToTake = math.min(currentInDispenser, requiredAmount)

                            -- Retrieve items from the dispenser to the chest
                            local retrieved, retrievalMessage = SharedAPI.ItemAPI.retrieveItemsFromDispenser("minecraft:dispenser_"..dispenser, "minecraft:chest_51", requiredItemID, amountToTake)
                            if retrieved then
                                -- Update the block amount in blocksValue (not adding new entry)
                                blocksValue[i].amount = blocksValue[i].amount - amountToTake
                                debugField:addLine("Retrieved: " .. amountToTake .. " of " .. requiredItem)

                                -- Mark as completed if fully collected
                                if blocksValue[i].amount <= 0 then
                                    debugField:addLine(requiredItem .. " collection complete!")
                                end
                                contractUpdated = true  -- Mark that an update occurred
                            else
                                debugField:addLine("Retrieval failed: " .. retrievalMessage)
                            end
                        else
                            debugField:addLine("Not enough of " .. requiredItem .. " in dispenser.")
                        end
                    end

                    -- If any block progress was updated, send the updated contract back to the server
                    if contractUpdated then
                        local editedContract = {
                            id = tonumber(ContractID),
                            title = submitContract.payload.title,
                            description = submitContract.payload.description,
                            blocks = blocksValue,  -- Now correctly structured
                            status = status,
                            payout = tonumber(submitContract.payload.payout),
                            deadline = tonumber(submitContract.payload.deadline)
                        }
                        for i, item in ipairs(blocksValue) do
                            local requiredItem = item.block
                            local requiredAmount = item.amount
                            local requiredItemID = SharedAPI.ItemAPI.getItemID(requiredItem)
    
                            -- Initialize contract update for each block
                            completeContractFrame:addLabel():setText("                                                                                                 "):setPosition(16, 6 + (i + 1))
                            if requiredAmount > 0 then
                                completeContractFrame:addLabel():setText("Required Item " .. i .. ": ".. tostring(requiredItem) .. " x" .. tostring(requiredAmount)):setPosition(16, 6 + (i + 1))
                            else
                                completeContractFrame:addLabel():setText("                                                                                                 "):setPosition(16, 6 + (i + 1))
                            end
                        end 
                        debugField:addLine("Updating contract progress on Server PC...".. textutils.serialize(editedContract))
                        SharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "UPDATE_CONTRACT", editedContract)
                    end
            
                    -- Check if all blocks are completed
                    local allCompleted = true
                    for _, blockData in ipairs(blocksValue) do
                        if blockData.amount > 0 then
                            allCompleted = false
                            break
                        end
                    end
            
                    if allCompleted == true then
                        -- All items received, proceed with payout
                        local success, msg = SharedAPI.ItemAPI.payPlayer("minecraft:dispenser_"..dispenser, "minecraft:chest_50", Payout)
                        debugField:addLine(tostring(textutils.serialize(msg)))
            
                        if success then
                            debugField:addLine("All items retrieved successfully. Payout complete!")
                            completeContractFrame:addLabel():setPosition(13, 6):setText("Contract Is Completed!"):setForeground(colors.green)
                            SharedAPI.CommunicationAPI.sendMessage("SERVER_PC", "COMPLETE_CONTRACT", { id = ContractID, contractorID = tostring(contractorID) })
                        else
                            debugField:addLine("Payout failed!")
                        end
                    else
                        debugField:addLine("Contract is still in progress. Keep submitting items!")
                    end
                else
                    debugField:addLine("Contract is already completed.")
                end
            else
                return
            end
            
        end)
   
        completeContractFrame:addButton()
        :setText("Logout")
        :setSize(6,1)
        :setForeground(colors.red)
        :setPosition(46, 18)
        :onClick(function()
            basalt.stop()
            shell.run("startup.lua")
        end)
    else
        loginStatus:setText("Error: Invalid credentials.")
    end
else
    loginStatus:setText("Error: Server not responding.")
end
end)

basalt.autoUpdate()