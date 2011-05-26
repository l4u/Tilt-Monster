-- 
-- Abstract: Tilt Monster sample project 
-- Designed and created by Jonathan and Biffy Beebe of Beebe Games exclusively for Ansca, Inc.
-- http://jonbeebe.net/
-- 
-- Version: 2.0.1
-- 
-- Sample code is MIT licensed, see http://developer.anscamobile.com/code/license
-- Copyright (C) 2010 ANSCA Inc. All Rights Reserved.


-- SOME INITIAL SETTINGS
display.setStatusBar( display.HiddenStatusBar ) --Hide status bar from the beginning
system.setIdleTimer( false ) -- turn off device sleeping

--
local itunesID = nil	--> set this if you want users to be able to rate your app

-- Import director class
local director = require("director")

-- Create a main group
local mainGroup = display.newGroup()

-- Main function
local function main()
	
	-- Add the group from director class
	mainGroup:insert(director.directorView)
	
	-- Initial openfeint calls (to initialize openfeint)
	--openfeint = require ("openfeint")
	--openfeint.init( "---", "---", "Your Game Name", "---" )
	
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

	-- startGame() --> self-explanatory
	
	--***************************************************
	
	local startGame = function()
		-- ask to rate the game if it's the 4th time opening the app
		local ratingData = loadValue( "rating.data" )
		
		if ratingData == "0" then
			--> file didn't exist yet, first time opening
			saveValue( "rating.data", "1" )
		
		elseif ratingData == "1" then
			--> 2nd time opening
			saveValue( "rating.data", "2" )
		
		elseif ratingData == "2" then
			--> 3rd time opening
			saveValue( "rating.data", "3" )
		
		elseif ratingData == "3" then
			--> 4th time opening; show the popup asking to rate, dismiss, or don't show again
			
			local onRatingComplete = function( event )
				if "clicked" == event.action then
					local i = event.index
					if 3 == i then
						-- Do nothing from user's perspective, make sure it doesn't show again
						saveValue( "rating.data", "10" )
						
					elseif 2 == i then
						-- Do nothing; dialog will simply dismiss
						saveValue( "rating.data", "0" )	-- reset back to 0
						
					elseif 1 == i then
						-- First, make sure dialog won't show anymore and then open app store link
						saveValue( "rating.data", "10" )
						local itmsURL = "itms-apps://ax.itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsuserReviews?type=Purple+Software&id=" .. itunesID
						system.openURL( itmsURL )
					end
				end
			end
			 
			-- Show alert with five buttons
			local ratingAlert = native.showAlert( "Will You Submit a Rating?", "", 
													{ "Rate This Game", "Remind Me Later", "No, Thanks" }, onRatingComplete )
		
		end
		
		director:changeScene( "maingame" )
	end
	
	-- Start the game off with an optimization test
	startGame()
	
	return true
end

-- Begin
main()