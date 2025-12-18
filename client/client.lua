-- Erklärung 
-- vector4(x, y, z, heading) = x,y,z Koordinaten und heading ist die Blickrichtung
-- car model
-- job = Job-Name (z.B. "police", "ambulance", etc.)

ESX = exports['es_extended']:getSharedObject()

local coordinate = {
  -- Polizei Fahrzeuge 
  -- Straße
  { vector4(-588.71, -383.72, 34.81, 270.52), "polgt63", "police" },
  { vector4(-451.43, -445.36, 33.08, 260.97), "sw_subrb", "police" },
  { vector4(-456.14, -456.49, 33.11, 350.34), "sw_sprinter", "police" },
  { vector4(-451.95, -457.09, 33.02, 348.82), "sw_bearcat", "police" },
  { vector4(-448.66, -458.50, 32.95, 349.40), "sw_charg", "police" },
  { vector4(-445.17, -459.09, 32.88, 351.96), "sw_durango", "police" },
  { vector4(-493.60, -453.86, 34.20, 83.54), "polcoach", "police" }
  -- Police Fahrzeuge Dach
  --{ vector4(-588.71, -383.72, 34.81, 270.52), "polgt63", "police" },
  --{ vector4(-518.82, -425.18, 34.49, 352.64), "sw_subrb", "police" }
}

local spawnedVehicles = {}
local vehicleData = {} -- Speichert Fahrzeug-Daten für Respawn
local lastRespawnTime = 0 -- Zeitpunkt des letzten Respawn-Commands
local respawnCooldown = 30 * 60 * 1000 -- 30 Minuten in Millisekunden
local respawnInProgress = false -- Flag für laufenden Respawn-Prozess

-- Funktion zum Spawnen eines Fahrzeugs
local function SpawnVehicle(coordData, index)
    local v1 = coordData[1]
    local vehicleModel = coordData[2]
    local requiredJob = coordData[3] or "police"
    
    RequestModel(vehicleModel) 
    while not HasModelLoaded(vehicleModel) do
        Wait(10)
    end
    local Vehicle = CreateVehicle(vehicleModel, v1.x, v1.y, v1.z, v1.w, false, false)
    SetVehicleMod(Vehicle, 48, 5, true) -- Spoiler
    SetModelAsNoLongerNeeded(GetHashKey(vehicleModel))
    SetVehRadioStation(Vehicle, "OFF")
    Wait(10)
    SetVehicleOnGroundProperly(Vehicle)
    
    -- Fahrzeug sperren und Job-Information speichern
    -- Wird dynamisch entsperrt, wenn Spieler mit richtigem Job in der Nähe ist
    SetVehicleDoorsLocked(Vehicle, 2)
    SetEntityAsMissionEntity(Vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(Vehicle, false)
    
    -- Prüfe sofort, ob Spieler in der Nähe den richtigen Job hat (ab Rang 1)
    Citizen.CreateThread(function()
        Wait(1000) -- Warte kurz, damit ESX geladen ist
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local vehicleCoords = GetEntityCoords(Vehicle)
        local distance = #(playerCoords - vehicleCoords)
        
        local xPlayer = ESX.GetPlayerData()
        if xPlayer and xPlayer.job and xPlayer.job.name == requiredJob and xPlayer.job.grade >= 1 then
            -- Wenn Spieler in der Nähe (15m), entsperre sofort
            if distance < 15.0 then
                SetVehicleDoorsLocked(Vehicle, 0)
            end
        end
    end)
    
    -- Fahrzeug in Tabelle speichern mit Job-Info
    spawnedVehicles[Vehicle] = {
        job = requiredJob,
        model = vehicleModel,
        index = index
    }
    
    -- Daten für Respawn speichern
    vehicleData[index] = {
        coord = coordData,
        vehicle = Vehicle
    }
    
    return Vehicle
end

-- NICHTS ÄNDERN !!!
Citizen.CreateThread(function()
    for i, v in pairs(coordinate) do
        SpawnVehicle(v, i)
    end
end)

-- Prüfe beim Versuch einzusteigen, ob Spieler den richtigen Job hat
Citizen.CreateThread(function()
    while true do
        Wait(50) -- Schnellere Prüfung für bessere Reaktionszeit
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsTryingToEnter(playerPed)
        
        if vehicle ~= 0 and spawnedVehicles[vehicle] then
            local requiredJob = spawnedVehicles[vehicle].job
            local xPlayer = ESX.GetPlayerData()
            
            if xPlayer and xPlayer.job and xPlayer.job.name == requiredJob and (xPlayer.job.grade or 0) >= 1 then
                -- Spieler hat den richtigen Job und Rang >= 1 - Fahrzeug entsperren
                SetVehicleDoorsLocked(vehicle, 0)
            else
                -- Spieler hat nicht den richtigen Job oder zu niedrigen Rang - Fahrzeug sperren
                SetVehicleDoorsLocked(vehicle, 2)
                ClearPedTasksImmediately(playerPed)
                ESX.ShowNotification("~r~Du hast keinen Zugriff auf dieses Fahrzeug!")
            end
        end
    end
end)

-- Prüfe beim Einsteigen, ob Spieler den richtigen Job hat (zusätzliche Sicherheit)
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkPlayerEnteredVehicle' then
        local vehicle = args[1]
        local playerPed = PlayerPedId()
        
        if spawnedVehicles[vehicle] then
            local requiredJob = spawnedVehicles[vehicle].job
            local xPlayer = ESX.GetPlayerData()
            
            if xPlayer and xPlayer.job and (xPlayer.job.name ~= requiredJob or xPlayer.job.grade < 1) then
                -- Spieler hat nicht den richtigen Job oder zu niedrigen Rang
                TaskLeaveVehicle(playerPed, vehicle, 0)
                ESX.ShowNotification("~r~Du hast keinen Zugriff auf dieses Fahrzeug!")
                Wait(100)
                SetVehicleDoorsLocked(vehicle, 2)
            else
                -- Spieler hat den richtigen Job und Rang >= 1 - Fahrzeug entsperren
                SetVehicleDoorsLocked(vehicle, 0)
            end
        end
    end
end)

