QBCore = nil

Citizen.CreateThread(function() 
    while true do
        Citizen.Wait(1)
		if QBCore == nil then
			
            TriggerEvent("QBCore:GetObject", function(obj) QBCore = obj end)    
            Citizen.Wait(200)
        end
    end
end)

Citizen.CreateThread(function() 
    while true do
		Citizen.Wait(30 * 60000)
		print('Coke Table')
		TriggerServerEvent('coke:updateTable', false)
	end
end)

local inUse = false
local process 
local coord 
local location = nil
local enroute
local fueling
local dodo
local delivering
local hangar
local jerrycan
local checkPlane
local flying
local landing
local hasLanded
local pilot
local airplane
local planehash
local driveHangar
local blip
local isProcessing = false

Citizen.CreateThread(function()
	while QBCore == nil do TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end) Wait(0) end
    QBCore.Functions.TriggerCallback('coke:processcoords', function(servercoords)
        process = servercoords
	end)
end)

Citizen.CreateThread(function()
	while QBCore == nil do TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end) Wait(0) end
    QBCore.Functions.TriggerCallback('coke:startcoords', function(servercoords)
        coord = servercoords
	end)
end)

Citizen.CreateThread(function()
	local sleep
	while not coord do
		Citizen.Wait(0)
	end
	while true do
		sleep = 5
		local player = GetPlayerPed(-1)
		local playercoords = GetEntityCoords(player)
		local dist = #(vector3(playercoords.x, playercoords.y, playercoords.z)-vector3(coord.x, coord.y, coord.z))
		if not inUse then
			if dist <= 2.0 then
				sleep = 5
				DrawText3D(coord.x, coord.y, coord.z, 'Press ~g~[ E ]~w~ to rent a Plane for 2000')
				if IsControlJustPressed(1, 51) then
					QBCore.Functions.TriggerCallback('coke:pay', function(success)
						if success then
							main()
						end
					end)
				end
			else
				sleep = 2000
			end
		elseif dist <= 3 and inUse then
			sleep = 0
			DrawText3D(coord.x, coord.y, coord.z, 'Someone has already rented a plane. plesae wait')
		else
			sleep = 3000
		end
		Citizen.Wait(sleep)
	end
end)

RegisterNetEvent('coke:syncTable')
AddEventHandler('coke:syncTable', function(bool)
    inUse = bool
end)

RegisterNetEvent('coke:onUse')
AddEventHandler('coke:onUse', function()
	if Config.useMythic then
		QBCore.Functions.Notify("You used Coke", "success")
	end
	local crackhead = GetPlayerPed(-1)
	SetPedArmour(crackhead, 30)
	SetTimecycleModifier("DRUG_gas_huffin")
	Citizen.Wait(Config.cokeTime)
	DoScreenFadeOut(1000)
	Citizen.Wait(1000)
	DoScreenFadeIn(2000)
	if Config.useMythic then
		QBCore.Functions.Notify("You are feeling normal now..", "success")
	end
	SetPedArmour(crackhead, 0)
	ClearTimecycleModifier()
end)

