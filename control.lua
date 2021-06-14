-- Based on Ghost Scanner (Copyright (c) 2019 Optera)
-- See LICENSE in the project directory for license information.
-- constant prototypes names
local SENSOR = "request-scanner"
local OnNthTick = _G.OnNthTick
local OnTick = _G.OnTick

---- MOD SETTINGS ----
local UpdateInterval = settings.global["request-scanner_update_interval"].value
local MaxResults = settings.global["request-scanner_max_results"].value
if MaxResults == 0 then MaxResults = nil end
local InvertSign = settings.global["request-scanner-negative-output"].value
local RoundToStack = settings.global["request-scanner-round2stack"].value
local NetworkID = settings.global["request-scanner_networkID"].value

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
	if event.setting == "request-scanner_update_interval" then
		UpdateInterval = settings.global["request-scanner_update_interval"].value
		UpdateEventHandlers()
	end
	if event.setting == "request-scanner_max_results" then
		MaxResults = settings.global["request-scanner_max_results"].value
		if MaxResults == 0 then MaxResults = nil end
	end
	if event.setting == "request-scanner-negative-output" then
		InvertSign = settings.global["request-scanner-negative-output"].value
	end
	if event.setting == "request-scanner-round2stack" then
		RoundToStack = settings.global["request-scanner-round2stack"].value
	end
	if event.setting == "request-scanner_networkID" then
		NetworkID = settings.global["request-scanner_networkID"].value
	end
end)

