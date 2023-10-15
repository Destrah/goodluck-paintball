local QBCore = exports['qb-core']:GetCoreObject()

local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

local redspawn = vector3(794.1, -244.53, 67.61)
local bluespawn = vector3(747.83, -215.6, 68.81)
local endPos = vector3(777.99, -205.95, 69.46)
local spectate = vector3(776.26, -233.34, 80.63)
local redradio = 9.0
local blueradio = 10.0

local gameid = -1
local team = ''
local lives = -1
local activeGame = false
local docountdown = true
local team = ''
local handlingDowned = false
local toggleCombat = false
local sideFlip = false
local initialHealth = 150

function startHandling()
	Citizen.CreateThread(function()
		while activeGame do
			if docountdown then
				FreezeEntityPosition(GetPlayerPed(-1), true)
				GiveWeaponToPed(GetPlayerPed(-1), 2578377531, 9, false, true)
				SetCurrentPedWeapon(GetPlayerPed(-1), 2578377531, 1)
				SetPedAmmo(GetPlayerPed(-1), 2578377531, 200)
				SetEntityHealth(GetPlayerPed(-1), initialHealth)
				TriggerEvent('erp-ambulancejob:revive')
				if team == 'red' then
					if sideFlip then
						SetEntityCoords(GetPlayerPed(-1), redspawn, 0.0, 0.0, 0.0, false)
					else
						SetEntityCoords(GetPlayerPed(-1), bluespawn, 0.0, 0.0, 0.0, false)
					end
					--exports.tokovoip_script:addPlayerToRadio(redradio)
					--exports["mumble-voip"]:addPlayerToRadio(redradio)
					exports["pma-voice"]:setRadioChannel(redradio)
					QBCore.Functions.Notify('You switched to radio channel '..redradio, 1)
					TriggerEvent("InteractSound_CL:PlayOnOne","radioon",0.3)
				else
					if sideFlip then
						SetEntityCoords(GetPlayerPed(-1), bluespawn, 0.0, 0.0, 0.0, false)
					else
						SetEntityCoords(GetPlayerPed(-1), redspawn, 0.0, 0.0, 0.0, false)
					end
					--exports.tokovoip_script:addPlayerToRadio(blueradio)
					--exports["mumble-voip"]:addPlayerToRadio(blueradio)
					exports["pma-voice"]:setRadioChannel(blueradio)
					QBCore.Functions.Notify('You switched to radio channel '..blueradio, 1)
					TriggerEvent("InteractSound_CL:PlayOnOne","radioon",0.3)
				end
				exports["pma-voice"]:setVoiceProperty("radioEnabled", true)
				for i = 10, 1, -1 do
					QBCore.Functions.Notify('Match starts in ' .. i .. ' seconds', 1, 500)
					Citizen.Wait(1100)
				end
				QBCore.Functions.Notify('Match started!!!', 1)
				FreezeEntityPosition(GetPlayerPed(-1), false)
				docountdown = false
			end
			Citizen.Wait(100)
		end
	end)
end

-- -1716589765
AddEventHandler('gameEventTriggered', function(event, data)
    if event == "CEventNetworkEntityDamage" then
		local victim, attacker, victimDied, weapon = data[1], data[2], data[4], data[7]
		if NetworkGetPlayerIndexFromPed(victim) == PlayerId() then
			if LocalPlayer.state.isPaintballing then
				print(LocalPlayer.state.isPaintballing, "Damaing weapon", QBCore.Shared.Weapons[weapon].label, weapon, NetworkGetPlayerIndexFromPed(victim), NetworkGetPlayerIndexFromPed(attacker), PlayerId())
				if activeGame then
					if tonumber(weapon) == -1716589765 and NetworkGetPlayerIndexFromPed(attacker) ~= PlayerId() then
						--[[if lives <= 1 then
							lives = lives - 1
							TriggerServerEvent('paintball-server:endGame', gameid, lives)
							endingGame = true
							while endingGame do
								Citizen.Wait(10)
							end
						else
							lives = lives - 1
							toggleCombat = true
							while IsPedRagdoll(GetPlayerPed(-1)) do

								Citizen.Wait(10)
							end
							TriggerServerEvent('paintball-server:startNewRound', gameid)
							startingNewRound = true
							while startingNewRound do
								Citizen.Wait(10)
							end
							toggleCombat = false
						end--]]
						handlingDowned = true
						SetEntityCoords(GetPlayerPed(-1), spectate, 0.0, 0.0, 0.0, false)
						if team == 'red' then
							--exports.tokovoip_script:removePlayerFromRadio(redradio)
						else
							--exports.tokovoip_script:removePlayerFromRadio(blueradio)
						end
						exports["pma-voice"]:setRadioChannel(0)
						exports["pma-voice"]:setVoiceProperty("radioEnabled", false)
						TriggerServerEvent('paintball-server:handleDowned', gameid)
						toggleCombat = true
						while handlingDowned do
							Citizen.Wait(10)
						end
						toggleCombat = false
					end
				end
			end
		end
	end
end)

