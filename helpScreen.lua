-- 
-- Abstract: Tilt Monster sample project 
-- Designed and created by Jonathan and Biffy Beebe of Beebe Games exclusively for Ansca, Inc.
-- http://jonbeebe.net/
-- 
-- Version: 2.0.1
-- 
-- Sample code is MIT licensed, see http://developer.anscamobile.com/code/license
-- Copyright (C) 2010 ANSCA Inc. All Rights Reserved.

module(..., package.seeall)

-- Main function - MUST return a display.newGroup()
function new()
	local helpGroup = display.newGroup()
	
	local ui = require("ui")
	
	-- OPTIONS
	--local soundsOn = true; local soundsData
	
	-- OBJECTS
	local menuBtn
	
	--***************************************************

	-- drawBackground()
	
	--***************************************************
	
	local drawBackground = function()
		local helpBackground = display.newImageRect( "helpScreen.png", 480, 320 )
		helpBackground.x = 240; helpBackground.y = 160
		
		helpGroup:insert( helpBackground )
	end
	
	--***************************************************

	-- drawButtons()
	
	--***************************************************
	
	local drawButtons = function()
		-- Setup "Menu" Button
		local touchMenuBtn = function( event )
			if event.phase == "release" then
				
				-- close the web popup
				native.cancelWebPopup()
				
				-- main menu call
				director:changeScene( "gotomainmenu" )
			end
		end
		
		menuBtn = ui.newButton{
			defaultSrc = "menubtn.png",
			defaultX = 125,
			defaultY = 42,
			overSrc = "menubtn-over.png",
			overX = 125,
			overY = 42,
			onEvent = touchMenuBtn,
			id = "menuButton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		
		menuBtn:setReferencePoint( display.BottomLeftReferencePoint )
		menuBtn.xOrigin = 0; menuBtn.yOrigin = 450
		menuBtn.isVisible = false
		
		helpGroup:insert( menuBtn )
		
		-- Show "Menu" Button
		menuBtn.isVisible = true
		menuBtn:setReferencePoint( display.BottomLeftReferencePoint )
		menuBtn.x = 0
		transition.to( menuBtn, { time=1000, y=320, transition=easing.inOutExpo } )
		
	end
	
	--***************************************************

	-- showHelpPopup()
	
	--***************************************************
	
	local showHelpPopup = function()
		local topLoc = 73
		
		if system.getInfo("model") == "iPad" then
			topLoc = 73 + 34
		end
		
		native.showWebPopup( 58, topLoc, 389, 223, "help.html", {baseUrl=system.ResourceDirectory, hasBackground=false } ) 
		
	end
	
	--***************************************************

	-- init()
	
	--***************************************************
	
	local init = function()
		
		drawBackground()
		drawButtons()
		
		showHelpPopup()	--> display local help.html file
		
	end
		
	init()
	
	-- create border if on iPad
	if system.getInfo("model") == "iPad" then
		local iPadBackground = display.newImageRect( "ipadbackground.png", 512, 384 )
		iPadBackground:setReferencePoint( display.TopLeftReferencePoint )
		iPadBackground.x = -16; iPadBackground.y = -34
		
		helpGroup.x = 16; helpGroup.y = 34
		helpGroup:insert( iPadBackground )
	end
	
	-- MUST return a display.newGroup()
	return helpGroup
end