---- EVENTS ----
do -- create & remove
	local function OnEntityCreated(event)
		local entity = event.created_entity or event.entity
		if entity then
			if entity.name == SENSOR then
				global.RequestScanners = global.RequestScanners or {}
				-- entity.operable = false
				-- entity.rotatable = false
				local requestScanner = {}
				requestScanner.ID = entity.unit_number
				requestScanner.entity = entity
				global.RequestScanners[#global.RequestScanners + 1] = requestScanner
				UpdateEventHandlers()
			end
		end
	end

	local function RemoveSensor(id)
		for i = #global.RequestScanners, 1, -1 do
			if id == global.RequestScanners[i].ID then
				table.remove(global.RequestScanners,i)
			end
		end
		UpdateEventHandlers()
	end

	local function OnEntityRemoved(event)
		if event.entity.name == SENSOR then
			RemoveSensor(event.entity.unit_number)
		end
	end
end

do -- tick handlers
	local function UpdateEventHandlers()
		-- unsubscribe tick handlers
		script.on_nth_tick(nil)
		script.on_event(defines.events.on_tick, nil)
		-- subcribe tick or nth_tick depending on number of scanners
		local entity_count = #global.RequestScanners
		if entity_count > 0 then
			local nth_tick = UpdateInterval / entity_count
			if nth_tick >= 2 then
				script.on_nth_tick(math.floor(nth_tick), OnNthTick)
				-- log("subscribed on_nth_tick = "..math.floor(nth_tick))
			else
				script.on_event(defines.events.on_tick, OnTick)
				-- log("subscribed on_tick")
			end
			script.on_event({defines.events.on_pre_player_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, OnEntityRemoved)
		else	-- all sensors removed
			script.on_event({defines.events.on_pre_player_mined_item, defines.events.on_robot_pre_mined, defines.events.on_entity_died}, nil)
		end
	end

	-- runs when #global.RequestScanners > UpdateInterval/2
	function OnTick(event)
		local offset = event.tick % UpdateInterval
		for i=#global.RequestScanners - offset, 1, -1 * UpdateInterval do
			-- log( event.tick.." updating entity["..i.."]" )
			UpdateSensor(global.RequestScanners[i])
		end
	end

	-- runs when #global.RequestScanners <= UpdateInterval/2
	function OnNthTick(_)
		if global.UpdateIndex > #global.RequestScanners then
			global.UpdateIndex = 1
		end
		-- log( NthTickEvent.tick.." updating entity["..global.UpdateIndex.."]" )
		UpdateSensor(global.RequestScanners[global.UpdateIndex])
		global.UpdateIndex = global.UpdateIndex + 1
	end
end


---- update Sensor ----
do
	local signals
	local signal_indexes

	local function add_signal(name, count)
		local signal_index = signal_indexes[name]
		local s
		if signal_index then
			s = signals[signal_index]
		else
			signal_index = #signals + 1
			signal_indexes[name] = signal_index
			s = { signal = { type = "item", name = name }, count = 0, index = (signal_index) }
			signals[signal_index] = s
		end
		if InvertSign then
			s.count = s.count - count
		else
			s.count = s.count + count
		end
	end

	--- returns request requested items as signals or nil
	local function get_requests_as_signals(logisticNetwork)
		if not (logisticNetwork and logisticNetwork.valid) then
			return nil
		end
		local result_limit = MaxResults
		local found_entities = {} -- store found unit_numbers to prevent duplicate entries
		signals = {}
		signal_indexes = {}
		local count_unique_entities = 0
		local requesterEntities = logisticNetwork.requesters
		for _, e in pairs(requesterEntities) do --1
			local uid = e.unit_number
			if not found_entities[uid]then --2
				found_entities[uid] = true
				if e.to_be_deconstructed(e.force) == false then --3
					for slot = 1, 12 do --4
						if e.get_request_slot(slot) ~= nil then --5
							--has the request been satisfied?
							local itemName = e.get_request_slot(slot).name
							local itemCount = e.get_item_count(itemName)
							local requestCount = e.get_request_slot(slot).count
							local itemRequestCount = requestCount - itemCount
							if itemRequestCount > 0 then --6
								add_signal(itemName, itemRequestCount)
								count_unique_entities = count_unique_entities + 1
							end --6
							if MaxResults then --7
								result_limit = result_limit - count_unique_entities
								if result_limit <= 0 then --8
									break
								end --8
							end --7
						end--5
					end--4
				end--3
			end--2
		end--1

		-- round signals to next stack size
		-- signal = { type = "item", name = name }, count = 0, index = (signal_index)
		if RoundToStack then
			local round = math.ceil
			if InvertSign then round = math.floor end
			for _, signal in pairs(signals) do
				local prototype = game.item_prototypes[signal.signal.name]
				if prototype then
					local stack_size = prototype.stack_size
					signal.count = round(signal.count / stack_size) * stack_size
				end
			end
		end
		return signals
	end

	local function UpdateSensor(requestScanner)
		-- handle invalidated sensors
		if not requestScanner.entity.valid then
			RemoveSensor(requestScanner.ID)
			return
		end
		-- skip scanner if disabled
		if not requestScanner.entity.get_control_behavior().enabled then
			requestScanner.entity.get_control_behavior().parameters = nil
			return
		end
		-- dirty hack, add gui later
		local base_force = requestScanner.entity.force
		local checkForce = base_force
		if NetworkID and NetworkID > 0 then
			local channel_force_name = base_force.name .. ".channel." .. NetworkID
			if game.forces[channel_force_name] ~= nil then
				checkForce = game.forces[channel_force_name]
			--else
			--	game.print("[Request Scanner] Channel # "..tostring(NetworkID).." unknown, using default channel"
			end
		end
		local surface = requestScanner.entity.surface
		-- storing logistic network becomes problematic when roboports run out of energy
		local logisticNetwork = surface.find_logistic_network_by_position(requestScanner.entity.position, checkForce)
		--
		if not logisticNetwork then
			requestScanner.entity.get_control_behavior().parameters = nil
			return
		end
		-- set signals
		local signals = get_requests_as_signals(logisticNetwork)
		if not signals then
			requestScanner.entity.get_control_behavior().parameters = nil
			return
		end
		requestScanner.entity.get_control_behavior().parameters = {parameters = signals}
	end
end


---- INIT ----
do
	local function init_events()
		script.on_event({
			defines.events.on_built_entity,
			defines.events.on_robot_built_entity,
			defines.events.script_raised_built,
			defines.events.script_raised_revive,
		}, OnEntityCreated)
		if global.RequestScanners then
			UpdateEventHandlers()
		end
	end

	script.on_load(function()
		init_events()
	end)

	script.on_init(function()
		global.RequestScanners = global.RequestScanners or {}
		global.UpdateIndex = global.UpdateIndex or 1
		init_events()
	end)

	script.on_configuration_changed(function(_)
		global.RequestScanners = global.RequestScanners or {}
		global.UpdateIndex = global.UpdateIndex or 1
		init_events()
	end)
end