function startMiscChecking()
	Citizen.CreateThread(function()
		while activeGame do
			SetPedCanRagdoll(GetPlayerPed(-1), not toggleCombat)
			if toggleCombat then
				DisablePlayerFiring(PlayerId(), toggleCombat)
			end
			if GetSelectedPedWeapon(GetPlayerPed(-1)) ~= 2578377531 and GetSelectedPedWeapon(GetPlayerPed(-1)) ~= -1716589765 then
				GiveWeaponToPed(GetPlayerPed(-1), 2578377531, 9, false, true)
				SetCurrentPedWeapon(GetPlayerPed(-1), 2578377531, 1)
				SetPedAmmo(GetPlayerPed(-1), 2578377531, 200)
			end
			if #(vector3(765.47, -229.81, 72) - GetEntityCoords(GetPlayerPed(-1), true)) > 50.0 then
				if team == 'red' then
					if sideFlip then
						SetEntityCoords(GetPlayerPed(-1), redspawn, 0.0, 0.0, 0.0, false)
					else
						SetEntityCoords(GetPlayerPed(-1), bluespawn, 0.0, 0.0, 0.0, false)
					end
				else
					if sideFlip then
						SetEntityCoords(GetPlayerPed(-1), bluespawn, 0.0, 0.0, 0.0, false)
					else
						SetEntityCoords(GetPlayerPed(-1), redspawn, 0.0, 0.0, 0.0, false)
					end
				end
			end
			Citizen.Wait(0)
		end
	end)
end

function IsPlayingPaintball()
	return activeGame
end

exports("IsPlayingPaintball", IsPlayingPaintball)

RegisterNetEvent('paintball-client:startGame')
AddEventHandler('paintball-client:startGame', function(sentgameid, sentlives, sentteam)
	gameid = sentgameid
	activeGame = true
	lives = tonumber(sentlives)
	team = sentteam
	initialHealth = GetEntityHealth(GetPlayerPed(-1))
	startHandling()
    LocalPlayer.state:set('isPaintballing', true, false)
	startMiscChecking()
end)

RegisterNetEvent('paintball-client:restartRound')
AddEventHandler('paintball-client:restartRound', function(sentlives)
	handlingDowned = true
	lives = sentlives
	QBCore.Functions.Notify('Starting new round in 3 seconds. You have  ' .. lives .. ' live(s) left.', 1)
	TriggerServerEvent('paintball-server:startNewRound', gameid)
	Citizen.Wait(3000)
	docountdown = true
	handlingDowned = false
	sideFlip = not sideFlip
end)

