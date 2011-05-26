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
	local creditsGroup = display.newGroup()
	
	local backToOptions = function( event )
		if event.phase == "began" then
			
			director:changeScene( "optionsScreen" )
		end
	end
	
	local creditsBg = display.newImageRect( "creditsbg.png", 480, 320 )
	creditsBg.x = 240; creditsBg.y = 160
	
	creditsGroup:insert( creditsBg )
	
	creditsBg:addEventListener( "touch", backToOptions )
	
	-- MUST return a display.newGroup()
	return creditsGroup
end
