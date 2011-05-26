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
	local localGroup = display.newGroup()
	
	local gotoMainGame = function()
		director:changeScene( "maingame" )
	end
	
	local theTimer = timer.performWithDelay( 250, gotoMainGame, 1 )
	
	-- MUST return a display.newGroup()
	return localGroup
end