RegisterNetEvent('paintball-client:endGame')
AddEventHandler('paintball-client:endGame', function(sentlives, teamcount, total, winningTeam)
	--TriggerServerEvent('TokoVoip:removePlayerFromAllRadio', GetPlayerServerId(PlayerId()))
	--exports["mumble-voip"]:removePlayerFromRadio()
	exports["pma-voice"]:setRadioChannel(0)
	exports["pma-voice"]:setVoiceProperty("radioEnabled", false)
	lives = sentlives
	SetEntityCoords(GetPlayerPed(-1), endPos, 0.0, 0.0, 0.0, false)
	SetEntityHealth(GetPlayerPed(-1), initialHealth)
	TriggerEvent('erp-ambulancejob:revive')
	RemoveAllPedWeapons(GetPlayerPed(-1))
	if team == winningTeam then
		QBCore.Functions.Notify('Game over. You won!!', 1)
		TriggerServerEvent('paintball-server:giveReward', gameid, teamcount, total)
	else
		QBCore.Functions.Notify('Game over. You lost.', 1)
	end
	RemoveAllPedWeapons(GetPlayerPed(-1))
	SetPedCanRagdoll(GetPlayerPed(-1), true)
	gameid = -1
	team = ''
	lives = -1
	activeGame = false
	docountdown = true
	team = ''
	handlingDowned = false
	toggleCombat = false
	sideFlip = false
    LocalPlayer.state:set('isPaintballing', false, false)
end)

RegisterCommand("paintballcreate", function(src, args, raw)
	if #(endPos - GetEntityCoords(GetPlayerPed(-1), false)) <= 10.0 then
		if exports["qb-inventory"]:GetQuantity('pticket') > 0 then
			if #args == 3 then
				if tonumber(args[1]) and tonumber(args[2]) and tonumber(args[3]) then
					if tonumber(args[1]) > 1 then
						TriggerServerEvent('paintball-server:create', tonumber(args[1]), math.floor(tonumber(args[2])), tonumber(args[3]), GetPlayerPed(-1))
					else
						QBCore.Functions.Notify('Must have more than one player', 2)
					end
				else
					QBCore.Functions.Notify('USAGE: /paintballcreate [number of players] [bet amount] [number of lives] <password>')
				end
			elseif #args == 4 then
				if tonumber(args[1]) and tonumber(args[2]) and tonumber(args[3]) then
					TriggerServerEvent('paintball-server:create', tonumber(args[1]), math.floor(tonumber(args[2])), tonumber(args[3]), GetPlayerPed(-1), args[4])
				else
					QBCore.Functions.Notify('USAGE: /paintballcreate [number of players] [bet amount] [number of lives] <password>')
				end
			else
				QBCore.Functions.Notify('USAGE: /paintballcreate [number of players] [bet amount] [number of lives] <password>')
			end
		else
			QBCore.Functions.Notify('You need a paintball ticket before being able to create a game.', 2)
		end
	else
		QBCore.Functions.Notify('You need to be near the paintball booth to start a game.', 2)
	end
end)

RegisterCommand("paintballjoin", function(src, args, raw)
	if #(endPos - GetEntityCoords(GetPlayerPed(-1), false)) <= 10.0 then
		if exports["qb-inventory"]:GetQuantity('pticket') > 0 then
			if #args == 1 then
				if tonumber(args[1]) then
					TriggerServerEvent('paintball-server:join', tonumber(args[1]), GetPlayerPed(-1))
				else
					QBCore.Functions.Notify('USAGE: /paintballjoin [game id] <password>')
				end
			elseif #args == 2 then
				if tonumber(args[1]) then
					TriggerServerEvent('paintball-server:join', tonumber(args[1]), GetPlayerPed(-1), args[2])
				else
					QBCore.Functions.Notify('USAGE: /paintballjoin [game id] <password>')
				end
			else

			end
		else
			QBCore.Functions.Notify('You need a paintball ticket before being able to join.', 2)
		end
	else
		QBCore.Functions.Notify('You need to be near the paintball booth to join a game.', 2)
	end
end)

RegisterCommand("paintballstart", function(src, args, raw)
	if #(endPos - GetEntityCoords(GetPlayerPed(-1), false)) <= 10.0 then
		if #args == 1 then
			if tonumber(args[1]) then
				TriggerServerEvent('paintball-server:startGame', tonumber(args[1]))
			else
				QBCore.Functions.Notify('USAGE: /paintballstart [game id]')
			end
		else

		end
	else
		QBCore.Functions.Notify('You need to be near the paintball booth to start a game.', 2)
	end
end)