function main()
	local player = GetPlayerPed(-1)
	SetEntityCoords(player, coord.x-0.1,coord.y-0.1,coord.z-1, 0.0,0.0,0.0, false)
	SetEntityHeading(player, Config.doorHeading)
	playAnim("gestures@f@standing@casual", "gesture_point", 3000)
	Citizen.Wait(2000)
	TriggerServerEvent('coke:updateTable', true)
	if Config.useMythic then
		QBCore.Functions.Notify("Go to the airfield.", "success")
	end
	rand = math.random(1,#Config.locations)
	location = Config.locations[rand]
	blip1 = AddBlipForCoord(location.fuel.x,location.fuel.y,location.fuel.z)
	SetBlipRoute(blip1, true)
	enroute = true
	print('en')
	Citizen.CreateThread(function()
		while enroute do
			sleep = 5	
			local player = GetPlayerPed(-1)
			playerpos = GetEntityCoords(player)
			local disttocoord = #(vector3(location.fuel.x,location.fuel.y,location.fuel.z)-vector3(playerpos.x,playerpos.y,playerpos.z))
			if disttocoord <= 20 then
				--planeFly()
				PlaneSpawn()
				enroute = false
			else
				sleep = 1500
			end
			Citizen.Wait(sleep)
		end
	end)
end

function PlaneSpawn()

	if DoesEntityExist(airplane) then
	    SetVehicleHasBeenOwnedByPlayer(airplane,false)
		SetEntityAsNoLongerNeeded(airplane)
		DeleteEntity(airplane)
	end

	local planehash = GetHashKey("dodo")
	
    RequestModel(planehash)
    while not HasModelLoaded(planehash) do
        Citizen.Wait(0)
    end

    airplane = CreateVehicle(planehash, location.parking.x, location.parking.y, location.parking.z, 100, true, false)
    local plt = GetVehicleNumberPlateText(airplane)
	SetVehicleHasBeenOwnedByPlayer(airplane,true)
	
	local plate = GetVehicleNumberPlateText(airplane)
	--TriggerServerEvent('garage:addKeys', plate)
	TriggerEvent("vehiclekeys:client:SetOwner", airplane)

	RemoveBlip(blip1)
	SetBlipRoute(blip1, false)
	PoliceCall()
	
	dodo = false
	delivering = true
	delivery()

	
    while true do
    	Citizen.Wait(1)
    	 DrawText3D(location.parking.x, location.parking.y, location.parking.z, "Cocaine Plane.")
		 if #(GetEntityCoords(PlayerPedId()) - vector3(location.parking.x, location.parking.y, location.parking.z)) < 8.0 then
    	 	return
    	 end
	end
end

function planeFly()
	
	
end


Citizen.CreateThread(function()
	checkPlane = true
	while checkPlane do
		sleep = 100 
		if DoesEntityExist(airplane) then
			if GetVehicleEngineHealth(airplane) < 0 then
				if Config.useMythic then
					QBCore.Functions.Notify("Failed, your plane was Destroyed", "error")
				end
				TriggerServerEvent('coke:updateTable', false)
				RemoveBlip(blip)
				SetBlipRoute(blip, false)
				DeleteEntity(pickupSpawn)
				delivering = false
				checkPlane = false
			end
		else
			sleep = 3000
		end
		Citizen.Wait(sleep)
	end
end)

function delivery()
	if Config.useMythic then
		QBCore.Functions.Notify("Get in the plane and pick up the delivery marked on your GPS", "success")
	end
	local pickup = GetHashKey("prop_barrel_float_1")
	blip = AddBlipForCoord(location.delivery.x,location.delivery.y,location.delivery.z)
	SetBlipRoute(blip, true)
	RequestModel(pickup)
	while not HasModelLoaded(pickup) do
		Citizen.Wait(0)
	end
	local pickupSpawn = CreateObject(pickup, location.delivery.x,location.delivery.y,location.delivery.z, true, true, true)
	local player = GetPlayerPed(-1)
	Citizen.CreateThread(function()
		while delivering do
			sleep = 5	
			local playerpos = GetEntityCoords(player)
			local disttocoord = #(vector3(location.delivery.x,location.delivery.y,location.delivery.z)-vector3(playerpos.x,playerpos.y,playerpos.z))
			if disttocoord <= 30 then
				RemoveBlip(blip)
				SetBlipRoute(blip, false)
				DrawText3D(location.delivery.x,location.delivery.y,location.delivery.z-1, 'Press ~g~[ E ]~w~ to pick up the delivery')
				if IsControlJustPressed(1, 51) then
					delivering = false

					QBCore.Functions.Progressbar("picking_", "Picking up the delivery..", lockpickTime, false, true, {
						disableMovement = true,
						disableCarMovement = true,
						disableMouse = false,
						disableCombat = true,
					}, {}, {}, {}, function() -- Done
						DeleteEntity(pickupSpawn)
					end, function() -- Cancel
						QBCore.Functions.Notify("Canceled!", "error")
					end)

					Citizen.Wait(2000)
					QBCore.Functions.Notify("Picked up the delivery. Return to the airfield marked on your GPS.", "success")
					Citizen.Wait(2000)
					final()
				end
			else
				sleep = 1500
			end
			Citizen.Wait(sleep)
		end
	end)
end
function DrawText3D(x, y, z, text)
	SetTextScale(0.35, 0.35)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextColour(255, 255, 255, 215)
	SetTextEntry("STRING")
	SetTextCentre(true)
	AddTextComponentString(text)
	SetDrawOrigin(x,y,z, 0)
	DrawText(0.0, 0.0)
	local factor = (string.len(text)) / 370
	DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
	ClearDrawOrigin()
end
function final()
	QBCore.Functions.Notify("Deliver the plane back to a hangar", "success")
	blip = AddBlipForCoord(location.hangar.x,location.hangar.y,location.hangar.z)
	SetBlipRoute(blip, true)
	hangar = true
	local player = GetPlayerPed(-1)
	Citizen.CreateThread(function()
		while hangar do
			sleep = 5	
			local playerpos = GetEntityCoords(player)
			local disttocoord = #(vector3(location.hangar.x,location.hangar.y,location.hangar.z)-vector3(playerpos.x,playerpos.y,playerpos.z))
			if IsPedInAnyPlane(GetPlayerPed(-1)) and disttocoord <= 10 then
				RemoveBlip(blip)
				SetBlipRoute(blip, false)
				DrawText3D(location.hangar.x,location.hangar.y,location.hangar.z-1, 'Press [E] to park the plane.')
				DrawMarker(27, location.hangar.x,location.hangar.y,location.hangar.z-0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 2.0, 2.0, 2.0, 3, 252, 152, 100, false, true, 2, false, false, false, false)
				if IsControlJustPressed(1, 51) then
					hangar = false
					FreezeEntityPosition(airplane, true)
					QBCore.Functions.Progressbar("lockpick_vehicledoor", "Storing Plane..", 1000, false, true, {
						disableMovement = true,
						disableCarMovement = true,
						disableMouse = false,
						disableCombat = true,
					}, {}, {}, {}, function() -- Done
						DeleteEntity(airplane)
					end, function() -- Cancel
						DeleteEntity(airplane)
					end)

					Citizen.Wait(2000)
					TriggerServerEvent('coke:GiveItem')
					TaskLeaveVehicle(player, airplane, 0)
					SetVehicleDoorsLocked(airplane, 2)
					Citizen.Wait(1000)
					if Config.useCD then		
						cooldown()
					else
						TriggerServerEvent('coke:updateTable', false)
					end
				end
			else
				sleep = 1500
			end
			Citizen.Wait(sleep)
		end
	end)
end

Citizen.CreateThread(function()
	local sleep
	while not process do
		Citizen.Wait(0)
	end
	while true do
		sleep = 5
		local player = GetPlayerPed(-1)
		local playercoords = GetEntityCoords(player)
		local dist = #(vector3(playercoords.x,playercoords.y,playercoords.z)-vector3(process.x,process.y,process.z))
		if dist <= 3 and not isProcessing then
			sleep = 5
			DrawText3D(process.x, process.y, process.z, 'Press [ E ] to begin breaking down the cocaine')
			if IsControlJustPressed(1, 51) then		
				isProcessing = true
				QBCore.Functions.TriggerCallback('QBCore:HasItem', function(result)
					if result then
						processing()
					else
						QBCore.Functions.Notify("You need coke brick to do this", "error")
						isProcessing = false
					end
				end, 'coke_brick')
			end
		else
			sleep = 1500
		end
		Citizen.Wait(sleep)
	end
end)

function processing()
	local player = GetPlayerPed(-1)
	SetEntityCoords(player, process.x,process.y,process.z-1, 0.0, 0.0, 0.0, false)
	SetEntityHeading(player, 51.734)
	FreezeEntityPosition(player, true)
	playAnim("anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 30000)

	QBCore.Functions.Progressbar("coke-", "Breaking down the coke..", 30000, false, true, {
		disableMovement = true,
		disableCarMovement = true,
		disableMouse = false,
		disableCombat = true,
	}, {}, {}, {}, function() -- Done
		FreezeEntityPosition(player, false)
		TriggerServerEvent('coke:processed')
		isProcessing = false
	end, function() -- Cancel
		isProcessing = false
		ClearPedTasksImmediately(player)
		FreezeEntityPosition(player, false)
	end)

end

function cooldown()
	Citizen.Wait(Config.cdTime)
	TriggerServerEvent('coke:updateTable', false)
end

function playAnimPed(animDict, animName, duration, buyer, x,y,z)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do 
      Citizen.Wait(0) 
    end
    TaskPlayAnim(pilot, animDict, animName, 1.0, -1.0, duration, 49, 1, false, false, false)
    RemoveAnimDict(animDict)
end

function playAnim(animDict, animName, duration)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do 
      Citizen.Wait(0) 
    end
    TaskPlayAnim(GetPlayerPed(-1), animDict, animName, 1.0, -1.0, duration, 49, 1, false, false, false)
    RemoveAnimDict(animDict)
end

function PoliceCall(vehicle)

	local pos = GetEntityCoords(PlayerPedId())
	local chance = 20
	local msg = ""
	local s1, s2 = Citizen.InvokeNative(0x2EB41072B4C1E4C0, pos.x, pos.y, pos.z, Citizen.PointerValueInt(), Citizen.PointerValueInt())
	local streetLabel = GetStreetNameFromHashKey(s1)
	local street2 = GetStreetNameFromHashKey(s2)
	if street2 ~= nil and street2 ~= "" then 
		streetLabel = streetLabel .. " " .. street2
	end
	local alertTitle = ""

		local vehicle = vehicle
		local modelName = GetEntityModel(vehicle)
		if QBCore.Shared.VehicleModels[modelName] ~= nil then
			Name = QBCore.Shared.Vehicles[QBCore.Shared.VehicleModels[modelName]["model"]]["brand"] .. ' ' .. QBCore.Shared.Vehicles[QBCore.Shared.VehicleModels[modelName]["model"]]["name"]
		else
			Name = "Unknown"
		end
		local plate = GetVehicleNumberPlateText(airplane)
		local msg = "10-31 | Vehicle Transporting Drugs " ..streetLabel.. ". Vehicle: " .. Name .. ", License Plate: " .. plate
		local alertTitle = " Drug Transporting (Plane)"
		TriggerServerEvent("police:server:VehicleCall", pos, msg, alertTitle, streetLabel, plate, Name)

end