-- Prüfe kontinuierlich, ob Spieler in der Nähe von Fahrzeugen den richtigen Job hat und entsperre sie
Citizen.CreateThread(function()
    while true do
        Wait(500) -- Häufigere Prüfung für bessere Reaktionszeit
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local xPlayer = ESX.GetPlayerData()
        
        if xPlayer and xPlayer.job then
            local playerJob = xPlayer.job.name
            local playerGrade = xPlayer.job.grade or 0
            
            -- Prüfe alle gespawnten Fahrzeuge
            for vehicle, data in pairs(spawnedVehicles) do
                if DoesEntityExist(vehicle) then
                    local vehicleCoords = GetEntityCoords(vehicle)
                    local distance = #(playerCoords - vehicleCoords)
                    
                    -- Wenn Spieler in der Nähe (15m) und richtiger Job mit Rang >= 1, entsperre Fahrzeug
                    if distance < 15.0 and data.job == playerJob and playerGrade >= 1 then
                        SetVehicleDoorsLocked(vehicle, 0)
                    elseif distance < 15.0 and (data.job ~= playerJob or playerGrade < 1) then
                        -- Spieler mit falschem Job oder zu niedrigen Rang in der Nähe - sperre Fahrzeug
                        local pedInVehicle = GetVehiclePedIsIn(playerPed, false)
                        if pedInVehicle ~= vehicle then
                            SetVehicleDoorsLocked(vehicle, 2)
                        end
                    end
                end
            end
        end
    end
end)

-- Alternative Methode: Prüfe kontinuierlich, ob Spieler im Fahrzeug sitzt
Citizen.CreateThread(function()
    while true do
        Wait(500)
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        
        if vehicle ~= 0 and spawnedVehicles[vehicle] then
            local requiredJob = spawnedVehicles[vehicle].job
            local xPlayer = ESX.GetPlayerData()
            
            if xPlayer and xPlayer.job and (xPlayer.job.name ~= requiredJob or xPlayer.job.grade < 1) then
                -- Spieler hat nicht den richtigen Job oder zu niedrigen Rang - auswerfen
                TaskLeaveVehicle(playerPed, vehicle, 0)
                ESX.ShowNotification("~r~Du hast keinen Zugriff auf dieses Fahrzeug!")
                Wait(100)
                SetVehicleDoorsLocked(vehicle, 2)
            end
        end
    end
end)

