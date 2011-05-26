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
	local optionsGroup = display.newGroup()
	
	local ui = require("ui")
	local movieclip = require ("movieclip")	
	
	-- OPTIONS
	local settingsChanged = false
	
	local soundsOn = true; local soundsData
	local musicOn = false; local musicData
	
	local charSelection = "d"	--> d, ms. d, purple moe
	local themeSelection = "classic"	--> classic, spook, disco
	local tiltSelection = "3"	--> 1, 2, 3, 4, 5
	local diffSelection = "0"	--> 0=medium, 1=easy, 2=hard
	
	
	-- OBJECTS
	local menuBtn
	local charSelector
	local themeSelector
	local tiltSelector
	local diffButton
	
	local muteMusic
	local muteSounds
	
	-- SOUNDS
	local tapSound = audio.loadSound( "tapsound.caf" )
	
	
	--***************************************************
	
	-- unloadSounds()
	
	--***************************************************
	
	local unloadSounds = function()
		
		audio.stop()
		
		if tapSound then
			audio.dispose( tapSound )
			tapSound = nil
		end
	end
	
	--***************************************************

	-- saveValue() --> used for saving high score, etc.
	
	--***************************************************
	local saveValue = function( strFilename, strValue )
		-- will save specified value to specified file
		local theFile = strFilename
		local theValue = strValue
		
		local path = system.pathForFile( theFile, system.DocumentsDirectory )
		
		-- io.open opens a file at path. returns nil if no file found
		local file = io.open( path, "w+" )
		if file then
		   -- write game score to the text file
		   file:write( theValue )
		   io.close( file )
		end
	end
	
	--***************************************************

	-- loadValue() --> load saved value from file (returns loaded value as string)
	
	--***************************************************
	local loadValue = function( strFilename )
		-- will load specified file, or create new file if it doesn't exist
		
		local theFile = strFilename
		
		local path = system.pathForFile( theFile, system.DocumentsDirectory )
		
		-- io.open opens a file at path. returns nil if no file found
		local file = io.open( path, "r" )
		if file then
		   -- read all contents of file into a string
		   local contents = file:read( "*a" )
		   io.close( file )
		   return contents
		else
		   -- create file b/c it doesn't exist yet
		   file = io.open( path, "w" )
		   file:write( "0" )
		   io.close( file )
		   return "0"
		end
	end
	
	--***************************************************

	-- saveChanges()
	
	--***************************************************
	
	local saveChanges = function()
		Runtime:removeEventListener( "touch", muteUnmute )
		
		if settingsChanged == true then
			saveValue( "char.data", charSelection )
			saveValue( "theme.data", themeSelection )
			saveValue( "tilt.data", tiltSelection )
			saveValue( "music.data", musicData )
			saveValue( "sound.data", soundsData )
			saveValue( "difficulty.data", diffSelection )
		end
	end
	
	--***************************************************

	-- drawBackground()
	
	--***************************************************
	
	local drawBackground = function()
		local optionsBackground = display.newImageRect( "optionsBackground.png", 480, 320 )
		optionsBackground.x = 240; optionsBackground.y = 160
		
		optionsGroup:insert( optionsBackground )
	end
	
	--***************************************************

	-- drawButtons()
	
	--***************************************************
	
	local drawButtons = function()
		-- Setup "Menu" Button
		local touchMenuBtn = function( event )
			if event.phase == "release" and menuBtn.isActive == true then
				menuBtn.isActive = false
				
				-- Play Sound
				if soundsOn == true then
					audio.play( tapSound )
				end
				
				-- save settings if any were changed
				saveChanges()
				
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
		
		optionsGroup:insert( menuBtn )
		
		-- Setup "Credits" Button
		local touchCreditsBtn = function( event )
			if event.phase == "release" and creditsBtn.isActive == true then
				creditsBtn.isActive = false
				
				-- Play Sound
				if soundsOn == true then
					audio.play( tapSound )
				end
				
				-- save settings if any were changed
				saveChanges()
				
				-- main menu call
				director:changeScene( "creditsScreen" )
			end
		end
		
		creditsBtn = ui.newButton{
			defaultSrc = "creditsbtn.png",
			defaultX = 125,
			defaultY = 42,
			overSrc = "creditsbtn-over.png",
			overX = 125,
			overY = 42,
			onEvent = touchCreditsBtn,
			id = "creditsButton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		
		creditsBtn:setReferencePoint( display.BottomRightReferencePoint )
		creditsBtn.xOrigin = 480; creditsBtn.yOrigin = 450
		creditsBtn.isVisible = false
		
		optionsGroup:insert( creditsBtn )
		
		-- Show "Menu" Button
		menuBtn.isVisible = true
		menuBtn:setReferencePoint( display.BottomLeftReferencePoint )
		menuBtn.x = 0
		transition.to( menuBtn, { time=1000, y=320, transition=easing.inOutExpo } )
		
		-- Show "Credits" Button
		creditsBtn.isVisible = true
		creditsBtn:setReferencePoint( display.BottomRightReferencePoint )
		creditsBtn.x = 480
		transition.to( creditsBtn, { time=1000, y=320, transition=easing.inOutExpo } )
	end
	
	
	--***************************************************

	-- drawOptionButtons()
	
	--***************************************************
	
	local drawOptionButtons = function()
		
		-- Theme Selection
		themeSelector = movieclip.newAnim({ "classic-theme.png", "spook-theme.png" }, 60, 60 )
		
		local onThemeSelectorTouch = function( event )
			if event.phase == "began" then
				-- Play Sound
				if soundsOn == true then
					audio.play( tapSound )
				end
				
				
				if themeSelection == "classic" then
					themeSelection = "spook"
					themeSelector:stopAtFrame( 2 )
					
					settingsChanged = true
					
				elseif themeSelection == "spook" then
					themeSelection = "classic"
					themeSelector:stopAtFrame( 1 )
					
					settingsChanged = true
				end
				
			else
				return true
			end
		end
		
		themeSelector:addEventListener( "touch", onThemeSelectorTouch )
		
		themeSelector.x = 240; themeSelector.y = 182
		
		if themeSelection == "classic" then
			themeSelector:stopAtFrame( 1 )
		elseif themeSelection == "spook" then
			themeSelector:stopAtFrame( 2 )
		end
		
		optionsGroup:insert( themeSelector )
		
		-- Character Selection
		charSelector = movieclip.newAnim({ "charselect-d.png", "charselect-msd.png", "charselect-purplemoe.png", "charselect-greenhorn.png" }, 52, 52 )
		
		local onCharSelectorTouch = function( event )
			if event.phase == "began" then
				-- Play Sound
				if soundsOn == true then
					audio.play( tapSound )
				end
				
				if charSelection == "d" then
					charSelection = "ms. d"
					charSelector:stopAtFrame( 2 )
					
					settingsChanged = true
					
				elseif charSelection == "ms. d" then
					charSelection = "purple moe"
					charSelector:stopAtFrame( 3 )
					
					settingsChanged = true
				elseif charSelection == "purple moe" then
					charSelection = "green horn"
					charSelector:stopAtFrame( 4 )
					
					settingsChanged = true
				elseif charSelection == "green horn" then
					charSelection = "d"
					charSelector:stopAtFrame( 1 )
					
					settingsChanged = true
				end
			else
				return true
			end
		end
		
		charSelector:addEventListener( "touch", onCharSelectorTouch )
		
		charSelector.x = 110; charSelector.y = 182
		
		if charSelection == "d" then
			charSelector:stopAtFrame( 1 )
		elseif charSelection == "ms. d" then
			charSelector:stopAtFrame( 2 )
		elseif charSelection == "purple moe" then
			charSelector:stopAtFrame( 3 )
		elseif charSelection == "green horn" then
			charSelector:stopAtFrame( 4 )
		end
		
		optionsGroup:insert( charSelector )
		
		-- Tilt Sensitivity Selection
		tiltSelector = movieclip.newAnim({ "tilt-option-1.png", "tilt-option-2.png", "tilt-option-3.png", "tilt-option-4.png", "tilt-option-5.png" }, 78, 34 )
		
		local onTiltSelectorTouch = function( event )
			if event.phase == "began" then
				-- Play Sound
				if soundsOn == true then
					audio.play( tapSound )
				end
				
				if tiltSelection == "1" then
					tiltSelection = "2"
					tiltSelector:stopAtFrame( 2 )
					
					settingsChanged = true
					
				elseif tiltSelection == "2" then
					tiltSelection = "3"
					tiltSelector:stopAtFrame( 3 )
					
					settingsChanged = true
				elseif tiltSelection == "3" then
					tiltSelection = "4"
					tiltSelector:stopAtFrame( 4 )
					
					settingsChanged = true
				elseif tiltSelection == "4" then
					tiltSelection = "5"
					tiltSelector:stopAtFrame( 5 )
					
					settingsChanged = true
				elseif tiltSelection == "5" then
					tiltSelection = "1"
					tiltSelector:stopAtFrame( 1 )
					
					settingsChanged = true
				end
			else
				return true
			end
		end
		
		tiltSelector:addEventListener( "touch", onTiltSelectorTouch )
		
		tiltSelector.x = 369; tiltSelector.y = 176
		
		if tiltSelection == "1" then
			tiltSelector:stopAtFrame( 1 )
			
		elseif tiltSelection == "2" then
			tiltSelector:stopAtFrame( 2 )
		
		elseif tiltSelection == "3" then
			tiltSelector:stopAtFrame( 3 )
		
		elseif tiltSelection == "4" then
			tiltSelector:stopAtFrame( 4 )
		
		elseif tiltSelection == "5" then
			tiltSelector:stopAtFrame( 5 )
		else
			tiltSelection = "3"
			tiltSelector:stopAtFrame( 3 )
		end
		
		optionsGroup:insert( tiltSelector )
		
		-- Difficulty Selection
		diffButton = movieclip.newAnim({ "difficulty-easy.png", "difficulty-medium.png", "difficulty-hard.png" }, 162, 30 )
		
		local onDifficultyTouch = function( event )
			if event.phase == "began" then
				-- Play Sound
				if soundsOn == true then
					audio.play( tapSound )
				end
				
				if diffSelection == "0" then
					diffSelection = "2"
					diffButton:stopAtFrame( 3 )
					
					settingsChanged = true
					
				elseif diffSelection == "2" then
					diffSelection = "1"
					diffButton:stopAtFrame( 1 )
					
					settingsChanged = true
					
				elseif diffSelection == "1" then
					diffSelection = "0"
					diffButton:stopAtFrame( 2 )
					
					settingsChanged = true
				end
			else
				return true
			end
		end
		
		diffButton:addEventListener( "touch", onDifficultyTouch )
		
		diffButton.x = 240; diffButton.y = 305
		
		if diffSelection == "0" then
			diffButton:stopAtFrame( 2 )
			
		elseif diffSelection == "1" then
			diffButton:stopAtFrame( 1 )
			
		elseif diffSelection == "2" then
			diffButton:stopAtFrame( 3 )
		end
		
		optionsGroup:insert( diffButton )
		
		-- Music Mute Indicator
		muteMusic = display.newImageRect( "red-mute.png", 48, 48 )
		muteMusic.x = 204; muteMusic.y = 259
		
		if musicOn == true then
			muteMusic.isVisible = false
		elseif musicOn == false then
			muteMusic.isVisible = true
		end
		
		optionsGroup:insert( muteMusic )
		
		-- Music Sounds Indicator
		muteSounds = display.newImageRect( "red-mute.png", 48, 48 )
		muteSounds.x = 276; muteSounds.y = 259
		
		if soundsOn == true then
			muteSounds.isVisible = false
		elseif soundsOn == false then
			muteSounds.isVisible = true
		end
		
		optionsGroup:insert( muteSounds )
	end
	
	--********************************************************************

	-- muteUnmute()	--> when player presses the mute sound/music options
	
	--********************************************************************
	
	local muteUnmute = function( event )
		
		if event.phase == "began" then
			
			local xLeft, xRight, yTop, yBottom = 178, 228, 233, 283
			
			if system.getInfo("model") == "iPad" then
				xLeft = xLeft + 16
				xRight = xRight + 16
				yTop = yTop + 34
				yBottom = yBottom + 34
			end
			
			local xLeft2, xRight2, yTop2, yBottom2 = 251, 301, 233, 283
			
			if system.getInfo("model") == "iPad" then
				xLeft2 = xLeft2 + 16
				xRight2 = xRight2 + 16
				yTop2 = yTop2 + 34
				yBottom2 = yBottom2 + 34
			end
			
			-- MUSIC BUTTON
			if event.x >= xLeft and event.x <= xRight and event.y >= yTop and event.y <= yBottom then
				
				if musicOn == true then
					musicOn = false
					musicData = "no"
					settingsChanged = true
					
					muteMusic.isVisible = true
				
				elseif musicOn == false then
					musicOn = true
					musicData = "yes"
					settingsChanged = true
					
					muteMusic.isVisible = false
				
				end
				
			-- SOUNDS BUTTON
			elseif event.x >= xLeft2 and event.x <= xRight2 and event.y >= yTop2 and event.y <= yBottom2 then
				
				if soundsOn == true then
					soundsOn = false
					soundsData = "no"
					settingsChanged = true
					
					muteSounds.isVisible = true
				
				elseif soundsOn == false then
					soundsOn = true
					soundsData = "yes"
					settingsChanged = true
					
					muteSounds.isVisible = false
				end
			end
			
		else
			return true
		end
		
	end
	
	--***************************************************

	-- init()
	
	--***************************************************
	
	local init = function()
		
		-- load settings from files
		charSelection = loadValue( "char.data" )
		themeSelection = loadValue( "theme.data" )
		tiltSelection = loadValue( "tilt.data" )
		diffSelection = loadValue( "difficulty.data" )
		
		soundsData = loadValue( "sound.data" )
		musicData = loadValue( "music.data" )
		
		if charSelection == "0" then
			charSelection = "d"
			saveValue( "char.data", charSelection )
		end
		
		if themeSelection == "0" then
			themeSelection = "classic"
			saveValue( "theme.data", themeSelection )
		end
		
		if tiltSelection == "0" then
			tiltSelection = "3"
			saveValue( "tilt.data", tiltSelection )
		end
		
		if soundsData == "yes" then
			soundsOn = true
		elseif soundsData == "no" then
			soundsOn = false
		end
		
		if musicData == "yes" then
			musicOn = true
		elseif musicData == "no" then
			musicOn = false
		else
			musicOn = false
		end
		
		
		drawBackground()
		drawButtons()
		drawOptionButtons()
		
		-- start event listener for mute buttons
		Runtime:addEventListener( "touch", muteUnmute )
	end
		
	init()
	
	-- create border if on iPad
	if system.getInfo("model") == "iPad" then
		local iPadBackground = display.newImageRect( "ipadbackground.png", 512, 384 )
		iPadBackground:setReferencePoint( display.TopLeftReferencePoint )
		iPadBackground.x = -16; iPadBackground.y = -34
		
		optionsGroup.x = 16; optionsGroup.y = 34
		optionsGroup:insert( iPadBackground )
	end
	
	clean = function()
		unloadSounds()
	end
	
	-- MUST return a display.newGroup()
	return optionsGroup
end
