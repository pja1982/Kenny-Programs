local component = require("component")
local event = require("event")
local fs = require("filesystem")
local keyboard = require("keyboard")
local shell = require("shell")
local term = require("term")
local text = require("text")
local unicode = require("unicode")
local sides = require("sides")
local colors=require("colors")

local gpu=component.gpu
local br = component.br_reactor
local rs = component.redstone

local maxTemp = 5500

local tickCnt = 0
local minCount = 0
local tickEnergy = 0
local minEnergy = 0
local slp = 1
local rodLevel = br.getControlRodLevel(0)

local running = true
local hours = 0
local mins = 0

term.clear()
term.setCursorBlink(false)


-------------------------------------------------------------------------------
function getKey()
	return (select(4, event.pull("key_down")))
end

local function printXY(row, col, s, ...)
	term.setCursor(col, row)
	print(s:format(...))
end

local function gotoXY(row, col)
	term.setCursor(col,row)
end

local function center(row, msg)
	local mLen = string.len(msg)
	w, h = gpu.getResolution()
	term.setCursor((w - mLen)/2,row)
	print(msg)
end

local function centerF(row, msg, ...)
	local mLen = string.len(msg)
	w, h = gpu.getResolution()
	term.setCursor((w - mLen)/2,row)
	print(msg:format(...))
end

local function warning(row, msg)
	local mLen = string.len(msg)
	w, h = gpu.getResolution()
	term.setCursor((w - mLen)/2,row)
	print(msg)
end


local controlKeyCombos = {[keyboard.keys.s]=true,[keyboard.keys.w]=true,
                          [keyboard.keys.c]=true,[keyboard.keys.x]=true}


local function onKeyDown(opt)
	if opt == keyboard.keys.left then
    br.setActive(false)
  elseif opt == keyboard.keys.right then
    br.setActive(true)
  elseif opt == keyboard.keys.up then
    if (rodLevel > 0) then
		  rodLevel = rodLevel - 1
			br.setAllControlRodLevels(rodLevel)
		end
  elseif opt == keyboard.keys.down then
    if (rodLevel < 100) then
		  rodLevel = rodLevel + 1
			br.setAllControlRodLevels(rodLevel)
		end
  elseif opt == keyboard.keys.pageDown then
		br.doEjectWaste()
  elseif opt == keyboard.keys.q then
    running = false
  end
end

-------------------------------------------------------------------------------


while running do
	tickCnt = tickCnt + 1
	if tickCnt == 20 then
		mins = mins + 1
		tickCnt = 0
	end
		
	if math.fmod(tickCnt,20) == 0 then 
		br.doEjectWaste()
	end
	
	if mins == 60 then
		hours = hours + 1
		mins = 0
	end
	
	local reactorTemp = br.getCasingTemperature()
	term.setCursor(1,1)
	print("    Item     Name:          Level:           Temperature:          Fuel:          Max Fuel          Waste:")
	printXY(4, 1, "   10:       Reactor        %03d              %04d                  %06d         %06d            %04d", br.getControlRodLevel(0), br.getCasingTemperature(), br.getFuelAmount(), br.getFuelAmountMax(), br.getWasteAmount())
	printXY(5, 1, "   11:       Energy Stored           %06.2f", br.getEnergyStored())
	printXY(6, 1, "   12:       Energy Last Tick           %06.2f", br.getEnergyProducedLastTick())
	
	centerF(40, "Data updates every second     Tick Count:  %2d", tickCnt)
	centerF(41, "Current up time:             %2d hours %2d min", hours, mins)
	center(42, "Left - Turn Reactor Off     Right - Turn Reactor On")
	center(43, "Up - Pull Rods 1%           Down - Lower Rods 1%  ")
	center(44, "Page Down - Eject Waste     Q - Quit               ")
	--center(39, "  ")
	
	if (reactorTemp > maxTemp) then
		term.setCursor(25,30)
		gpu.setForeground(0xFF0000)
		gpu.setBackground(0xFFFFFF)
		warning(30, "                                         ")
		warning(31, "     WARNING     WARNING     WARNING     ")
		warning(32, "                                         ")
		warning(33, "       Reactor Temperature Too High       ")
		warning(34, "                                         ")
		gpu.setForeground(0xFFFFFF)
		gpu.setBackground(0x000000)
		term.setCursor(1,41)
	else
		gpu.setForeground(0xFFFFFF)
		gpu.setBackground(0x000000)
		gotoXY(30,1)
		print()
		gotoXY(31,1)
		print()
		gotoXY(32,1)
		print()
		gotoXY(33,1)
		print()
		gotoXY(34,1)
		print()
		gpu.setForeground(0xFFFFFF)
		gpu.setBackground(0x000000)
		term.setCursor(1,47)
	end
	term.clearLine()
	print()	
  local event, address, arg1, arg2, arg3 = event.pull(1)
  if type(address) == "string" and component.isPrimary(address) then
    if event == "key_down" then
      onKeyDown(arg2)
    end
  end
end

term.clear()
term.setCursorBlink(false)