-- Funktion zum Prüfen und Respawnen von Fahrzeugen am Spawnpunkt
local function CheckAndRespawnVehicles()
    for i, coordData in pairs(coordinate) do
        local v1 = coordData[1]
        local spawnCoords = vector3(v1.x, v1.y, v1.z)
        
        -- Prüfe ob Fahrzeug am Spawnpunkt existiert
        local vehicleAtSpawn = GetClosestVehicle(spawnCoords.x, spawnCoords.y, spawnCoords.z, 2.0, 0, 71)
        
        -- Prüfe ob das Fahrzeug in unserer Liste ist
        local isOurVehicle = false
        if vehicleAtSpawn ~= 0 and spawnedVehicles[vehicleAtSpawn] then
            isOurVehicle = true
        end
        
        -- Prüfe ob unser gespawntes Fahrzeug noch existiert
        local ourVehicleExists = false
        local ourVehicleDistance = 999999.0
        if vehicleData[i] and vehicleData[i].vehicle and DoesEntityExist(vehicleData[i].vehicle) then
            ourVehicleExists = true
            local vehicleCoords = GetEntityCoords(vehicleData[i].vehicle)
            ourVehicleDistance = #(spawnCoords - vehicleCoords)
        end
        
        -- Nur respawne wenn:
        -- 1. Kein Fahrzeug am Spawnpunkt ODER es ist nicht unseres
        -- 2. UND unser Fahrzeug existiert nicht mehr
        -- WICHTIG: Fahrzeuge die weggefahren wurden werden NICHT gelöscht!
        if (vehicleAtSpawn == 0 or not isOurVehicle) and vehicleData[i] then
            if not ourVehicleExists then
                -- Fahrzeug existiert nicht mehr (gelöscht) - respawne
                local newVehicle = SpawnVehicle(coordData, i)
            end
            -- Wenn Fahrzeug existiert aber nicht am Spawnpunkt ist, mache nichts
            -- (Fahrzeug wurde weggefahren und bleibt bestehen)
        end
    end
end

-- Kontinuierliche Prüfung auf fehlende Fahrzeuge am Spawnpunkt
Citizen.CreateThread(function()
    while true do
        Wait(5000) -- Prüfe alle 5 Sekunden
        CheckAndRespawnVehicles()
    end
end)

-- /dv Command - Löscht das Fahrzeug, in dem der Spieler sitzt oder das nächste Fahrzeug
RegisterCommand('dv', function()
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    
    if vehicle == 0 then
        -- Kein Fahrzeug, suche nächstes Fahrzeug
        vehicle = GetClosestVehicle(GetEntityCoords(playerPed), 5.0, 0, 71)
    end
    
    if vehicle ~= 0 and DoesEntityExist(vehicle) then
        if spawnedVehicles[vehicle] then
            local index = spawnedVehicles[vehicle].index
            local coordData = coordinate[index]
            local v1 = coordData[1]
            local spawnCoords = vector3(v1.x, v1.y, v1.z)
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - spawnCoords)
            
            -- Prüfe ob Fahrzeug am Spawnpunkt gelöscht wird
            if distance < 3.0 then
                -- Fahrzeug aus Tabellen entfernen
                if vehicleData[index] then
                    vehicleData[index].vehicle = nil
                end
                spawnedVehicles[vehicle] = nil
                DeleteEntity(vehicle)
                
                -- Warte kurz und respawne am Spawnpunkt
                Wait(500)
                SpawnVehicle(coordData, index)
                ESX.ShowNotification("~g~Fahrzeug gelöscht und respawnt!")
            else
                -- Fahrzeug nicht am Spawnpunkt - einfach löschen
                if vehicleData[index] then
                    vehicleData[index].vehicle = nil
                end
                spawnedVehicles[vehicle] = nil
                DeleteEntity(vehicle)
                ESX.ShowNotification("~g~Fahrzeug gelöscht!")
            end
        else
            -- Nicht unser Fahrzeug - einfach löschen
            DeleteEntity(vehicle)
            ESX.ShowNotification("~g~Fahrzeug gelöscht!")
        end
    else
        ESX.ShowNotification("~r~Kein Fahrzeug gefunden!")
    end
end, false)

-- Funktion zum Prüfen ob ein Fahrzeug besetzt ist
local function IsVehicleOccupied(vehicle)
    if not DoesEntityExist(vehicle) then
        return false
    end
    
    local numSeats = GetVehicleModelNumberOfSeats(GetEntityModel(vehicle))
    for i = -1, numSeats - 2 do
        local ped = GetPedInVehicleSeat(vehicle, i)
        if ped ~= 0 and DoesEntityExist(ped) then
            return true
        end
    end
    return false
end

-- /respawncars Command - Respawnt alle Fahrzeuge für den Job des Spielers
RegisterCommand('respawncars', function()
    local currentTime = GetGameTimer()
    
    -- Prüfe Cooldown
    if currentTime - lastRespawnTime < respawnCooldown then
        local remainingTime = math.ceil((respawnCooldown - (currentTime - lastRespawnTime)) / 1000 / 60)
        ESX.ShowNotification("~r~Cooldown aktiv! Bitte warte noch " .. remainingTime .. " Minute(n).")
        return
    end
    
    -- Prüfe ob bereits ein Respawn läuft
    if respawnInProgress then
        ESX.ShowNotification("~r~Ein Respawn-Prozess läuft bereits!")
        return
    end
    
    local xPlayer = ESX.GetPlayerData()
    
    if not xPlayer or not xPlayer.job then
        ESX.ShowNotification("~r~Fehler beim Laden deiner Job-Daten!")
        return
    end
    
    local playerJob = xPlayer.job.name
    
    -- Zeige Nachricht im Chat
    TriggerEvent('chat:addMessage', {
        color = {255, 255, 0},
        multiline = true,
        args = {"System", "Dienstfahrzeuge werden in 60 Sekunden neu gesetzt, sofern diese nicht besetzt sind."}
    })
    
    -- Setze Flag und Cooldown
    respawnInProgress = true
    lastRespawnTime = currentTime
    
    -- Warte 60 Sekunden
    Citizen.SetTimeout(60000, function()
        respawnInProgress = false
        
        local returnedCount = 0
        local skippedCount = 0
        
        -- Bring alle Fahrzeuge für diesen Job zum Spawnpunkt zurück
        for i, coordData in pairs(coordinate) do
            local requiredJob = coordData[3] or "police"
            
            if requiredJob == playerJob then
                -- Prüfe ob altes Fahrzeug existiert
                if vehicleData[i] and vehicleData[i].vehicle and DoesEntityExist(vehicleData[i].vehicle) then
                    local oldVehicle = vehicleData[i].vehicle
                    local v1 = coordData[1]
                    
                    -- Prüfe ob Fahrzeug besetzt ist
                    if IsVehicleOccupied(oldVehicle) then
                        skippedCount = skippedCount + 1
                        -- Überspringe dieses Fahrzeug
                    else
                        -- Fahrzeug ist nicht besetzt - bringe es zum Spawnpunkt zurück
                        local spawnCoords = vector3(v1.x, v1.y, v1.z)
                        local spawnHeading = v1.w
                        
                        -- Setze Fahrzeugposition und Heading
                        SetEntityCoordsNoOffset(oldVehicle, spawnCoords.x, spawnCoords.y, spawnCoords.z, false, false, false)
                        SetEntityHeading(oldVehicle, spawnHeading)
                        
                        -- Setze Fahrzeug auf den Boden
                        SetVehicleOnGroundProperly(oldVehicle)
                        
                        -- Setze Fahrzeuggeschwindigkeit auf 0
                        SetEntityVelocity(oldVehicle, 0.0, 0.0, 0.0)
                        SetVehicleForwardSpeed(oldVehicle, 0.0)
                        
                        -- Motor ausschalten
                        SetVehicleEngineOn(oldVehicle, false, true, true)
                        
                        -- Fahrzeug sperren
                        SetVehicleDoorsLocked(oldVehicle, 2)
                        
                        returnedCount = returnedCount + 1
                    end
                else
                    -- Kein altes Fahrzeug vorhanden - spawne neues
                    SpawnVehicle(coordData, i)
                    returnedCount = returnedCount + 1
                end
            end
        end
        
        -- Benachrichtigung
        if returnedCount > 0 then
            ESX.ShowNotification("~g~" .. returnedCount .. " Fahrzeug(e) für Job '" .. playerJob .. "' zum Spawnpunkt zurückgebracht!")
        end
        if skippedCount > 0 then
            ESX.ShowNotification("~y~" .. skippedCount .. " Fahrzeug(e) übersprungen (besetzt).")
        end
        if returnedCount == 0 and skippedCount == 0 then
            ESX.ShowNotification("~r~Keine Fahrzeuge für deinen Job gefunden!")
        end
    end)
end, false)