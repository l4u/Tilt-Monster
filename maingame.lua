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

--************************************************************************************
--************************************************************************************

-- Main function - MUST return a display.newGroup()
function new()
	local gameGroup = display.newGroup()
	
	system.setAccelerometerInterval( 73.0 )	-- default: 75.0 (30fps) or 62.0 for 60 fps
	
	-- **************************************************************************************
	-- **************************************************************************************
	-- **************************************************************************************
	-- **************************************************************************************
	
	-- SCORE DISPLAY MODULE
	
	-- **************************************************************************************
	
	
	-- Init images. This creates a map of characters to the names of their corresponding images.
	 local numbers = { 
		[string.byte("0")] = "0.png",
		[string.byte("1")] = "1.png",
		[string.byte("2")] = "2.png",
		[string.byte("3")] = "3.png",
		[string.byte("4")] = "4.png",
		[string.byte("5")] = "5.png",
		[string.byte("6")] = "6.png",
		[string.byte("7")] = "7.png",
		[string.byte("8")] = "8.png",
		[string.byte("9")] = "9.png",
		[string.byte(" ")] = "space.png",
	}
	
	-- score components
	local theScoreGroup = display.newGroup()
	local theBackground = display.newImageRect( "scorebg.png", 160, 42 )
	theBackground.x = 78; theBackground.y = 20
	local theBackgroundBorder = 10
	
	theBackground.isVisible = false
	
	theScoreGroup:insert( theBackground )
	
	local numbersGroup = display.newGroup()
	theScoreGroup:insert( numbersGroup )
	
	-- the current score
	local theScore = 0
	
	-- the location of the score image
	
	-- initialize the score
	-- 		params.x <= X location of the score
	-- 		params.y <= Y location of the score
	function init( params )
		theScoreGroup.x = params.x
		theScoreGroup.y = params.y
		setScore( 0 )
	end
	
	-- retrieve score panel info
	--		result.x <= current panel x
	--		result.y <= current panel y
	--		result.xmax <= current panel x max
	--		result.ymax <= current panel y max
	--		result.stageWidth <= panel width
	--		result.stageHeight <= panel height
	--		result.score <= current score
	function getInfo()
		return {
			x = theScoreGroup.x,
			y = theScoreGroup.y,
			xmax = theScoreGroup.x + theScoreGroup.contentWidth,
			ymax = theScoreGroup.y + theScoreGroup.contentHeight,
			stageWidth = theScoreGroup.contentWidth,
			stageHeight = theScoreGroup.contentHeight,
			score = theScore
		}
	end
	
	-- update display of the current score.
	-- this is called by setScore, so normally this should not be called
	function update()
		-- remove old numerals
		theScoreGroup:remove(2)
	
		local numbersGroup = display.newGroup()
		theScoreGroup:insert( numbersGroup )
	
		-- go through the score, right to left
		local scoreStr = tostring( theScore )
	
		local scoreLen = string.len( scoreStr )
		local i = scoreLen	
	
		-- starting location is on the right. notice the digits will be centered on the background
		local x = theScoreGroup.contentWidth - theBackgroundBorder
		local y = theScoreGroup.contentHeight / 2
		
		while i > 0 do
			-- fetch the digit
			local c = string.byte( scoreStr, i )
			local digitPath = numbers[c]
			--local characterImage = display.newImage( digitPath )
			local characterImage = display.newImageRect( digitPath, 22, 32 )
	
			-- put it in the score group
			numbersGroup:insert( characterImage )
			
			-- place the digit
			characterImage.x = x - characterImage.width / 2
			characterImage.y = y
			x = x - characterImage.width
	
			-- 
			i = i - 1
		end
	end
	
	-- get current score
	function getScore()
		return theScore
	end
	
	-- set score to value
	--	score <= score value
	function setScore( score )
		theScore = score
		
		update()
	end
	
	-- **************************************************************************************
	-- END SCORE MODULE
	-- **************************************************************************************
	-- **************************************************************************************
	-- **************************************************************************************
	-- **************************************************************************************
	
	-- REQUIRED EXTERNAL LIBRARIES
	math.randomseed(os.time())	--> make random more random
	local movieclip = require ("movieclip")	
	local mRandom = math.random
	local physics = require "physics"
	local ui = require("ui")
	--local facebook = require "facebook"
	local json = require("json")
	
	local function printTable( t, label, level )
		if label then print( label ) end
		level = level or 1
	
		if t then
			for k,v in pairs( t ) do
				local prefix = ""
				for i=1,level do
					prefix = prefix .. "\t"
				end
	
				print( prefix .. "[" .. tostring(k) .. "] = " .. tostring(v) )
				if type( v ) == "table" then
					print( prefix .. "{" )
					printTable( v, nil, level + 1 )
					print( prefix .. "}" )
				end
			end
		end
	end
	
	---- Check if running on device or simulator ----
	local onDevice = false
	
	if system.getInfo( "environment" ) == "device" then
		onDevice = true
	else
		onDevice = false
	end
	
	-- GAME SETTINGS
	local deviceiPad = false
	local gameIsActive = false
	local menuIsActive = false
	local newHighScore = false
	local gameLives = 2
	local gemCombo = 0
	local gemCount = 0
	local highestCombo = 0
	local treeCycle = 1
	local pickupCycle = 1
	local starCycle = 1
	local bigEnemyCycle = 1
	local pondCycle = 1
	local checkPointCycle = 1
	local cpCount = 0
	local starCount = 0
	local orientationDirection = "landscapeRight"
	
	local gameSettings = {
		shouldOptimize = false,
		gameTheme = "spook",		--> classic, spook, disco, underwater
		gameChar = "ms. d",				--> d, ms. d
		tiltSpeed = "3",
		defaultMoveSpeed = 7.7,		--> set to 3.7 for 60 fps; 7.7 for 30 fps
		gameMoveSpeed = 7.7,
		soundsOn = true,
		musicOn = false,
		bestScore = 0,
		lifeGems = 0,
		highCombo = 0,
		unlockedItems = 0,
		oldUnlocked = 0,
		difficulty = "easy"			--> "easy", "medium", "hard"
	}
	
	-- FOR OPENFEINT ACHIEVEMENTS
	local ofAch = {
		score_10k = false,
		score_20k = false,
		score_50k = false,
		score_70k = false,
		combo_5 = false,
		combo_15 = false,
		combo_25 = false,
		combo_30 = false,
		combo_40 = false,
		combo_50 = false,
		combo_60 = false,
		gems_1k = false,
		gems_5k = false,
		gems_10k = false,
		gems_15k = false,
		gems_25k = false,
		gems_35k = false,
		gem_king = false,
		zero_hero = false,
		under_achiever = false,
		gem_hater = false,
		slacker = false,
		super_slacker = false,
		heart_saver = false,
		stingy_heart = false,
		life_preserver = false,
		fifteen_stars = false,
		star_struck = false
	}
	
	-- RANDOM TABLES
	local randomBunnyLocations = {}
	local bunnyIndice = 1; local maxBunnyIndice = 20
	local randomGemLocations = {}
	local gemIndice = 1; local maxGemIndice = 15
	
	local random1to4Table = {}
	local oneFourIndice = 1; local maxOneFourIndice = 20
	
	-- OBJECTS
	local playerObject
	local electroBubble
	local gemObject1
	local gemObject2
	local treeObjects = { }
	local starObject; local starSpawnRate = 3
	local pickupObject; local pickupSpawnRate = 6
	local checkPointObject; local checkPointSpawnRate = 13
	local grassBlade1; local grassBlade2; local grassBlade3
	
	-- ENEMY OBJECTS
	local flyingBunny1
	local flyingBunny2
	local flyingBunny3
	local bombObject1
	local bigEnemy; local bigEnemySpawnRate = 3
	local pondObject; local pondSpawnRate = 3
	
	-- HUD OBJECTS
	local comboIcon
	local comboText
	local comboBackground
	local notificationText
	local notificationBanner
	local heartBackground
	local heartLeft
	local heartRight
	local damageRect
	local pickupRect
	local pauseOverlay
	local lockedFire
	local lockedInvisible
	local lockedElectro
	local lockedHeart
	local bestScoreText
	local gemScoreText
	local gemScoreBg
	local gameOverScoreText
	local gameOverScoreBanner
	local gameOverShade
	local highScoreMarker
	local ofBtn
	local fbBtn
	local tryAgainBtn
	local menuBtn
	local quickStartBanner	--> quick start menu image
	local playNowBtn	--> quick start menu button
	local themesBtn		--> quick start menu button
	local helpBtn		--> quick start menu button
	--local tournamentBtn	--> quick start menu button
	local floatingText
	local floatingTextStar
	
	-- COLLISION FILTERS
	local playerFilter = { categoryBits = 2, maskBits = 6 }		--> Mask 6 collide with 4 & 2
	local itemMonsterFilter = { categoryBits = 4, maskBits = 3 }	--> Mask 3 collide with 2 & 1
	
	-- SOUNDS
	local pickupSound = audio.loadSound( "pickup.caf" )
	local gemSound = audio.loadSound( "gem.caf" )
	local tapSound = audio.loadSound( "tapsound.caf" )
	local hurtSound = audio.loadSound( "hurtsound.caf" )
	local bombSound = audio.loadSound( "bomb.caf" )
	local gameOverSound = audio.loadSound( "gameover.caf" )
	local checkPointSound = audio.loadSound( "checkpoint.caf" )
	
	local musicChan
	local gameMusic1 = audio.loadStream( "gamemusic1.mp3" )		--> menu music
	local gameMusic2 = audio.loadStream( "gamemusic2.mp3" )		--> cool halloween music
	local gameMusic3 = audio.loadStream( "gamemusic3.mp3" )		--> doodle dash music
	
	local runningSound = audio.loadStream( "footsteps.mp3" )	--> running (sound effect, play as music)
	
	-- set default master volume
	audio.setVolume( 1.0 )
	
	--***************************************************
	
	-- unloadSoundsAndMusic()
	
	--***************************************************
	
	local unloadSoundsAndMusic = function()
		
		audio.stop()
		
		audio.dispose( pickupSound )
			pickupSound = nil
		audio.dispose( gemSound )
			gemSound = nil
		audio.dispose( tapSound )
			tapSound = nil
		audio.dispose( hurtSound )
			hurtSound = nil
		audio.dispose( bombSound )
			bombSound = nil
		audio.dispose( gameOverSound )
			gameOverSound = nil
		audio.dispose( checkPointSound )
			checkPointSound = nil
		
		audio.dispose( gameMusic1 )
			gameMusic1 = nil
		audio.dispose( gameMusic2 )
			gameMusic2 = nil
		audio.dispose( gameMusic3 )
			gameMusic3 = nil
		audio.dispose( runningSound )
			runningSound = nil
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

	-- comma_value() --> place comma in thousands
	
	--***************************************************
	
	local comma_value = function(amount)
	  local formatted = amount
	  while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
		  break
		end
	  end
	  return formatted
	end
	
	-- ************************************************************** --
	
	--	flashAnimation() -- flash a colored rectangle onscreen
	
	-- ************************************************************** --
	
	local flashAnimation = function( flashType )
		
		if flashType == "damage" then
			
			damageRect.alpha = 1.0
			damageRect.isVisible = true
			
			local secondPickupRound = function()
				
				damageRect.alpha = 0.65
				damageRect.isVisible = true
				
				local hidedamageRect = function()
					damageRect.isVisible = false
				end
				
				transition.to( damageRect, { alpha=0, time=275, onComplete=hidedamageRect } )
			end
			
			transition.to( damageRect, { alpha=0, time=200, onComplete=secondPickupRound } )
		elseif flashType == "pickup" then
			
			pickupRect.alpha = 0.65
			pickupRect.isVisible = true
			
			local secondPickupRound = function()
				
				pickupRect.alpha = 0.65
				pickupRect.isVisible = true
				
				local hidePickupRect = function()
					pickupRect.isVisible = false
				end
				
				transition.to( pickupRect, { alpha=0, time=275, onComplete=hidePickupRect } )
			end
			
			transition.to( pickupRect, { alpha=0, time=200, onComplete=secondPickupRound } )
		end
		
	end
	
	local flashAnimationPickup = function( flashType )
		
		if flashType == "damage" then
			
			damageRect.alpha = 1
			damageRect.isVisible = true
			
			local hideDamageRect = function()
				damageRect.isVisible = false
			end
			
			transition.to( damageRect, { alpha=0, time=275, onComplete=hideDamageRect } )
		elseif flashType == "pickup" then
			
			pickupRect.alpha = 0.65
			pickupRect.isVisible = true
			
			local secondPickupRound = function()
				
				pickupRect.alpha = 0.65
				pickupRect.isVisible = true
				
				local hidePickupRect = function()
					pickupRect.isVisible = false
				end
				
				transition.to( pickupRect, { alpha=0, time=275, onComplete=hidePickupRect } )
			end
			
			transition.to( pickupRect, { alpha=0, time=200, onComplete=secondPickupRound } )
		end
	
	end
	-- ************************************************************** --
	
	--	onTilt() -- Accelerometer Code for Player Movement
	
	-- ************************************************************** --
	
	local onTilt = function( event )
		if gameIsActive then
			
			if playerObject.x <= 0 then
				playerObject.x = 479
			elseif playerObject.x >= 480 then
				playerObject.x = 1
			end
			
			playerObject.x = playerObject.x - (playerObject.speed * event.yGravity)
		end
	end
	
	-- ************************************************************** --
	
	--	dropNotification() -- drop down notification message from top
	
	-- ************************************************************** --
	
	local dropNotification = function( strMessage )
		
		local theMessage = strMessage
		
		notificationText.text = theMessage
		notificationText:setReferencePoint( display.CenterLeftReferencePoint )
		notificationText.x = 34
		notificationText.isVisible = true
		
		notificationBanner:setReferencePoint( display.TopLeftReferencePoint )
		notificationBanner.x = 0
		notificationBanner.isVisible = true
		
		local startHideTimer = function()
			local hideNotification = function()
				local hideBannerAndText = function()
					notificationText.isVisible = false
					notificationBanner.isVisible = false
				end
				
				transition.to( notificationText, { time=1000, y=-18, transition=easing.inOutExpo, onComplete=hideBannerAndText })
				transition.to( notificationBanner, { time=1000, y=-32, transition=easing.inOutExpo })
			end
			
			local hideTimer = timer.performWithDelay( 2000, hideNotification, 1 )
		end
		
		transition.to( notificationBanner, { time=1000, y=0, transition=easing.inOutExpo, onComplete=startHideTimer })
		transition.to( notificationText, { time=1000, y=16, transition=easing.inOutExpo })
		
	end
	
	-- ************************************************************** --
	
	--	touchPause() -- pause/unpause the game
	
	-- ************************************************************** --
	
	local touchPause = function( event )
		
		if event.phase == "began" then
			if event.x > 50 and event.x < 430 and event.y > 50 and event.y < 270 then
				if gameIsActive then
					-- Pause the game
					gameIsActive = false
					system.setIdleTimer( true ) -- turn on device sleeping
					Runtime:removeEventListener( "accelerometer", onTilt )
					
					-- START PAUSE SCREEN
					
					-- Pause Overlay
					pauseOverlay = display.newImageRect( "pauseoverlay.png", 440, 277 )
					pauseOverlay.x = 240; pauseOverlay.y = 160
					pauseOverlay.isVisible = true
					
					-- Locked items
					lockedFire = display.newImageRect( "locked-pickup.png", 30, 30 )
					lockedFire.x = 120; lockedFire.y = 209
					lockedFire.isVisible = false
					
					lockedInvisible = display.newImageRect( "locked-pickup.png", 30, 30 )
					lockedInvisible.x = 273; lockedInvisible.y = 209
					lockedInvisible.isVisible = false
					
					lockedElectro = display.newImageRect( "locked-pickup.png", 30, 30 )
					lockedElectro.x = 120; lockedElectro.y = 250
					lockedElectro.isVisible = false
					
					lockedHeart = display.newImageRect( "locked-pickup.png", 30, 30 )
					lockedHeart.x = 273; lockedHeart.y = 252
					lockedHeart.isVisible = false
					
					gameGroup:insert( pauseOverlay )
					gameGroup:insert( lockedFire )
					gameGroup:insert( lockedInvisible )
					gameGroup:insert( lockedElectro )
					gameGroup:insert( lockedHeart )
					
					-- END PAUSE SCREEN
					
					local unlockedItems = tonumber(gameSettings["unlockedItems"])
					print( tostring(unlockedItems) )
					
					if unlockedItems == 4 then
						lockedHeart.isVisible = false
					elseif unlockedItems == 3 then
						lockedHeart.isVisible = true
					elseif unlockedItems == 2 then
						lockedElectro.isVisible = true
						lockedHeart.isVisible = true
					elseif unlockedItems == 1 then
						lockedInvisible.isVisible = true
						lockedElectro.isVisible = true
						lockedHeart.isVisible = true
					elseif unlockedItems == 0 then
						lockedFire.isVisible = true
						lockedInvisible.isVisible = true
						lockedElectro.isVisible = true
						lockedHeart.isVisible = true
					end
					
					physics.pause()
					
					local musicOn = gameSettings[ "musicOn" ]
					local soundsOn = gameSettings[ "soundsOn" ]
					
					if musicOn then
						audio.setVolume( 0, { channel=musicChan } )	--> OpenAL
					end
					
					if soundsOn then
						audio.setVolume( 0 )
					end
				else
					-- Unpause the game
					system.setIdleTimer( false ) -- turn off device sleeping
					gameIsActive = true
					Runtime:removeEventListener( "accelerometer", onTilt )
					Runtime:addEventListener( "accelerometer", onTilt )
					
					if pauseOverlay then
						pauseOverlay.isVisible = false;
						display.remove( pauseOverlay )
						pauseOverlay = nil
					end
					
					if lockedFire.isVisible == true then lockedFire.isVisible = false; display.remove( lockedFire ); lockedFire = nil; end
					if lockedInvisible.isVisible == true then lockedInvisible.isVisible = false; display.remove( lockedInvisible ); lockedInvisible = nil; end
					if lockedElectro.isVisible == true then lockedElectro.isVisible = false; display.remove( lockedElectro ); lockedElectro = nil; end
					if lockedHeart.isVisible == true then lockedHeart.isVisible = false; display.remove( lockedHeart ); lockedHeart = nil; end
					
					physics.start( true )
					
					local musicOn = gameSettings[ "musicOn" ]
					local soundsOn = gameSettings[ "soundsOn" ]
					
					if musicOn then
						audio.setVolume( 0.5, { channel=musicChan } )		--> OpenAL
					end
					
					if soundsOn then
						audio.setVolume( 1.0 )
					end
				end
			end
		end
	end
	
	-- ************************************************************** --
	
	--	onSystem() -- listener for system events
	
	-- ************************************************************** --
	
	local onSystem = function( event )
		if event.type == "applicationSuspend" then
			if gameIsActive then
				-- Pause the game
				gameIsActive = false
				system.setIdleTimer( true ) -- turn on device sleeping
				Runtime:removeEventListener( "accelerometer", onTilt )
				
				-- START PAUSE SCREEN
					
				-- Pause Overlay
				pauseOverlay = display.newImageRect( "pauseoverlay.png", 440, 277 )
				pauseOverlay.x = 240; pauseOverlay.y = 160
				pauseOverlay.isVisible = true
				
				-- Locked items
				lockedFire = display.newImageRect( "locked-pickup.png", 30, 30 )
				lockedFire.x = 120; lockedFire.y = 209
				lockedFire.isVisible = false
				
				lockedInvisible = display.newImageRect( "locked-pickup.png", 30, 30 )
				lockedInvisible.x = 273; lockedInvisible.y = 209
				lockedInvisible.isVisible = false
				
				lockedElectro = display.newImageRect( "locked-pickup.png", 30, 30 )
				lockedElectro.x = 120; lockedElectro.y = 250
				lockedElectro.isVisible = false
				
				lockedHeart = display.newImageRect( "locked-pickup.png", 30, 30 )
				lockedHeart.x = 273; lockedHeart.y = 252
				lockedHeart.isVisible = false
				
				gameGroup:insert( pauseOverlay )
				gameGroup:insert( lockedFire )
				gameGroup:insert( lockedInvisible )
				gameGroup:insert( lockedElectro )
				gameGroup:insert( lockedHeart )
				
				-- END PAUSE SCREEN
				
				
				local unlockedItems = tonumber(gameSettings["unlockedItems"])
					
				if unlockedItems == 4 then
					lockedHeart.isVisible = false
				elseif unlockedItems == 3 then
					lockedHeart.isVisible = true
				elseif unlockedItems == 2 then
					lockedElectro.isVisible = true
					lockedHeart.isVisible = true
				elseif unlockedItems == 1 then
					lockedInvisible.isVisible = true
					lockedElectro.isVisible = true
					lockedHeart.isVisible = true
				elseif unlockedItems == 0 then
					lockedFire.isVisible = true
					lockedInvisible.isVisible = true
					lockedElectro.isVisible = true
					lockedHeart.isVisible = true
				end
				
				physics.pause()
				
				local musicOn = gameSettings[ "musicOn" ]
				
				if musicOn then
					audio.setVolume( 0, { channel=musicChan } )	--> OpenAL
				end
			end
		elseif event.type == "applicationExit" then
			-- save some data
			
			if onDevice == true then
				-- and then quit the game
				os.exit()
			end
		end
	end
	
	-- ************************************************************** --
	
	-- recycleRound() -- Start a new round (not the first!)
	
	-- ************************************************************** --
	
	local hideGameOverScreenObjects = function()
		-- Fade out the game over shade
		if gameOverShade then
			transition.to( gameOverShade, { time=500, alpha=0 } )
		end
		
		local hideGameOverScoreBanner = function()
			gameOverScoreBanner.isVisible = false
			gemScoreBg.isVisible = false
		end
		
		if gameOverScoreBanner then
			transition.to( gameOverScoreBanner, { x=720, time=1000, transition=easing.inOutExpo, onComplete=hideGameOverScoreBanner } )
		end
		
		local hideQuickStartBanner = function()
			quickStartBanner.isVisible = false
			--quickStartBanner:removeSelf()
			display.remove( quickStartBanner )
			quickStartBanner = nil
		end
		
		if quickStartBanner then
			transition.to( quickStartBanner, { x=720, time=1000, transition=easing.inOutExpo, onComplete=hideQuickStartBanner } )
		end
		
		if gemScoreBg then
			transition.to( gemScoreBg, { y=-52, time=1000, transition=easing.inOutExpo } )
		end
		
		if gemScoreText then
			gemScoreText.isVisible = false
		end
		
		if gameOverScoreText then
			gameOverScoreText.isVisible = false
		end
		
		if highScoreMarker then
			highScoreMarker.isVisible = false
		end
		
		if tryAgainBtn then
			local dropTryAgainButton = function()
				local hideTryAgain = function() tryAgainBtn.isVisible = false; tryAgainBtn.isActive = true; end
				transition.to( tryAgainBtn, { y=600, time=1000, transition=easing.inOutExpo, onComplete=hideTryAgain } )
			end
			local newTryAgainY = tryAgainBtn.y - 10
			transition.to( tryAgainBtn, { y=newTryAgainY, time=200, onComplete=dropTryAgainButton } )
		end
		
		if playNowBtn then
			local dropPlayNowButton = function()
				local hidePlayNow = function() playNowBtn.isVisible = false; display.remove( playNowBtn ); playNowBtn = nil; end
				transition.to( playNowBtn, { y=600, time=1000, transition=easing.inOutExpo, onComplete=hidePlayNow } )
			end
			
			local newPlayNowY = playNowBtn.y - 10
			transition.to( playNowBtn, { y=newPlayNowY, time=200, onComplete=dropPlayNowButton } )
		end
		
		if ofBtn then
			local hideOfBtn = function() ofBtn.isVisible = false; end
			transition.to( ofBtn, { y=625, time=1000, transition=easing.inOutExpo, onComplete=hideOfBtn } )
		end
		
		if fbBtn then
			local hideFbBtn = function() fbBtn.isVisible = false; end
			transition.to( fbBtn, { y=625, time=1000, transition=easing.inOutExpo, onComplete=hideFbBtn } )
		end
		
		if themesBtn then
			local hideThemesBtn = function() themesBtn.isVisible = false; display.remove( themesBtn ); themesBtn = nil; end
			transition.to( themesBtn, { y=625, time=1000, transition=easing.inOutExpo, onComplete=hideThemesBtn } )
		end
		
		if helpBtn then
			local hideHelpBtn = function() helpBtn.isVisible = false; display.remove( helpBtn ); helpBtn = nil; end
			transition.to( helpBtn, { y=450, time=1000, transition=easing.inOutExpo, onComplete=hideHelpBtn } )
		end
		
		--[[
		if tournamentBtn then
			local hideTournamentBtn = function() tournamentBtn.isVisible = false; tournamentBtn:removeSelf(); tournamentBtn = nil; end
			transition.to( tournamentBtn, { y=450, time=1000, transition=easing.inOutExpo, onComplete=hideTournamentBtn } )
		end
		]]--
		
		if menuBtn then
			local hideMenuBtn = function() menuBtn.isVisible = false; end
			transition.to( menuBtn, { y=450, time=1000, onComplete=hideMenuBtn } )
		end
		
		
		-- Reshow on-screen hud elements
		theScoreGroup.isVisible = true
		heartBackground.isVisible = true
		heartLeft.isVisible = true
		heartRight.isVisible = true
		bestScoreText.text = comma_value(gameSettings[ "bestScore" ])
		--bestScoreText:setReferencePoint( display.CenterLeftReferencePoint )
		--bestScoreText.x = 25
		bestScoreText.xScale = 0.5; bestScoreText.yScale = 0.5
		bestScoreText.x = (bestScoreText.contentWidth / 2) + 25; bestScoreText.y = 10
	end
	
	local recycleRound = function()
		
		--First, make sure accelerometer events are turned off (so they don't get turned on double time)
		Runtime:removeEventListener( "accelerometer", onTilt )
		
		-- First, reset the score and game lives
		--frameCounter = 1
		setScore( 0 )
		gemCombo = 0
		gemCount = 0
		highestCombo = 0
		treeCycle = 1
		pickupCycle = 1
		checkPointCycle = 1
		cpCount = 0
		starCount = 0
		starCycle = 1
		bigEnemyCycle = 1
		pondCycle = 1
		newHighScore = false
		gameLives = 2; heartLeft.alpha = 1
		gameSettings["gameMoveSpeed"] = gameSettings["defaultMoveSpeed"]
		gameSettings[ "oldUnlocked" ] = gameSettings[ "unlockedItems" ]
		
		-- reset openfeint achievement stuff
		ofAch = {
			score_10k = false,
			score_20k = false,
			score_50k = false,
			score_70k = false,
			combo_5 = false,
			combo_15 = false,
			combo_25 = false,
			combo_30 = false,
			combo_40 = false,
			combo_50 = false,
			combo_60 = false,
			gems_1k = false,
			gems_5k = false,
			gems_10k = false,
			gems_15k = false,
			gems_25k = false,
			gems_35k = false,
			gem_king = false,
			zero_hero = false,
			under_achiever = false,
			gem_hater = false,
			slacker = false,
			super_slacker = false,
			heart_saver = false,
			stingy_heart = false,
			life_preserver = false,
			fifteen_stars = false,
			star_struck = false
		}
		
		-- make sure best score is back to black
		local gameTheme = gameSettings["gameTheme"]
		
		if gameTheme == "spook" then
			bestScoreText:setTextColor( 255, 255, 255, 255 )
		else
			bestScoreText:setTextColor( 0, 0, 0, 255)
		end
		
		-- Populate random tables
		for i = 1, maxBunnyIndice do
			randomBunnyLocations[i] = mRandom( 1, 479 )
		end
		
		for i = 1, maxGemIndice do
			randomGemLocations[i] = mRandom( 70, 410 )
		end
		
		for i = 1, maxOneFourIndice do
			random1to4Table[i] = mRandom( 1, 4 )
		end
		
		-- Reset trees
		treeObjects["left1"].x = 0 + (treeObjects["left1"].width / 2)
		treeObjects["left1"].y = (display.contentHeight) / 2 - 128
		treeObjects["left2"].x = treeObjects["left1"].x
		treeObjects["left2"].y = treeObjects["left1"].y + treeObjects["left1"].height + 100
		
		treeObjects["right1"].x = 480 - (treeObjects["right1"].width / 2)
		treeObjects["right1"].y = (display.contentHeight / 2) - 32
		treeObjects["right2"].x = treeObjects["right1"].x
		treeObjects["right2"].y = treeObjects["right1"].y + treeObjects["right1"].height + 100
		
		-- Reset player settings
		playerObject.x = 240
		playerObject.y = 125
		playerObject.framePosition = "left"
		playerObject.alpha = 1
		playerObject.isVisible = true
		playerObject.animInterval = 150
		playerObject.isInvisible = false
		playerObject.invisibleCycle = 1
		playerObject.isElectro = false
		playerObject.alpha = 1.0
		playerObject.isBodyActive = true
		
		-- set player speed multiplier based on tilt sensitivity (tiltSpeed)
		local tiltSpeed = gameSettings["tiltSpeed"]
		
		if tiltSpeed == "1" then
			playerObject.speed = 19
			
		elseif tiltSpeed == "2" then
			playerObject.speed = 22
			
		elseif tiltSpeed == "3" then
			playerObject.speed = 25
			
		elseif tiltSpeed == "4" then
			playerObject.speed = 32
			
		elseif tiltSpeed == "5" then
			playerObject.speed = 37
			
		else
			playerObject.speed = 25
		
		end
		
		-- Reset gems
		gemObject1.x = randomGemLocations[gemIndice]
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		gemObject1.y = 420
		gemObject2.x = randomGemLocations[gemIndice]
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		gemObject2.y = 620
		
		gemObject1.isVisible = true; gemObject1.alpha = 1.0; gemObject1.isBodyActive = true
		gemObject2.isVisible = true; gemObject2.alpha = 1.0; gemObject2.isBodyActive = true
		
		-- Reset grass
		grassBlade1.x = randomGemLocations[gemIndice]
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		grassBlade1.y = 350
		
		grassBlade2.x = randomGemLocations[gemIndice]
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		grassBlade2.y = 500
		
		grassBlade3.x = randomGemLocations[gemIndice]
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		grassBlade3.y = 650
		
		grassBlade1.isVisible = true
		grassBlade2.isVisible = true
		grassBlade3.isVisible = true
		
		-- Reset pickup object
		pickupObject.x = randomGemLocations[gemIndice];
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		
		pickupObject.y = 520
		pickupObject.onTheMove = false
		pickupObject.isVisible = false
		pickupObject.isBodyActive = false
		electroBubble.isVisible = false
		
		-- Reset checkpoint object
		checkPointObject.x = 240
		checkPointObject.y = 600
		checkPointObject.onTheMove = false
		checkPointObject.isVisible = false
		checkPointObject.isBodyActive = false
		
		-- Reset star object
		starObject.x = randomGemLocations[gemIndice];
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		
		starObject.y = 720
		starObject.onTheMove = false
		starObject.isVisible = false
		starObject.isBodyActive = false
		
		-- Reset bunnies
		flyingBunny1.x = randomBunnyLocations[bunnyIndice]
		bunnyIndice = bunnyIndice + 1
		if bunnyIndice > maxBunnyIndice then
			bunnyIndice = 1
		end
		flyingBunny1.y = 500
		
		flyingBunny2.x = randomBunnyLocations[bunnyIndice]
		bunnyIndice = bunnyIndice + 1
		if bunnyIndice > maxBunnyIndice then
			bunnyIndice = 1
		end
		
		flyingBunny2.y = 800
		
		if gameSettings[ "difficulty" ] ~= "easy" then
			flyingBunny3.x = randomBunnyLocations[bunnyIndice]
			bunnyIndice = bunnyIndice + 1
			if bunnyIndice > maxBunnyIndice then
				bunnyIndice = 1
			end
		
			flyingBunny3.y = 950
		end
		
		flyingBunny1.isVisible = true; flyingBunny1.isBodyActive = true
		flyingBunny2.isVisible = true; flyingBunny2.isBodyActive = true
		flyingBunny1.selfSpeed = 0.5; flyingBunny2.selfSpeed = 0.5
		
		if gameSettings[ "difficulty" ] ~= "easy" then
			flyingBunny3.isVisible = true; flyingBunny3.isBodyActive = true; flyingBunny3.selfSpeed = 0.5
		end
		
		-- Reset bombs
		bombObject1.x = randomGemLocations[gemIndice]
		gemIndice = gemIndice + 1;
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		bombObject1.y = 650
		
		bombObject1.isVisible = true; bombObject1.isBodyActive = true;
		
		-- Reset big enemy
		bigEnemy.x = randomBunnyLocations[bunnyIndice];
		bunnyIndice = bunnyIndice + 1
		if bunnyIndice > maxBunnyIndice then
			bunnyIndice = 1
		end
		
		bigEnemy.y = 900
		bigEnemy.onTheMove = false
		bigEnemy.isVisible = false
		bigEnemy.isBodyActive = false
		bigEnemy.isDestroyed = false
		
		-- Reset green pond
		pondObject.x = randomBunnyLocations[bunnyIndice];
		bunnyIndice = bunnyIndice + 1
		if bunnyIndice > maxBunnyIndice then
			bunnyIndice = 1
		end
		
		pondObject.y = 500
		pondObject.onTheMove = false
		pondObject.isVisible = false
		pondObject.isBodyActive = false
		pondObject.isDestroyed = false
		
		
		-- Remove/hide Game Over Screen Objects
		
		hideGameOverScreenObjects()
		
		--collectgarbage( "collect" )
		timer.performWithDelay(1, function() collectgarbage("collect") end)
		
		-- Start the new round
		system.setIdleTimer( false ) -- turn off device sleeping
		
		local startNewRound = function() menuIsActive = false; gameIsActive = true; physics.start(); end
		
		local startGameInOne = timer.performWithDelay( 500, startNewRound, 1 )
		
		Runtime:addEventListener( "accelerometer", onTilt )
		Runtime:addEventListener( "touch", touchPause )
		
		playerObject.isVisible = true
	end
	
	-- ************************************************************** --
	
	-- connectHandler (for facebook posting)
	
	-- ************************************************************** --
	
	local function connectHandler( event )
		local post = "Playing Tilt Monster -- Getting Addicted!"
		local gameScore = getScore()
		gameScore = comma_value(gameScore)
		
		local session = event.sender
		if ( session:isLoggedIn() ) then
	
			print( "fbStatus " .. session.sessionKey )
			
			local scoreStatusMessage = "just scored a " .. tostring(gameScore) .. " on Tilt Monster... I'm officially addicted."
			
			local attachment = {
				name="Download Tilt Monster To Compete With Me",
				caption="Think you can beat my score of " .. tostring(gameScore) .. "? I dare you to try!",
				href="http://---LINK-TO-YOUR-ITUNES-APP",
				media= { { type="image", src="http://---LINK-TO-YOUR-90x90-ICON", href="---LINK-TO-YOUR-ITUNES-APP" } }
			}
	
			local action_links = {
				{ text="Download Tilt Monster", href="http://beebegamesonline.appspot.com/tiltmonster-itunes.html" }
			}
	
			local response = session:call{
				message = scoreStatusMessage,
				method ="stream.publish",
				attachment = json.encode(attachment),
				action_links = json.encode(action_links),
			}
	
			if "table" == type(response ) then
				-- print contents of response upon failure
				printTable( response, "fbStatus response:", 5 )
			end
			
			local onComplete = function ( event )
				if "clicked" == event.action then
					local i = event.index
					if 1 == i then
						-- Player click 'Ok'; do nothing, just exit the dialog
					end
				end
			end
			
			-- Show alert with two buttons
			local alert = native.showAlert( "Tilt Monster", "Your score has been posted to Facebook.", 
													{ "Ok" }, onComplete )
		end
	end
	
	
	-- **************************************************************
	
	-- drawGameOverScreen()
	
	-- **************************************************************
	
	local drawGameOverScreen = function()
		
		-- Draw game over shade
		if not gameOverShade then
			gameOverShade = display.newImageRect( "gameovershade.png", 480, 320 )		--> "gameovershade.png", 480, 320
			gameOverShade.x = 240; gameOverShade.y = 160
			gameOverShade.isVisible = false; gameOverShade.alpha = 0
			
			gameGroup:insert( gameOverShade )
		end
		
		-- Draw banner that gem score will show up on
		if not gemScoreBg then
			gemScoreBg = display.newImageRect( "gemscorebg.png", 284, 48 )
			gemScoreBg.x = -52; gemScoreBg.x = 240
			gemScoreBg.isVisible = false
			
			gameGroup:insert( gemScoreBg )
		end
		
		
		-- Draw banner that final score will show up on
		if not gameOverScoreBanner then
			gameOverScoreBanner = display.newImageRect( "highscorebanner.png", 480, 84 )
			gameOverScoreBanner.x = 720; gameOverScoreBanner.y = 94
			gameOverScoreBanner.isVisible = false
			
			gameGroup:insert( gameOverScoreBanner )
		end
		
		-- Draw high score marker that will show up if player beats their previous high score
		if not highScoreMarker then
			highScoreMarker = display.newImageRect( "highscoremarker.png", 50, 50 )
			highScoreMarker.x = 444; highScoreMarker.y = 88
			highScoreMarker.isVisible = false
		
			gameGroup:insert( highScoreMarker )
		end
		
		-- Draw gem score text with empty value
		if not gemScoreText then
			gemScoreText = display.newText( "High Gem Combo: ", 240, -52, "Helvetica-Bold", 30 )
			gemScoreText:setTextColor( 220, 220, 220, 255 )
			gemScoreText.xScale = 0.5; gemScoreText.yScale = 0.5
			gemScoreText.x = 240; gemScoreText.y = -52
			gemScoreText.isVisible = false
			
			gameGroup:insert( gemScoreText )
		end
		
		-- Draw high score text with temporary score
		if not gameOverScoreText then
			gameOverScoreText = display.newText( "1,000", 240, 93, "Helvetica-Bold", 76 )
			gameOverScoreText:setTextColor( 255, 255, 255, 255 )
			gameOverScoreText.xScale = 0.5; gameOverScoreText.yScale = 0.5
			gameOverScoreText.x = 240; gameOverScoreText.y = 93
			gameOverScoreText.isVisible = false
			
			gameGroup:insert( gameOverScoreText )
		end
		
		-- Setup "Try Again" Button
		local touchTryAgainBtn = function( event )
			if event.phase == "release" and tryAgainBtn.isActive == true then
				
				tryAgainBtn.isActive = false
				
				-- Play Sound
				local soundsOn = gameSettings[ "soundsOn" ]
				
				if soundsOn == true then
					local freeChan = audio.findFreeChannel()
					audio.play( tapSound, { channel=freeChan } )
					
					local freeChan2 = audio.findFreeChannel()
					audio.play( runningSound, { loops=-1, channel=freeChan2 } )
				end
				
				recycleRound()
			end
		end
		
		if not tryAgainBtn then
			tryAgainBtn = ui.newButton{
				defaultSrc = "tryagain.png",
				defaultX = 155,
				defaultY = 59,
				overSrc = "tryagain-over.png",
				overX = 155,
				overY = 59,
				onEvent = touchTryAgainBtn,
				id = "tryAgainButton",
				text = "",
				font = "Helvetica",
				textColor = { 255, 255, 255, 255 },
				size = 16,
				emboss = false
			}
			
			tryAgainBtn.xOrigin = 240; tryAgainBtn.yOrigin = 600
			tryAgainBtn.isVisible = false
			
			gameGroup:insert( tryAgainBtn )
		end
		
		if ofBtn then gameGroup:insert( ofBtn ); end
		
		-- Setup "Facebook" Button
		local touchFBBtn = function( event )
			if event.phase == "release" then
				
				-- BELOW IS AN EXAMPLE OF HOW TO GET FACEBOOK SCORE POSTING TO WORK:
				
				--[[
				-- Play Sound
				local soundsOn = gameSettings[ "soundsOn" ]
				
				if soundsOn == true then
					local freeChan = audio.findFreeChannel()
					audio.play( tapSound, { channel=freeChan } )
				end
				
				--
				
				local facebookListener = function( event )
					if ( "session" == event.type ) then
						-- upon successful login, update their status
						if ( "login" == event.phase ) then
							
							local gameScore = getScore()
							gameScore = comma_value(gameScore)
							
							local theMessage
							
							if gameSettings[ "difficulty" ] == "easy" then
								theMessage = "just scored a " .. gameScore .. " on Tilt Monster (Easy Mode)."
							
							elseif gameSettings[ "difficulty" ] == "medium" then
								theMessage = "just scored a " .. gameScore .. " on Tilt Monster (Medium Difficulty)."
							
							elseif gameSettings[ "difficulty" ] == "hard" then
								theMessage = "just scored a " .. gameScore .. " on Tilt Monster (Hard Mode)."
							
							end
							
							facebook.request( "me/feed", "POST", {
								message=theMessage,
								name="Download Tilt Monster to Compete with Me!",
								caption="Think you can beat my score of " .. gameScore .. "? I dare you to try!",
								link="---LINK-TO-YOUR-ITUNES-APP",
								picture="---LINK-TO-YOUR-90x90-ICON" } )
						end
					end
				end
				
				-- replace "---" below with your Facebook App ID
				facebook.login( "---", facebookListener, { "publish_stream" } )
				]]--
			end
		end
		
		if not fbBtn then
			fbBtn = ui.newButton{
				defaultSrc = "facebook.png",
				defaultX = 155,
				defaultY = 59,
				overSrc = "facebook-over.png",
				overX = 155,
				overY = 59,
				onEvent = touchFBBtn,
				id = "facebookButton",
				text = "",
				font = "Helvetica",
				textColor = { 255, 255, 255, 255 },
				size = 16,
				emboss = false
			}
			
			fbBtn.xOrigin = 330; fbBtn.yOrigin = 625
			fbBtn.isVisible = false
			
			gameGroup:insert( fbBtn )
		end
		
		-- Setup "Menu" Button
		local touchMenuBtn = function( event )
			if event.phase == "release" and menuBtn.isActive == true then
				menuBtn.isActive = false
				
				-- Play Sound
				local soundsOn = gameSettings[ "soundsOn" ]
				local musicOn = gameSettings[ "musicOn" ]
				
				if soundsOn == true then
					local freeChan = audio.findFreeChannel()
					audio.play( tapSound, { channel=freeChan } )
				end
				
				if musicOn == true then
				
					if gameSettings[ "gameTheme" ] == "classic" then
						audio.stop( gameMusic3 )
					elseif gameSettings[ "gameTheme" ] == "spook" then
						audio.stop( gameMusic2 )
					end
				
				end
				
				--main menu call
				director:changeScene( "gotomainmenu" )
			end
		end
		
		if not menuBtn then
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
			
			gameGroup:insert( menuBtn )
		end
	end
	
	-- END DRAW GAME OVER SCREEN
	
	
	-- ************************************************************** --
	
	-- callGameOver() -- Display the game over display overlay
	
	-- ************************************************************** --
	
	local callGameOver = function()
		-- Pause all game movement
		if gameIsActive == true then gameIsActive = false; end
		
		physics.pause()
		Runtime:removeEventListener( "accelerometer", onTilt )
		Runtime:removeEventListener( "touch", touchPause )
		
		-- Play Game Over Sound
		local soundsOn = gameSettings[ "soundsOn" ]
		
		if soundsOn then
			-- stop running sound
			audio.stop( runningSound )
			
			local freeChan = audio.findFreeChannel()
			audio.play( gameOverSound, { channel=freeChan } )
		end
		
		system.setIdleTimer( true ) -- turn on device sleeping
		
		
		-- Hide some of the on-screen elements
		theScoreGroup.isVisible = false
		heartBackground.isVisible = false
		heartLeft.isVisible = false
		heartRight.isVisible = false
		comboText.isVisible = false
		comboIcon.isVisible = false
		comboBackground.isVisible = false
		
		-- Create Game Over Screen
		drawGameOverScreen()
		
		local showGameOverScreen = function()
			
			-- Store current score as variable
			local scoreNumber = getScore()
			scoreNumber = comma_value(scoreNumber)
			
			-- Check to see if there is a new high score, if so, save it
			local gameScore = tonumber(getScore())
			local bestScore = tonumber(gameSettings[ "bestScore" ])
			
			if gameScore > bestScore then
				gameSettings[ "bestScore" ] = tostring(gameScore)
				bestScore = gameScore
				
				if gameSettings[ "difficulty" ] ~= "easy" then
					saveValue( "TiMQGcpCZv.data", tostring(gameScore) )
				else
					saveValue( "TpjixLATIZ.data", tostring(gameScore) )
				end
				
				-- Show high score marker
				highScoreMarker.alpha = 0
				highScoreMarker.isVisible = true
				transition.to( highScoreMarker, { time=2000, alpha=1, transition=easing.inOutExpo } )
			end
			
			
			-- Update lifetime gems file
			local lifeGemsCount = tonumber(gameSettings[ "lifeGems" ])
			lifeGemsCount = lifeGemsCount + gemCount
			gameSettings[ "lifeGems" ] = tostring(lifeGemsCount)
			
			if gameSettings[ "difficulty" ] ~= "easy" then
				saveValue( "SadzCtDWmK.data", tostring(lifeGemsCount) )
			else
				saveValue( "sOfvDxAlkH.data", tostring(lifeGemsCount) )
			end
			
			-- Update highest combo file
			local bestCombo = tonumber(gameSettings[ "highCombo" ])
			
			if highestCombo > bestCombo then
				gameSettings[ "highCombo" ] = tostring(highestCombo)
				
				if gameSettings[ "difficulty" ] ~= "easy" then
					saveValue( "UVIMSPUuCb.data", tostring(highestCombo) )
				else
					saveValue( "wnpzK3g55u.data", tostring(highestCombo) )
				end
			end
			
			bestCombo = tonumber(gameSettings[ "highCombo" ])
			
			-- Update the unlocked items file
			local unlockedItems = tostring(gameSettings["unlockedItems"])
			
			if gameSettings[ "difficulty" ] ~= "easy" then
				saveValue( "nxMzUBnOeN.data", unlockedItems )
			else
				saveValue( "neiEFXdaiLIa.data", unlockedItems )
			end
			
			-- Send score, lifetime gems, and high gem combo to openfeint leaderboard servers
			
			if onDevice then
				local bestScoreDisplay = comma_value( bestScore )
				
				if gameSettings[ "difficulty" ] ~= "easy" then
					----openfeint.setHighScore( {leaderboardID="566804", score=bestScore, displayText=bestScoreDisplay } )
				else
					----openfeint.setHighScore( {leaderboardID="579234", score=bestScore, displayText=bestScoreDisplay } )
				end
				
				local bestComboText = tostring(bestCombo) .. " Gems"
				
				if gameSettings[ "difficulty" ] ~= "easy" then
					----openfeint.setHighScore( {leaderboardID="566814", score=bestCombo, displayText=bestComboText } )	--> Highest Gem Combo
				else
					----openfeint.setHighScore( {leaderboardID="579244", score=bestCombo, displayText=bestComboText } )	--> Highest Gem Combo
				end
				
				local lifeGemsText = comma_value(lifeGemsCount) .. " Gems"
				
				if gameSettings[ "difficulty" ] ~= "easy" then
					----openfeint.setHighScore( {leaderboardID="566824", score=lifeGemsCount, displayText=lifeGemsText } )	--> Total Lifetime Gems
				else
					----openfeint.setHighScore( {leaderboardID="579254", score=lifeGemsCount, displayText=lifeGemsText } )	--> Total Lifetime Gems
				end
				
				
				-- OPENFEINT ACHIEVEMENTS
				
				-- Gem Combo Achievements
				
				if ofAch[ "combo_5" ] == true then
					----openfeint.unlockAchievement( 720752 )
				end
				
				if ofAch[ "combo_15" ] == true then
					----openfeint.unlockAchievement( 720762 )
				end
				
				if ofAch[ "combo_25" ] == true then
					----openfeint.unlockAchievement( 720772 )
				end
				
				if ofAch[ "combo_30" ] == true then
					----openfeint.unlockAchievement( 720782 )
				end
				
				if ofAch[ "combo_40" ] == true then
					----openfeint.unlockAchievement( 720792 )
				end
				
				if ofAch[ "combo_50" ] == true then
					----openfeint.unlockAchievement( 720802 )
				end
				
				if ofAch[ "combo_60" ] == true then
					----openfeint.unlockAchievement( 720812 )
				end
				
				-- Lifetime Gems Achievements
				
				if lifeGemsCount >= 100000 then
					--openfeint.unlockAchievement( 720892 )
				end
				
				if lifeGemsCount >= 35000 then
					--openfeint.unlockAchievement( 720882 )
				end
				
				if lifeGemsCount >= 25000 then
					--openfeint.unlockAchievement( 720872 )
				end
				
				if lifeGemsCount >= 15000 then
					--openfeint.unlockAchievement( 720862 )
				end
				
				if lifeGemsCount >= 10000 then
					--openfeint.unlockAchievement( 720852 )
				end
				
				if lifeGemsCount >= 5000 then
					--openfeint.unlockAchievement( 720832 )
				end
				
				if lifeGemsCount >= 1000 then
					--openfeint.unlockAchievement( 720822 )
				end
				
				-- Oddball Achievements
				
				if ofAch[ "zero_hero" ] == true then
					--openfeint.unlockAchievement( 720902 )
				end
					
				if ofAch[ "under_achiever" ] == true then
					--openfeint.unlockAchievement( 720912 )
				end
				
				if ofAch[ "gem_hater" ] == true then
					--openfeint.unlockAchievement( 720922 )
				end
				
				if ofAch[ "slacker" ] == true then
					--openfeint.unlockAchievement( 720932 )
				end
				
				if ofAch[ "super_slacker" ] == true then
					--openfeint.unlockAchievement( 720942 )
				end
				
				-- Double-Heart Achievements
				
				if ofAch[ "heart_saver" ] == true then
					--openfeint.unlockAchievement( 720952 )
				end
				
				if ofAch[ "stingy_heart" ] == true then
					--openfeint.unlockAchievement( 720962 )
				end
				
				if ofAch[ "life_preserver" ] == true then
					--openfeint.unlockAchievement( 720972 )
				end
				
				-- Star Achievements
				
				if ofAch[ "fifteen_stars" ] == true then
					--openfeint.unlockAchievement( 720982 )
				end
				
				if ofAch[ "star_struck" ] == true then
					--openfeint.unlockAchievement( 720992 )
				end
			end
		
			-- Fade in the game over shade
			gameOverShade.isVisible = true
			gameOverShade.alpha = 0
			transition.to( gameOverShade, { time=500, alpha=1 } )
			
			-- Slide the score banner from the right
			gameOverScoreBanner.isVisible = true
			transition.to( gameOverScoreBanner, { time=1000, x=240, transition=easing.inOutExpo } )
			
			-- Update score and display label
			gameOverScoreText.text = scoreNumber
			gameOverScoreText.x = 240
			gameOverScoreText.alpha = 0
			gameOverScoreText.isVisible = true
			transition.to( gameOverScoreText, { time=2000, alpha=1, transition=easing.inOutExpo } )
			
			-- Slide gem count banner down from the top
			gemScoreBg.isVisible = true
			transition.to( gemScoreBg, { time=500, y=24, transition=easing.inOutExpo } )
			
			-- Update gem score label
			local labelText = "High Gem Combo: " .. tostring(highestCombo)
			gemScoreText.text = labelText
			gemScoreText.y = 24
			gemScoreText.alpha = 0
			gemScoreText.isVisible = true
			transition.to( gemScoreText, { time=2000, alpha=1, transition=easing.inOutExpo } )
			
			-- Show "Try Again" Button
			tryAgainBtn.isVisible = true
			transition.to( tryAgainBtn, { time=2500, y=248, transition=easing.inOutExpo } )
			
			-- Show "OpenFeint" Button
			ofBtn.isVisible = true
			transition.to( ofBtn, { time=1500, y=174, transition=easing.inOutExpo } )
			
			-- Show "Facebook" Button
			fbBtn.isVisible = true
			transition.to( fbBtn, { time=2000, y=174, transition=easing.inOutExpo } )
			
			-- Show "Menu" Button
			menuBtn.isVisible = true
			menuBtn:setReferencePoint( display.BottomLeftReferencePoint )
			menuBtn.x = 0
			transition.to( menuBtn, { time=2800, y=320, transition=easing.inOutExpo } )
		end
		
		local oldUnlocked = tonumber(gameSettings["oldUnlocked"])
		local unlockedItems = tonumber(gameSettings["unlockedItems"])
		
		if oldUnlocked == 3 then
			local newItemMessage
			
			if unlockedItems == 4 then
				newItemMessage = display.newImageRect( "unlocked-heart.png", 480, 320 )
				newItemMessage.x = 240; newItemMessage.y = 160
				
				gameGroup:insert( newItemMessage )
				
			end
			
			local destroyMessageShowGameOver = function()
				if newItemMessage then
					display.remove( newItemMessage ); newItemMessage = nil
				end
				showGameOverScreen()
			end
			
			if unlockedItems > 3 then
				local theTimer = timer.performWithDelay( 4000, destroyMessageShowGameOver, 1 )
			else
				destroyMessageShowGameOver()
			end
			
		elseif oldUnlocked == 2 then
			local newItemMessage
			
			if unlockedItems == 4 then
				newItemMessage = display.newImageRect( "unlocked-heart.png", 480, 320 )
				newItemMessage.x = 240; newItemMessage.y = 160
				
				gameGroup:insert( newItemMessage )
				
			elseif unlockedItems == 3 then
				newItemMessage = display.newImageRect( "unlocked-electro.png", 480, 320 )
				newItemMessage.x = 240; newItemMessage.y = 160
				
				gameGroup:insert( newItemMessage )
			
			end
			
			local destroyMessageShowGameOver = function()
				if newItemMessage then
					display.remove( newItemMessage ); newItemMessage = nil
				end
				showGameOverScreen()
			end
			
			if unlockedItems > 2 then
				local theTimer = timer.performWithDelay( 4000, destroyMessageShowGameOver, 1 )
			else
				destroyMessageShowGameOver()
			end
			
		elseif oldUnlocked == 1 then
			local newItemMessage
			
			if unlockedItems == 4 then
				newItemMessage = display.newImageRect( "unlocked-heart.png", 480, 320 )
				newItemMessage.x = 240; newItemMessage.y = 160
				
				gameGroup:insert( newItemMessage )
				
			elseif unlockedItems == 3 then
				newItemMessage = display.newImageRect( "unlocked-electro.png", 480, 320 )
				newItemMessage.x = 240; newItemMessage.y = 160
				
				gameGroup:insert( newItemMessage )
			
			elseif unlockedItems == 2 then
				newItemMessage = display.newImageRect( "unlocked-invisible.png", 480, 320 )
				newItemMessage.x = 240; newItemMessage.y = 160
				
				gameGroup:insert( newItemMessage )
			
			end
			
			local destroyMessageShowGameOver = function()
				if newItemMessage then
					display.remove( newItemMessage ); newItemMessage = nil
				end
				showGameOverScreen()
			end
			
			if unlockedItems > 1 then
				local theTimer = timer.performWithDelay( 4000, destroyMessageShowGameOver, 1 )
			else
				destroyMessageShowGameOver()
			end
		
		elseif oldUnlocked == 0 then
			local newItemMessage
			
			if unlockedItems == 4 then
				newItemMessage = display.newImageRect( "unlocked-heart.png", 480, 320 )
				newItemMessage.x = 240; newItemMessage.y = 160
				
				gameGroup:insert( newItemMessage )
				
			elseif unlockedItems == 3 then
				newItemMessage = display.newImageRect( "unlocked-electro.png", 480, 320 )
				newItemMessage.x = 240; newItemMessage.y = 160
				
				gameGroup:insert( newItemMessage )
			
			elseif unlockedItems == 2 then
				newItemMessage = display.newImageRect( "unlocked-invisible.png", 480, 320 )
				newItemMessage.x = 240; newItemMessage.y = 160
				
				gameGroup:insert( newItemMessage )
			
			elseif unlockedItems == 1 then
				newItemMessage = display.newImageRect( "unlocked-fire.png", 480, 320 )
				newItemMessage.x = 240; newItemMessage.y = 160
				
				gameGroup:insert( newItemMessage )
			end
			
			local destroyMessageShowGameOver = function()
				if newItemMessage then
					display.remove( newItemMessage ); newItemMessage = nil
				end
				showGameOverScreen()
			end
			
			if unlockedItems > 0 then
				local theTimer = timer.performWithDelay( 4000, destroyMessageShowGameOver, 1 )
			else
				destroyMessageShowGameOver()
			end
		else
			showGameOverScreen()
		end
	end
	
	-- ************************************************************** --
	
	-- checkForGameOver() -- Check to see if player has lives left
	
	-- ************************************************************** --
	local checkForGameOver = function()
		
		if gameLives > 2 then
			gameLives = 2
		elseif gameLives <= 0 then
			callGameOver()
		end
	end	
	
	--***************************************************

	-- drawBackgound() --> create game background
	
	--***************************************************
	
	local drawBackground = function()
		local gameBackground
		local gameTheme = gameSettings["gameTheme"]
		
		if gameTheme == "classic" then
			gameBackground = display.newImageRect( "background-standard.png", 480, 320 )
		elseif gameTheme == "spook" then
			gameBackground = display.newImageRect( "background_spook.png", 480, 320 )
		end
		gameBackground.x = 240; gameBackground.y = 160
		
		gameGroup:insert( gameBackground )
	end
	
	--***************************************************

	-- createPlayer() --> create the main character
	
	--***************************************************
	local createPlayer = function()
		-- first, create the electroBubble
		electroBubble = display.newImageRect( "electrobubble.png", 60, 60 )
		electroBubble.x = -100; electroBubble.y = -100
		electroBubble.isVisible = false
		
		local gameTheme = gameSettings["gameTheme"]
		local gameChar = gameSettings["gameChar"]
		
		if gameTheme == "classic" then
			
			if gameChar == "d" then
				playerObject = movieclip.newAnim({ "dash-left.png", "dash-right.png" }, 46, 46 )
				
			elseif gameChar == "ms. d" then
				playerObject = movieclip.newAnim({ "girldash-left.png", "girldash-right.png" }, 46, 46 )
			
			elseif gameChar == "purple moe" then
				playerObject = movieclip.newAnim({ "purplemoe-left.png", "purplemoe-right.png" }, 52, 52 )
			
			elseif gameChar == "green horn" then
				playerObject = movieclip.newAnim({ "greenhorn-left.png", "greenhorn-right.png" }, 52, 52 )
				
			end
		
		elseif gameTheme == "spook" then
			
			if gameChar == "d" then
				playerObject = movieclip.newAnim({ "dash-left_spook.png", "dash-right_spook.png" }, 46, 46 )
			
			elseif gameChar == "ms. d" then
				playerObject = movieclip.newAnim({ "girldash-left_spook.png", "girldash-right_spook.png" }, 52, 52 )
			
			elseif gameChar == "purple moe" then
				playerObject = movieclip.newAnim({ "purplemoe-left_spook.png", "purplemoe-right_spook.png" }, 52, 52 )
			
			elseif gameChar == "green horn" then
				playerObject = movieclip.newAnim({ "greenhorn-left_spook.png", "greenhorn-right_spook.png" }, 52, 52 )
				
			else
				playerObject = movieclip.newAnim({ "dash-left_spook.png", "dash-right_spook.png" }, 46, 46 )
			end
		
		end
		
		local theShape
		
		if gameChar == "d" or gameChar == "ms. d" then
			theShape = { -9,-18, 9,-18, 9,18, -9,18 }
		elseif gameChar == "purple moe" then
			theShape = { -8,-17, 8,-17, 8,17, -8,17 }
		elseif gameChar == "green horn" then
			theShape = { -8,-19, 8,-19, 8,19, -8,19 }
		end
		
		physics.addBody( playerObject, "kinematic", { isSensor = true, density = 0, friction = 0, bounce = 0, shape = theShape, filter = playerFilter } )
		playerObject.isFixedRotation = true
		playerObject.myName = "player"
		playerObject.framePosition = "left"
		playerObject.animInterval = 150		--> lower = faster animation speed (old: 200)
		playerObject.isInvisible = false
		playerObject.isElectro = false
		playerObject.invisibleCycle = 1
		
		-- set actor speed multiplier based on tilt sensitivity (tiltSpeed)
		local tiltSpeed = gameSettings["tiltSpeed"]
		
		if tiltSpeed == "1" then
			playerObject.speed = 19
			
		elseif tiltSpeed == "2" then
			playerObject.speed = 22
			
		elseif tiltSpeed == "3" then
			playerObject.speed = 25
			
		elseif tiltSpeed == "4" then
			playerObject.speed = 32
			
		elseif tiltSpeed == "5" then
			playerObject.speed = 37
			
		else
			playerObject.speed = 25
		
		end
		
		local playerAnimation = function()
			if gameIsActive then
				if playerObject.framePosition == "left" then
					playerObject:stopAtFrame( 2 )
					playerObject.framePosition = "right"
				elseif playerObject.framePosition == "right" then
					playerObject:stopAtFrame( 1 )
					playerObject.framePosition = "left"
				end
			end
		end
		
		playerObject.animTimer = timer.performWithDelay( playerObject.animInterval, playerAnimation, 0 )	--> 250 is default interval
		
		-- Set player starting position on screen
		
		playerObject.x = 240
		playerObject.y = 125
		
		gameGroup:insert( electroBubble )
		gameGroup:insert( playerObject )
	end
	
	-- ************************************************************** --
	
	-- createGrass() -- Create the grass objects (cosmetic)
	
	-- ************************************************************** --
	local createGrass = function()
		
		local gameTheme = gameSettings["gameTheme"]
		
		if gameTheme == "classic" then
			grassBlade1 = display.newImageRect( "grass-f1.png", 22, 20 )
			grassBlade2 = display.newImageRect( "grass-f2.png", 22, 20 )
			grassBlade3 = display.newImageRect( "grass-f3.png", 22, 20 )
		
		elseif gameTheme == "spook" then
			grassBlade1 = display.newImageRect( "grass-f1_spook.png", 22, 20 )
			grassBlade2 = display.newImageRect( "grass-f2_spook.png", 22, 20 )
			grassBlade3 = display.newImageRect( "grass-f3_spook.png", 22, 20 )
		
		end
		
		grassBlade1.x = randomGemLocations[gemIndice];
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		grassBlade1.y = 350
		
		grassBlade2.x = randomGemLocations[gemIndice];
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		grassBlade2.y = 500
		
		grassBlade3.x = randomGemLocations[gemIndice];
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		grassBlade3.y = 650
		
		gameGroup:insert( grassBlade1 )
		gameGroup:insert( grassBlade2 )
		gameGroup:insert( grassBlade3 )
	end
	
	-- ************************************************************** --
	
	-- moveGrass() -- move grass based on game speed
	
	-- ************************************************************** --
	
	local moveGrass = function()
		
		local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
		
		grassBlade1.y = grassBlade1.y - gameMoveSpeed
		grassBlade2.y = grassBlade2.y - gameMoveSpeed
		grassBlade3.y = grassBlade3.y - gameMoveSpeed
		
		-- grassBlade1 goes past screen (top)
		if grassBlade1.y <= -36 then
		
			grassBlade1.x = randomGemLocations[gemIndice];
			gemIndice = gemIndice + 1
			if gemIndice > maxGemIndice then
				gemIndice = 1
			end
			grassBlade1.y = 350
			
			if grassBlade1.isVisible == false then
				grassBlade1.isVisible = true
			end
			
		end
		
		-- grassBlade2 goes past screen (top)
		if grassBlade2.y <= -36 then
		
			grassBlade2.x = randomGemLocations[gemIndice];
			gemIndice = gemIndice + 1
			if gemIndice > maxGemIndice then
				gemIndice = 1
			end
			grassBlade2.y = 350
			
			if grassBlade2.isVisible == false then
				grassBlade2.isVisible = true
			end
			
		end
		
		-- grassBlade3 goes past screen (top)
		if grassBlade3.y <= -36 then
		
			grassBlade3.x = randomGemLocations[gemIndice];
			gemIndice = gemIndice + 1
			if gemIndice > maxGemIndice then
				gemIndice = 1
			end
			grassBlade3.y = 350
			
			if grassBlade3.isVisible == false then
				grassBlade3.isVisible = true
			end
			
		end
	end
	
	-- ************************************************************** --
	
	-- createGems() -- Create the gem objects
	
	-- ************************************************************** --
	local createGems = function()
		
		--************************************************************************
		
		-- writeTextAboveChar()	--> displaying floating/fading text
		
		--************************************************************************
		
		local writeTextAboveChar = function( textLineOne, charX, charY )
			
			local theString = textLineOne
			local theX = charX
			local theY = charY - 30
			
			floatingText.text = theString
			floatingText:setReferencePoint( display.CenterReferencePoint )
			floatingText:setTextColor( 66, 17, 148, 255 )
			floatingText.alpha = 1.0
			floatingText.isVisible = true
			floatingText.xOrigin = theX
			floatingText.yOrigin = theY
			
			local destroyMessage = function()
				floatingText.x = 500; floatingText.y = -100
				floatingText.alpha = 0
				floatingText.isVisible = false
			end
			
			local newY = theY - 100
			
			transition.to( floatingText, { time=500, alpha=0, y=newY, onComplete=destroyMessage } )
		end
		
		local onGemCollision = function( self, event )
			if event.phase == "began" and event.other.myName == "player" then
				
				local doCollision = function()
					-- collision with player
					--self.isVisible = false
					self.alpha = 0
					
					local soundsOn = gameSettings[ "soundsOn" ]
						
					if soundsOn == true then
						local freeChan = audio.findFreeChannel()
						audio.play( gemSound, { channel=freeChan } )
					end
					
					--
					
					local scoreIncrease = 10 + (100 * gemCombo) + treeCycle
					gemCombo = gemCombo + 1
					gemCount = gemCount + 1
					
					if gemCombo >= 2 then
						local comboCount = tostring(gemCombo)
						
						comboText.text = "Combo " .. comboCount .. "x"
						comboText.isVisible = true
						comboIcon.isVisible = true
						comboBackground.isVisible = true
						
						-- set highest combo value
						if gemCombo > highestCombo then
							highestCombo = gemCombo
						end
						
						-- OpenFeint Achievements:
						if gemCombo >= 60 and ofAch[ "combo_60" ] == false then
							ofAch[ "combo_60" ] = true
						end
						
						if gemCombo >= 50 and ofAch[ "combo_50" ] == false then
							ofAch[ "combo_50" ] = true
						end
						
						if gemCombo >= 40 and ofAch[ "combo_40" ] == false then
							ofAch[ "combo_40" ] = true
						end
						
						if gemCombo >= 30 and ofAch[ "combo_30" ] == false then
							ofAch[ "combo_30" ] = true
						end
						
						if gemCombo >= 25 and ofAch[ "combo_25" ] == false then
							ofAch[ "combo_25" ] = true
						end
						
						if gemCombo >= 15 and ofAch[ "combo_15" ] == false then
							ofAch[ "combo_15" ] = true
						end
						
						if gemCombo >= 5 and ofAch[ "combo_5" ] == false then
							ofAch[ "combo_5" ] = true
						end
					end
					
					local currentScore = theScore + scoreIncrease
					setScore( currentScore )
					
					writeTextAboveChar( tostring(scoreIncrease), self.xOrigin, self.yOrigin )
					
					self.isBodyActive = false
				end
				
				local collisionTimer = timer.performWithDelay( 1, doCollision, 1 )
			else
				return true
			end
		end
		
		local gameTheme = gameSettings["gameTheme"]
		
		if gameTheme == "classic" then
			if gameSettings["shouldOptimize"] == true then
				if random1to4Table[oneFourIndice] <= 2 then
					gemObject1 = movieclip.newAnim({ "greengem.png", "greengem.png", "pinkgem.png", "pinkgem.png" }, 28, 28 )
					gemObject2 = movieclip.newAnim({ "greengem.png", "greengem.png", "pinkgem.png", "pinkgem.png" }, 28, 28 )
				else
					gemObject1 = movieclip.newAnim({ "bluegem.png", "bluegem.png", "orangegem.png", "orangegem.png" }, 28, 28 )
					gemObject2 = movieclip.newAnim({ "bluegem.png", "bluegem.png", "orangegem.png", "orangegem.png" }, 28, 28 )
				end
			else
				gemObject1 = movieclip.newAnim({ "bluegem.png", "greengem.png", "orangegem.png", "pinkgem.png" }, 28, 28 )
				gemObject2 = movieclip.newAnim({ "bluegem.png", "greengem.png", "orangegem.png", "pinkgem.png" }, 28, 28 )
			end
			
		elseif gameTheme == "spook" then
			gemObject1 = movieclip.newAnim({ "gem_spook.png", "gem_spook.png", "gem_spook.png", "gem_spook.png" }, 28, 28 )
			gemObject2 = movieclip.newAnim({ "gem_spook.png", "gem_spook.png", "gem_spook.png", "gem_spook.png" }, 28, 28 )
			
		end
		
		local theShape = { -9,-8, 9,-8, 9,8, -9,8 }
		physics.addBody( gemObject1, "dynamic", { isSensor = true, density = 0, friction = 0, bounce = 0, shape = theShape, filter = itemMonsterFilter } )
		physics.addBody( gemObject2, "dynamic", { isSensor = true, density = 0, friction = 0, bounce = 0, shape = theShape, filter = itemMonsterFilter } )
		
		
		gemObject1.isFixedRotation = true
		gemObject2.isFixedRotation = true
		gemObject1.alpha = 1.0
		gemObject2.alpha = 1.0
		gemObject1.myName = "gem1"
		gemObject2.myName = "gem2"
		
		-- set collisions
		gemObject1.collision = onGemCollision
		gemObject2.collision = onGemCollision
		
		gemObject1:addEventListener( "collision", gemObject1 )
		gemObject2:addEventListener( "collision", gemObject2 )
		
		-- set random color for both gem objects
		local randValue1 = random1to4Table[oneFourIndice]
		oneFourIndice = oneFourIndice + 1
		if oneFourIndice > maxOneFourIndice then
			oneFourIndice = 1
		end
		local randValue2 = random1to4Table[oneFourIndice]
		oneFourIndice = oneFourIndice + 1
		if oneFourIndice > maxOneFourIndice then
			oneFourIndice = 1
		end
		
		gemObject1:stopAtFrame( randValue1 )
		gemObject2:stopAtFrame( randValue2 )
		
		-- set initial location for both gem objects
		--gemObject1.x = mRandom( 70, 410 ); gemObject1.y = 420
		--gemObject2.x = mRandom( 70, 410 ); gemObject2.y = 620
		
		gemObject1.x = randomGemLocations[gemIndice];
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		gemObject1.y = 420
		
		gemObject2.x = randomGemLocations[gemIndice];
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		gemObject2.y = 620
		
		
		gameGroup:insert( gemObject1 )
		gameGroup:insert( gemObject2 )
	end
	
	-- ************************************************************** --
	
	-- moveGems() -- move gems based on game speed
	
	-- ************************************************************** --
	
	local moveGems = function()
		
		local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
		local randValue
		
		gemObject1.y = gemObject1.y - gameMoveSpeed
		gemObject2.y = gemObject2.y - gameMoveSpeed
		
		-- gemObjects go past player (reset gem combo)
		if gemObject1.y <= 60 then
			-- if gem wasn't picked up, reset combo count
			if gemObject1.alpha == 1.0 then
				gemCombo = 0
			end
		end
		
		if gemObject2.y <= 60 then
			-- if gem wasn't picked up, reset combo count
			if gemObject2.alpha == 1.0 then
				gemCombo = 0
			end
		end
		
		-- gemObject1 goes past screen (top)
		if gemObject1.y <= -32 then
		
			gemObject1.x = randomGemLocations[gemIndice];
			gemIndice = gemIndice + 1
			if gemIndice > maxGemIndice then
				gemIndice = 1
			end
			gemObject1.y = 420
			
			if gemObject1.isVisible == false or gemObject1.alpha == 0 then
				gemObject1.isVisible = true
				gemObject1.alpha = 1.0
			end
			
			-- choose new gem color
			-- set random color for both gem objects
			randValue = random1to4Table[oneFourIndice]
			oneFourIndice = oneFourIndice + 1
			if oneFourIndice > maxOneFourIndice then
				oneFourIndice = 1
			end
			
			gemObject1:stopAtFrame( randValue )
			
			gemObject1.isBodyActive = true
			
		end
		
		-- gemObject2 goes past screen (top)
		if gemObject2.y <= -32 then
			
			gemObject2.x = randomGemLocations[gemIndice];
			gemIndice = gemIndice + 1
			if gemIndice > maxGemIndice then
				gemIndice = 1
			end
			gemObject2.y = 420
			
			if gemObject2.isVisible == false or gemObject2.alpha == 0 then
				gemObject2.isVisible = true
				gemObject2.alpha = 1.0
			end
			
			-- choose new gem color
			randValue = random1to4Table[oneFourIndice]
			oneFourIndice = oneFourIndice + 1
			if oneFourIndice > maxOneFourIndice then
				oneFourIndice = 1
			end
			gemObject2:stopAtFrame( randValue )
			
			gemObject2.isBodyActive = true
		end
	end
	
	-- ************************************************************** --
	
	-- destroyAllEnemies() -- Destroy game-wise, not object-removal
	
	-- ************************************************************** --
	local destroyAllEnemies = function()
		
		if gameIsActive then
			-- Bunnies
			flyingBunny1.isBodyActive = false; flyingBunny1.isVisible = false
			flyingBunny2.isBodyActive = false; flyingBunny2.isVisible = false
			
			if gameSettings[ "difficulty" ] ~= "easy" then
				flyingBunny3.isBodyActive = false; flyingBunny3.isVisible = false
			end
			
			-- Bombs
			bombObject1.isBodyActive = false; bombObject1.isVisible = false
			
			-- Big Enemy
			bigEnemy.onTheMove = false; bigEnemy.isBodyActive = false; bigEnemy.isDestroyed = true; bigEnemy.isVisible = false
			
			-- Pond
			pondObject.onTheMove = false; pondObject.isBodyActive = false; pondObject.isDestroyed = true; pondObject.isVisible = false
		end
	end
	
	-- ************************************************************** --
	
	-- createPickups() -- Create the pickup items
	
	-- ************************************************************** --
	local createPickups = function()
		local collideActions = function()
			
			pickupObject.onTheMove = false
			
			-- increment the score
			local currentScore = getScore()
			currentScore = currentScore + 300
			setScore( currentScore )
			
			-- do something based on WHAT pickup it is
			if pickupObject.myName == "fire" then
				-- Destroy all enemies
				destroyAllEnemies()
				dropNotification( "Enemies Destroyed +300" )
				
			elseif pickupObject.myName == "invisible" then
				-- Invisibility
				playerObject.isInvisible = true
				playerObject.alpha = 0.45
				playerObject.invisibleCycle = 1
				dropNotification( "Invincibility +300" )
				
			elseif pickupObject.myName == "electro" then
				-- Destroy on touch
				
				electroBubble.isVisible = true
				playerObject.isInvisible = true
				playerObject.invisibleCycle = 1
				playerObject.isElectro = true
				dropNotification( "Destroy on Contact +300" )
				
			elseif pickupObject.myName == "heart" then
				-- Increase Life
				gameLives = 2
				heartLeft.alpha = 1.0
				dropNotification( "Extra Heart Earned +300" )
				
			end
			
			-- Based on how many pickups are unlocked, choose one
			local unlockedItems = tonumber(gameSettings["unlockedItems"])
			
			if unlockedItems == 1 then
				-- Only fire unlocked
				pickupObject.myName = "fire"
				pickupObject:stopAtFrame( 1 )
			
			elseif unlockedItems == 2 then
				-- Randomly choose between "fire" or "invisible"
				if random1to4Table[oneFourIndice] <= 2 then
					pickupObject.myName = "fire"
					pickupObject:stopAtFrame( 1 )
					
				elseif random1to4Table[oneFourIndice] > 2 then
					pickupObject.myName = "invisible"
					pickupObject:stopAtFrame( 2 )
				end
				
				-- increment random 1 to 4 table
				oneFourIndice = oneFourIndice + 1
				if oneFourIndice > maxOneFourIndice then
					oneFourIndice = 1
				end
			
			elseif unlockedItems == 3 then
				
				-- Randomly choose between "fire", "invisible", or "electro"
				if random1to4Table[oneFourIndice] == 1 then
					pickupObject.myName = "fire"
					pickupObject:stopAtFrame( 1 )
					
				elseif random1to4Table[oneFourIndice] == 2 then
					pickupObject.myName = "invisible"
					pickupObject:stopAtFrame( 2 )
				
				elseif random1to4Table[oneFourIndice] > 2 then
					pickupObject.myName = "electro"
					pickupObject:stopAtFrame( 3 )
				end
				
				-- increment random 1 to 4 table
				oneFourIndice = oneFourIndice + 1
				if oneFourIndice > maxOneFourIndice then
					oneFourIndice = 1
				end
				
			elseif unlockedItems == 4 then
				
				-- Randomly choose between "fire", "invisible", "electro", or "heart"
				if random1to4Table[oneFourIndice] == 1 then
					pickupObject.myName = "fire"
					pickupObject:stopAtFrame( 1 )
					
				elseif random1to4Table[oneFourIndice] == 2 then
					pickupObject.myName = "invisible"
					pickupObject:stopAtFrame( 2 )
				
				elseif random1to4Table[oneFourIndice] == 3 then
					pickupObject.myName = "electro"
					pickupObject:stopAtFrame( 3 )
				
				elseif random1to4Table[oneFourIndice] == 4 then
					
					if gameLives < 2 then
						pickupObject.myName = "heart"
						pickupObject:stopAtFrame( 4 )
					else
						pickupObject.myName = "fire"
						pickupObject:stopAtFrame( 1 )
					end
					
				end
				
				-- increment random 1 to 4 table
				oneFourIndice = oneFourIndice + 1
				if oneFourIndice > maxOneFourIndice then
					oneFourIndice = 1
				end
			end
		end
		
		local onPickupCollision = function( self, event )
			if event.phase == "began" and event.other.myName == "player" and gameIsActive == true then
				
				local doCollision = function()
					self.isBodyActive = false
					self.isVisible = false
					
					-- collision with player
					local soundsOn = gameSettings[ "soundsOn" ]
					
					if soundsOn == true then
						local freeChan = audio.findFreeChannel()
						audio.play( pickupSound, { channel=freeChan } )
					end
					
					flashAnimationPickup( "pickup" )
					collideActions()
				end
				
				local collisionTimer = timer.performWithDelay( 1, doCollision, 1 )
			end
		end
		
		pickupObject = movieclip.newAnim({ "fire-pickup.png", "invisible-pickup.png", "electro-pickup.png", "heart-pickup.png" }, 30, 30 )
		
		local theRadius = 14
		physics.addBody( pickupObject, "dynamic", { isSensor = true, density = 0, friction = 0, bounce = 0, radius=theRadius, filter = itemMonsterFilter } )
		
		pickupObject.isFixedRotation = true
		pickupObject.myName = "fire"	--> fire, invisible, electro, heart
		pickupObject.onTheMove = false	--> when set to true, moves up like other game objects (otherwise, is on standby)
		pickupObject.isVisible = false
		
		-- set collisions
		pickupObject.collision = onPickupCollision
		pickupObject:addEventListener( "collision", pickupObject )
		
		-- set initial location for the pickup object
		
		pickupObject.x = randomGemLocations[gemIndice];
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		
		pickupObject.y = 520
		
		
		gameGroup:insert( pickupObject )
		
	end
	
	-- ************************************************************** --
	
	-- movePickups() -- move pickups based on game speed
	
	-- ************************************************************** --
	
	local movePickups = function()
		
		if pickupObject.onTheMove then
			local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
			
			pickupObject.isVisible = true
			pickupObject.isBodyActive = true
			
			pickupObject.y = pickupObject.y - gameMoveSpeed
			
			-- Pickup goes past screen (top)
			if pickupObject.y <= -34 then
				pickupObject.onTheMove = false
				pickupObject.isVisible = false
				pickupObject.isBodyActive = false
				
				pickupObject.x = randomGemLocations[gemIndice];
				gemIndice = gemIndice + 1
				if gemIndice > maxGemIndice then
					gemIndice = 1
				end
				pickupObject.y = 520
				
				-- Based on how many pickups are unlocked, choose one
				local unlockedItems = tonumber(gameSettings["unlockedItems"])
				
				if unlockedItems == 1 then
					-- Only fire unlocked
					pickupObject.myName = "fire"
					pickupObject:stopAtFrame( 1 )
				
				elseif unlockedItems == 2 then
					-- Randomly choose between "fire" or "invisible"
					if random1to4Table[oneFourIndice] <= 2 then
						pickupObject.myName = "fire"
						pickupObject:stopAtFrame( 1 )
						
					elseif random1to4Table[oneFourIndice] > 2 then
						pickupObject.myName = "invisible"
						pickupObject:stopAtFrame( 2 )
					end
					
					-- increment random 1 to 4 table
					oneFourIndice = oneFourIndice + 1
					if oneFourIndice > maxOneFourIndice then
						oneFourIndice = 1
					end
				
				elseif unlockedItems == 3 then
					
					-- Randomly choose between "fire", "invisible", or "electro"
					if random1to4Table[oneFourIndice] == 1 then
						pickupObject.myName = "fire"
						pickupObject:stopAtFrame( 1 )
						
					elseif random1to4Table[oneFourIndice] == 2 then
						pickupObject.myName = "invisible"
						pickupObject:stopAtFrame( 2 )
					
					elseif random1to4Table[oneFourIndice] > 2 then
						pickupObject.myName = "electro"
						pickupObject:stopAtFrame( 3 )
					end
					
					-- increment random 1 to 4 table
					oneFourIndice = oneFourIndice + 1
					if oneFourIndice > maxOneFourIndice then
						oneFourIndice = 1
					end
					
				elseif unlockedItems == 4 then
					
					-- Randomly choose between "fire", "invisible", "electro", or "heart"
					if random1to4Table[oneFourIndice] == 1 then
						pickupObject.myName = "fire"
						pickupObject:stopAtFrame( 1 )
						
					elseif random1to4Table[oneFourIndice] == 2 then
						pickupObject.myName = "invisible"
						pickupObject:stopAtFrame( 2 )
					
					elseif random1to4Table[oneFourIndice] == 3 then
						pickupObject.myName = "electro"
						pickupObject:stopAtFrame( 3 )
					
					elseif random1to4Table[oneFourIndice] == 4 then
						
						if gameLives < 2 then
							pickupObject.myName = "heart"
							pickupObject:stopAtFrame( 4 )
						else
							pickupObject.myName = "fire"
							pickupObject:stopAtFrame( 1 )
						end
						
					end
					
					-- increment random 1 to 4 table
					oneFourIndice = oneFourIndice + 1
					if oneFourIndice > maxOneFourIndice then
						oneFourIndice = 1
					end
				end
			end
		end
	end
	
	-- ************************************************************** --
	
	-- createCheckPoint() -- Create the checkpoint item
	
	-- ************************************************************** --
	local createCheckPoint = function()
		
		local onCheckPointCollision = function( self, event )
			if event.phase == "began" and event.other.myName == "player" then
				
				local doCollision = function()
					-- collision with player
					local soundsOn = gameSettings[ "soundsOn" ]
					
					if soundsOn == true then
						local freeChan = audio.findFreeChannel()
						audio.play( checkPointSound, { channel=freeChan } )
					end
					
					self.onTheMove = false
					self.isBodyActive = false
					
					local scoreIncrement = 3000
					
					-- increment the score
					local currentScore = getScore()
					
					-- count how many checkpoints were crossed
					cpCount = cpCount + 1
					
					-- OPENFEINT ACHIEVEMENTS
					if currentScore == 0 and cpCount == 1 and ofAch[ "zero_hero" ] == false then
						-- Unlock Zero Hero Achievement
						ofAch[ "zero_hero" ] = true
					end
					
					if currentScore <= 3000 and cpCount == 2 and ofAch[ "under_achiever" ] == false then
						-- Unlock Under Achiever Achievement
						ofAch[ "under_achiever" ] = true
					end
					
					if currentScore <= 6000 and cpCount == 3 and ofAch[ "gem_hater" ] == false then
						-- Unlock Gem Hater Achievement
						ofAch[ "gem_hater" ] = true
					end
					
					if currentScore <= 9000 and cpCount == 4 and ofAch[ "slacker" ] == false then
						-- Unlock Slacker Achievement
						ofAch[ "slacker" ] = true
					end
					
					if currentScore <= 12000 and cpCount == 5 and ofAch[ "super_slacker" ] == false then
						-- Unlock Super Slacker Achievement
						ofAch[ "super_slacker" ] = true
					end
					
					-- END OPENFEINT ACHIEVEMENTS
					
					if cpCount < 5 then
						currentScore = currentScore + scoreIncrement
						
						-- Show notification message
						dropNotification( "Checkpoint Reached! +3000" )
					else
						scoreIncrement = 3000 * (cpCount - 3)
						currentScore = currentScore + scoreIncrement
						
						local notifyMessage = "Checkpoint Reached! +" .. tostring(scoreIncrement)
						
						-- Show notification message
						dropNotification( notifyMessage )
					end
					
					setScore( currentScore )
					
					
					-- make game faster
					if gameSettings[ "difficulty" ] == "easy" then
						gameSettings["gameMoveSpeed"] = gameSettings["gameMoveSpeed"] + 0.2	--> + 0.4 (30 fps) or 0.2 for (60 fps)
					
					elseif gameSettings[ "difficulty" ] == "medium" then
						gameSettings["gameMoveSpeed"] = gameSettings["gameMoveSpeed"] + 0.4	--> + 0.4 (30 fps) or 0.2 for (60 fps)
						
					elseif gameSettings[ "difficulty" ] == "medium" then
						gameSettings["gameMoveSpeed"] = gameSettings["gameMoveSpeed"] + 0.5	--> + 0.4 (30 fps) or 0.2 for (60 fps)
						
					end
					
					-- make player run faster
					if playerObject.animInterval > 100 then
						playerObject.animInterval = playerObject.animInterval - 20
					end
				end
				
				local collisionTimer = timer.performWithDelay( 1, doCollision, 1 )
			end
		end
		
		checkPointObject = display.newImageRect( "checkpoint.png", 480, 28 )
		
		physics.addBody( checkPointObject, "dynamic", { isSensor = true, density = 0, friction = 0, bounce = 0, filter = itemMonsterFilter } )
		
		checkPointObject.isFixedRotation = true
		checkPointObject.onTheMove = false	--> when set to true, moves up like other game objects (otherwise, is on standby)
		checkPointObject.isVisible = false
		checkPointObject.isBodyActive = false
		
		-- set collisions
		checkPointObject.collision = onCheckPointCollision
		checkPointObject:addEventListener( "collision", checkPointObject )
		
		-- set initial location for the pickup object
		
		checkPointObject.x = 240
		checkPointObject.y = 600
		
		
		gameGroup:insert( checkPointObject )
		
	end
	
	-- ************************************************************** --
	
	-- moveCheckPoint() -- move checkpoint based on game speed
	
	-- ************************************************************** --
	
	local moveCheckPoint = function()
		
		if checkPointObject.onTheMove then
			local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
			
			checkPointObject.y = checkPointObject.y - gameMoveSpeed
			
			-- Pickup goes past screen (top)
			if checkPointObject.y <= -90 then
				checkPointObject.onTheMove = false
				checkPointObject.isVisible = false
				checkPointObject.isBodyActive = false
				
				checkPointObject.x = 240
				checkPointObject.y = 600
			end
		elseif checkPointObject.onTheMove == false and checkPointObject.y > -90 then
			local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
			checkPointObject.y = checkPointObject.y - gameMoveSpeed
		elseif checkPointObject.onTheMove == false and checkPointObject.y < -90 then
			if checkPointObject.isVisible == true then
				checkPointObject.isVisible = false
			end
		end
	end
	
	-- ************************************************************** --
	
	-- createStar() -- Create the star object
	
	-- ************************************************************** --
	local createStar = function()
		
		--************************************************************************
		
		-- writeTextAboveChar()	--> displaying floating/fading text
		
		--************************************************************************
		
		local writeTextAboveChar = function( textLineOne, charX, charY )
			
			local theString = textLineOne
			local theX = charX
			local theY = charY - 30
			
			floatingTextStar.text = theString
			floatingTextStar:setReferencePoint( display.CenterReferencePoint )
			floatingTextStar:setTextColor( 66, 17, 148, 255 )
			floatingTextStar.alpha = 1.0
			floatingTextStar.isVisible = true
			floatingTextStar.xOrigin = theX
			floatingTextStar.yOrigin = theY
			
			local destroyMessage = function()
				floatingTextStar.x = 500; floatingTextStar.y = -100
				floatingTextStar.alpha = 0
				floatingTextStar.isVisible = false
			end
			
			local newY = theY - 100
			
			transition.to( floatingTextStar, { time=500, alpha=0, y=newY, onComplete=destroyMessage } )
		end
		
		local onStarCollision = function( self, event )
			if event.phase == "began" and event.other.myName == "player" then
				
				local doCollision = function( event )
					-- collision with player
					local soundsOn = gameSettings[ "soundsOn" ]
					
					if soundsOn == true then
						local freeChan = audio.findFreeChannel()
						audio.play( gemSound, { channel=freeChan } )
					end
					
					self.onTheMove = false
					self.isVisible = false
					self.isBodyActive = false
					
					-- increment the score
					local currentScore = getScore()
					local scoreIncrease = 10 * treeCycle
					currentScore = currentScore + scoreIncrease
					setScore( currentScore )
					
					-- OPENFEINT ACHIEVEMENT STUFF
					starCount = starCount + 1
					
					if starCount >= 15 and ofAch[ "fifteen_stars" ] == false then
						ofAch[ "fifteen_stars" ] = true
					end
					
					if starCount >= 25 and ofAch[ "star_struck" ] == false then
						ofAch[ "star_struck" ] = true
					end
					
					writeTextAboveChar( tostring(scoreIncrease), self.xOrigin, self.yOrigin )
				end
				
				local collisionTimer = timer.performWithDelay( 1, doCollision, 1 )
			end
		end
		
		local gameTheme = gameSettings["gameTheme"]
		
		if gameTheme == "classic" then
			starObject = display.newImageRect( "star.png", 30, 30 )
			
		elseif gameTheme == "spook" then
			starObject = display.newImageRect( "star_spook.png", 30, 30 )
		
		end
		
		local theRadius = 12
		physics.addBody( starObject, "dynamic", { isSensor = true, density = 0, friction = 0, bounce = 0, radius=theRadius, filter = itemMonsterFilter } )
		
		starObject.isFixedRotation = true
		starObject.onTheMove = false	--> when set to true, moves up like other game objects (otherwise, is on standby)
		starObject.isVisible = false
		
		-- set collisions
		starObject.collision = onStarCollision
		starObject:addEventListener( "collision", starObject )
		
		-- set initial location for the star object
		
		starObject.x = randomGemLocations[gemIndice];
		gemIndice = gemIndice + 1
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		
		starObject.y = 720
		
		
		gameGroup:insert( starObject )
		
	end
	
	-- ************************************************************** --
	
	-- moveStar() -- move star based on game speed
	
	-- ************************************************************** --
	
	local moveStar = function()
		
		if starObject.onTheMove then
			local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
			
			starObject.isVisible = true
			starObject.isBodyActive = true
			
			starObject.y = starObject.y - gameMoveSpeed
			
			-- Pickup goes past screen (top)
			if starObject.y <= -34 then
				starObject.onTheMove = false
				starObject.isVisible = false
				starObject.isBodyActive = false
				
				starObject.x = randomGemLocations[gemIndice];
				gemIndice = gemIndice + 1
				if gemIndice > maxGemIndice then
					gemIndice = 1
				end
				starObject.y = 720
				
			end
		end
	end
	
	
	-- ************************************************************** --
	
	-- createBunnies() -- Create the bunny enemies
	
	-- ************************************************************** --
	local createBunnies = function()
		
		local onBunnyCollision = function( self, event )
			if event.phase == "began" and event.other.myName == "player" then
				if playerObject.isInvisible == false then
					-- collision with player
					
					-- assess damage and lives
					if gameLives == 2 then
						local soundsOn = gameSettings[ "soundsOn" ]
						
						if soundsOn == true then
							local freeChan = audio.findFreeChannel()
							audio.play( hurtSound, { channel=freeChan } )
						end
						
						self.isBodyActive = false
					
						flashAnimation( "damage" )
						gameLives = 1; heartLeft.alpha = .25
					elseif gameLives == 1 then
						gameLives = 0
						gameIsActive = false
						
						local gameOverTimer = timer.performWithDelay( 200, callGameOver(), 1 )
					end
					
					return true
				
				else
					if playerObject.isElectro == true then
						local soundsOn = gameSettings[ "soundsOn" ]
						
						if soundsOn == true then
							local freeChan = audio.findFreeChannel()
							audio.play( bombSound, { channel=freeChan } )
						end
						
						self.isBodyActive = false; self.isVisible = false
						
						-- increment the score
						local currentScore = getScore()
						currentScore = currentScore + 200
						setScore( currentScore )
						
						--explode the bomb
						local poofAnim = movieclip.newAnim({ "poof-f1.png", "poof-f1.png", "poof-f2.png", "poof-f2.png", "poof-f3.png", "poof-f3.png", "poof-f4.png", "poof-f4.png", "poof-f5.png", "poof-f5.png" }, 64, 64 )
						poofAnim.x = self.x
						poofAnim.y = self.y
						poofAnim:play{ startFrame=1, endFrame=10, loop=1, remove=true }
						
						return true
					else
						return true
					end
				end
				
				return true
			end
		end
		
		local gameTheme = gameSettings["gameTheme"]
		
		if gameTheme == "classic" then
			flyingBunny1 = movieclip.newAnim( { "bunny1.png", "bunny1-2.png" }, 52, 52 )
			flyingBunny2 = movieclip.newAnim( { "bunny2.png", "bunny2-2.png" }, 52, 52 )
			
			if gameSettings[ "difficulty" ] ~= "easy" then
				if gameSettings["shouldOptimize"] == true then
					flyingBunny3 = movieclip.newAnim( { "bunny1.png", "bunny1-2.png" }, 52, 52 )
				else
					flyingBunny3 = movieclip.newAnim( { "bunny3.png", "bunny3-2.png" }, 52, 52 )
				end
				
			end
			
		elseif gameTheme == "spook" then
			flyingBunny1 = movieclip.newAnim( { "bunny1_spook.png", "bunny1-2_spook.png" }, 52, 52 )
			flyingBunny2 = movieclip.newAnim( { "bunny1_spook.png", "bunny1-2_spook.png" }, 52, 52 )
			if gameSettings[ "difficulty" ] ~= "easy" then
				flyingBunny3 = movieclip.newAnim( { "bunny1_spook.png", "bunny1-2_spook.png" }, 52, 52 )
			end
			
		end
		
		local theShape = { -7,-14, 7,-14, 7,14, -7,14 }
		physics.addBody( flyingBunny1, "dynamic", { isSensor = true, density = 0, friction = 0, bounce = 0, shape = theShape, filter = itemMonsterFilter } )
		physics.addBody( flyingBunny2, "dynamic", { isSensor = true, density = 0, friction = 0, bounce = 0, shape = theShape, filter = itemMonsterFilter } )
		
		if gameSettings[ "difficulty" ] ~= "easy" then
			physics.addBody( flyingBunny3, "dynamic", { isSensor = true, density = 0, friction = 0, bounce = 0, shape = theShape, filter = itemMonsterFilter } )
		end
		
		local flyingBunnyAnimInterval = 300
		
		flyingBunny1.isFixedRotation = true
		flyingBunny1.framePosition = 1
		flyingBunny2.isFixedRotation = true
		flyingBunny2.framePosition = 2
		
		if gameSettings[ "difficulty" ] == "easy" then
			flyingBunny1.selfSpeed = 0.4; flyingBunny1.dSelfSpeed = 0.4
			flyingBunny2.selfSpeed = 0.4; flyingBunny2.dSelfSpeed = 0.4
		
		elseif gameSettings[ "difficulty" ] == "medium" then
			flyingBunny1.selfSpeed = 0.5; flyingBunny1.dSelfSpeed = 0.5
			flyingBunny2.selfSpeed = 0.5; flyingBunny2.dSelfSpeed = 0.5
		
		elseif gameSettings[ "difficulty" ] == "hard" then
			flyingBunny1.selfSpeed = 0.6; flyingBunny1.dSelfSpeed = 0.6
			flyingBunny2.selfSpeed = 0.6; flyingBunny2.dSelfSpeed = 0.6
		
		end
		
		if gameSettings[ "difficulty" ] ~= "easy" then
			flyingBunny3.isFixedRotation = true
			flyingBunny3.framePosition = 1
			flyingBunny3.selfSpeed = 0.5
		end
		
		-- set collisions
		flyingBunny1.collision = onBunnyCollision
		flyingBunny2.collision = onBunnyCollision
		flyingBunny1:addEventListener( "collision", flyingBunny1 )
		flyingBunny2:addEventListener( "collision", flyingBunny2 )
		
		if gameSettings[ "difficulty" ] ~= "easy" then
			flyingBunny3.collision = onBunnyCollision
			flyingBunny3:addEventListener( "collision", flyingBunny3 )
		end
		
		-- set initial location for bunny objects
		--flyingBunny1.x = mRandom( 1, 479 ); flyingBunny1.y = 500
		--flyingBunny2.x = mRandom( 1, 479 ); flyingBunny2.y = 800
		flyingBunny1.x = randomBunnyLocations[bunnyIndice];
		bunnyIndice = bunnyIndice + 1;
		if bunnyIndice > maxBunnyIndice then
			bunnyIndice = 1
		end
		flyingBunny1.y = 500
		
		flyingBunny2.x = randomBunnyLocations[bunnyIndice];
		bunnyIndice = bunnyIndice + 1;
		if bunnyIndice > maxBunnyIndice then
			bunnyIndice = 1
		end
		flyingBunny2.y = 800
		
		if gameSettings[ "difficulty" ] ~= "easy" then
			flyingBunny3.x = randomBunnyLocations[bunnyIndice];
			bunnyIndice = bunnyIndice + 1;
			if bunnyIndice > maxBunnyIndice then
				bunnyIndice = 1
			end
			flyingBunny3.y = 950
		end
		
		-- handle bunny animations
		local bunny1Animation = function()
			if gameIsActive then
				if flyingBunny1.framePosition == 1 then
					flyingBunny1:stopAtFrame( 2 )
					flyingBunny1.framePosition = 2
				elseif flyingBunny1.framePosition == 2 then
					flyingBunny1:stopAtFrame( 1 )
					flyingBunny1.framePosition = 1
				end
			end
		end
		
		flyingBunny1.animTimer = timer.performWithDelay( flyingBunnyAnimInterval, bunny1Animation, 0 )
		
		local bunny2Animation = function()
			if gameIsActive then
				if flyingBunny2.framePosition == 1 then
					flyingBunny2:stopAtFrame( 2 )
					flyingBunny2.framePosition = 2
				elseif flyingBunny2.framePosition == 2 then
					flyingBunny2:stopAtFrame( 1 )
					flyingBunny2.framePosition = 1
				end
			end
		end
		
		flyingBunny2.animTimer = timer.performWithDelay( flyingBunnyAnimInterval, bunny2Animation, 0 )
		
		if gameSettings[ "difficulty" ] ~= "easy" then
			local bunny3Animation = function()
				if gameIsActive then
					if flyingBunny3.framePosition == 1 then
						flyingBunny3:stopAtFrame( 2 )
						flyingBunny3.framePosition = 2
					elseif flyingBunny3.framePosition == 2 then
						flyingBunny3:stopAtFrame( 1 )
						flyingBunny3.framePosition = 1
					end
				end
			end
			
			flyingBunny3.animTimer = timer.performWithDelay( flyingBunnyAnimInterval, bunny3Animation, 0 )
		end
		
		gameGroup:insert( flyingBunny1 )
		gameGroup:insert( flyingBunny2 )
		
		if gameSettings[ "difficulty" ] ~= "easy" then
			gameGroup:insert( flyingBunny3 )
		end
	end
	
	-- ************************************************************** --
	
	-- moveBunnies() -- move bunnies based on game speed
	
	-- ************************************************************** --
	
	local moveBunnies = function()
		
		local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
		
		-- move bunny upward on screen
		flyingBunny1.y = flyingBunny1.y - (gameMoveSpeed + flyingBunny1.selfSpeed)
		flyingBunny2.y = flyingBunny2.y - (gameMoveSpeed + flyingBunny2.selfSpeed)
		
		if gameSettings[ "difficulty" ] ~= "easy" then
			flyingBunny3.y = flyingBunny3.y - (gameMoveSpeed + flyingBunny3.selfSpeed)
		end
		
		-- move bunny toward's character
		if playerObject.x < flyingBunny1.x then
			flyingBunny1.x = flyingBunny1.x - (gameMoveSpeed * 0.15)	--> 0.15 / 0.12
			
		elseif playerObject.x > flyingBunny1.x then
			flyingBunny1.x = flyingBunny1.x + (gameMoveSpeed * 0.15)	--> 0.15 / 0.12
			
		end
		
		if playerObject.x < flyingBunny2.x then
			flyingBunny2.x = flyingBunny2.x - (gameMoveSpeed * 0.07)	--> 0.07 / 0.04
			
		elseif playerObject.x > flyingBunny2.x then
			flyingBunny2.x = flyingBunny2.x + (gameMoveSpeed * 0.07)	--> 0.07 / 0.04
			
		end
		
		if gameSettings[ "difficulty" ] ~= "easy" then
			if playerObject.x < flyingBunny3.x then 
				flyingBunny3.x = flyingBunny3.x - (gameMoveSpeed * 0.11)	--> 0.11 / 0.08
				
			elseif playerObject.x > flyingBunny3.x then
				flyingBunny3.x = flyingBunny3.x + (gameMoveSpeed * 0.11)	--> 0.11 / 0.08
				
			end
		end
		
		-- once player passes bunny
		local frontOfPlayer = playerObject.y + 50
		
		if frontOfPlayer >= flyingBunny1.y then
			flyingBunny1.selfSpeed = -2.0	--> -2.0 / -1.0
		end
		
		if frontOfPlayer >= flyingBunny2.y then
			flyingBunny2.selfSpeed = -2.0	--> -2.0 / -1.0
		end
		
		if gameSettings[ "difficulty" ] ~= "easy" then
			if frontOfPlayer >= flyingBunny3.y then
				flyingBunny3.selfSpeed = -2.0	--> -2.0 / -1.0
			end
		end
		
		-- bunny moves past top of screen
		if flyingBunny1.y <= -58 then
			flyingBunny1.x = randomBunnyLocations[bunnyIndice]
			bunnyIndice = bunnyIndice + 1;
			if bunnyIndice > maxBunnyIndice then
				bunnyIndice = 1
			end
			flyingBunny1.y = 500
			
			flyingBunny1.selfSpeed = flyingBunny1.dSelfSpeed
			
			if flyingBunny1.isVisible == false then
				flyingBunny1.isVisible = true
			end
			
			flyingBunny1.isBodyActive = true
		end
		
		if flyingBunny2.y <= -58 then
			flyingBunny2.x = randomBunnyLocations[bunnyIndice]
			bunnyIndice = bunnyIndice + 1;
			if bunnyIndice > maxBunnyIndice then
				bunnyIndice = 1
			end
			flyingBunny2.y = 500
			flyingBunny2.selfSpeed = flyingBunny2.dSelfSpeed
			
			if flyingBunny2.isVisible == false then
				flyingBunny2.isVisible = true
			end
			
			flyingBunny2.isBodyActive = true
		end
		
		if gameSettings[ "difficulty" ] ~= "easy" then
			if flyingBunny3.y <= -58 then
				flyingBunny3.x = randomBunnyLocations[bunnyIndice]
				bunnyIndice = bunnyIndice + 1;
				if bunnyIndice > maxBunnyIndice then
					bunnyIndice = 1
				end
				flyingBunny3.y = 500
				flyingBunny3.selfSpeed = 0.5
				if flyingBunny3.isVisible == false then
					flyingBunny3.isVisible = true
				end
				
				flyingBunny3.isBodyActive = true
			end
		end
		
	end
	
	-- ************************************************************** --
	
	-- createBombs() -- Create the bomb enemies
	
	-- ************************************************************** --
	local createBombs = function()
		
		local onBombCollision = function( self, event )
			if event.phase == "began" and event.other.myName == "player" then
				local doCollision = function()
					if playerObject.isInvisible == false then
						-- collision with player
						self.isBodyActive = false
						self.isVisible = false
						
						-- move poof object and animate it at the same location as bomb
						
						local soundsOn = gameSettings[ "soundsOn" ]
						
						if soundsOn == true then
							local freeChan = audio.findFreeChannel()
							audio.play( bombSound, { channel=freeChan } )
						end
						
						--> start Poof animation
						local poofAnim = movieclip.newAnim({ "poof-f1.png", "poof-f1.png", "poof-f2.png", "poof-f2.png", "poof-f3.png", "poof-f3.png", "poof-f4.png", "poof-f4.png", "poof-f5.png", "poof-f5.png" }, 64, 64 )
						poofAnim.x = self.x
						poofAnim.y = self.y
						poofAnim:play{ startFrame=1, endFrame=10, loop=1, remove=true }
						
						-- bombs mean automatic game over (unless in easy mode)
						if gameSettings[ "difficulty" ] ~= "easy" then
							gameLives = 0
							playerObject.isVisible = false
						else
							if gameLives >= 2 then
								gameLives = 1; heartLeft.alpha = .25
								playerObject.isVisible = true
								
								flashAnimation( "damage" )
								
							else
								gameLives = 0
								playerObject.isVisible = false
							end
						end
						
						if gameLives <= 0 then
							--checkForGameOver()
							gameIsActive = false
							local gameOverTimer = timer.performWithDelay( 200, callGameOver(), 1 )
						end
						
						return true
					else
						if playerObject.isElectro == true then
							local soundsOn = gameSettings[ "soundsOn" ]
					
							if soundsOn == true then
								local freeChan = audio.findFreeChannel()
								audio.play( bombSound, { channel=freeChan } )
							end
							
							self.isBodyActive = false; self.isVisible = false
							
							-- increment the score
							local currentScore = getScore()
							currentScore = currentScore + 200
							setScore( currentScore )
							
							--explode the bomb
							local poofAnim = movieclip.newAnim({ "poof-f1.png", "poof-f1.png", "poof-f2.png", "poof-f2.png", "poof-f3.png", "poof-f3.png", "poof-f4.png", "poof-f4.png", "poof-f5.png", "poof-f5.png" }, 64, 64 )
							poofAnim.x = self.x
							poofAnim.y = self.y
							poofAnim:play{ startFrame=1, endFrame=10, loop=1, remove=true }
							
							return true
						else
							return true
						end
					end
				end
				
				local collisionTimer = timer.performWithDelay( 1, doCollision, 1 )
			end
		end
		
		bombObject1 = display.newImageRect( "bomb.png", 38, 38 )
		
		local theShape = { -7,-6, 7,-6, 7,6, -7,6 }
		physics.addBody( bombObject1, "dynamic", { isSensor = true, density = 0, friction = 0, bounce = 0, shape = theShape, filter = itemMonsterFilter } )
		
		bombObject1.isFixedRotation = true
		
		-- set collisions
		bombObject1.collision = onBombCollision
		bombObject1:addEventListener( "collision", bombObject1 )
		
		-- set initial location for bomb object
		bombObject1.x = randomGemLocations[gemIndice]
		gemIndice = gemIndice + 1;
		if gemIndice > maxGemIndice then
			gemIndice = 1
		end
		bombObject1.y = 650
		
		
		gameGroup:insert( bombObject1 )
	end
	
	-- ************************************************************** --
	
	-- moveBombs() -- move bombs based on game speed
	
	-- ************************************************************** --
	
	local moveBombs = function()
		
		local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
		
		-- move bomb upward on screen
		bombObject1.y = bombObject1.y - gameMoveSpeed
		
		
		-- bomb moves past top of screen
		if bombObject1.y <= -42 then
			bombObject1.x = randomGemLocations[gemIndice]
			gemIndice = gemIndice + 1;
			if gemIndice > maxGemIndice then
				gemIndice = 1
			end
			bombObject1.y = 650
			
			if bombObject1.isVisible == false then
				bombObject1.isVisible = true
			end
			
			bombObject1.isBodyActive = true
		end
		
	end
	
	-- ************************************************************** --
	
	-- createBigEnemy() -- Create the big enemy object
	
	-- ************************************************************** --
	local createBigEnemy = function()
		
		local onBigEnemyCollision = function( self, event )
			if event.phase == "began" and event.other.myName == "player" then
				local doCollision = function()
					if playerObject.isInvisible == false then
						-- collision with player
						
						if gameLives == 2 then
							
							self.onTheMove = false
							self.isBodyActive = false
							
							flashAnimation( "damage" )
							gameLives = 1; heartLeft.alpha = .25
							
							local soundsOn = gameSettings[ "soundsOn" ]
							
							if soundsOn == true then
								local freeChan = audio.findFreeChannel()
								audio.play( hurtSound, { channel=freeChan } )
							end
							
							-- change the score (big enemy steals 1000 points)
							local currentScore = getScore()
							
							if gameSettings[ "difficulty" ] ~= "easy" then
								currentScore = currentScore - 1000
							else
								currentScore = currentScore - 400
							end
							
							if currentScore < 0 then currentScore = 0; end
							setScore( currentScore )
							
						elseif gameLives == 1 then
							gameLives = 0
							--checkForGameOver()
							gameIsActive = false
							local gameOverTimer = timer.performWithDelay( 200, callGameOver(), 1 )
						end
						
						return true
						
					else
						if playerObject.isElectro == true then
							local soundsOn = gameSettings[ "soundsOn" ]
							
							if soundsOn == true then
								local freeChan = audio.findFreeChannel()
								audio.play( bombSound, { channel=freeChan } )
							end
							
							self.onTheMove = false; self.isBodyActive = false; self.isDestroyed = true; self.isVisible = false
							
							-- increment the score
							local currentScore = getScore()
							currentScore = currentScore + 300
							setScore( currentScore )
							
							--explode the bomb
							local poofAnim = movieclip.newAnim({ "poof-f1.png", "poof-f1.png", "poof-f2.png", "poof-f2.png", "poof-f3.png", "poof-f3.png", "poof-f4.png", "poof-f4.png", "poof-f5.png", "poof-f5.png" }, 64, 64 )
							poofAnim.x = self.x
							poofAnim.y = self.y
							poofAnim:play{ startFrame=1, endFrame=10, loop=1, remove=true }
							
							return true
						else
							return true
						end
					end
				end
				
				local collisionTimer = timer.performWithDelay( 1, doCollision, 1 )
			end
		end
		
		local gameTheme = gameSettings["gameTheme"]
		
		if gameTheme == "classic" then
			bigEnemy = display.newImageRect( "bigenemy.png", 94, 94 )
			
		elseif gameTheme == "spook" then
			bigEnemy = display.newImageRect( "bigenemy_spook.png", 94, 94 )
		
		end
		
		local theShape = { -16,-14, 16,-14, 16,14, -16,14 }
		physics.addBody( bigEnemy, "dynamic", { isSensor = true, density = 0, friction = 0, bounce = 0, shape = theShape, filter = itemMonsterFilter } )
		
		bigEnemy.isFixedRotation = true
		bigEnemy.onTheMove = false	--> when set to true, moves up like other game objects (otherwise, is on standby)
		bigEnemy.isVisible = false
		bigEnemy.isDestroyed = false
		
		-- set collisions
		bigEnemy.collision = onBigEnemyCollision
		bigEnemy:addEventListener( "collision", bigEnemy )
		
		-- set initial location for big enemy object
		bigEnemy.x = randomBunnyLocations[bunnyIndice]
		bunnyIndice = bunnyIndice + 1;
		if bunnyIndice > maxBunnyIndice then
			bunnyIndice = 1
		end
		bigEnemy.y = 900
		
		
		gameGroup:insert( bigEnemy )
	end
	
	-- ************************************************************** --
	
	-- moveBigEnemy() -- move big enemy based on game speed
	
	-- ************************************************************** --
	
	local moveBigEnemy = function()
		
		if bigEnemy.onTheMove then
			local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
			
			bigEnemy.isVisible = true
			bigEnemy.isBodyActive = true
			
			bigEnemy.y = bigEnemy.y - gameMoveSpeed
			
		elseif bigEnemy.onTheMove == false and bigEnemy.isDestroyed == false and bigEnemy.y > -102 then
			local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
			bigEnemy.y = bigEnemy.y - gameMoveSpeed
			bigEnemy.isBodyActive = false
		end
		
		if bigEnemy.isDestroyed then
			local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
			bigEnemy.y = bigEnemy.y - gameMoveSpeed
			bigEnemy.isVisible = false
			bigEnemy.isBodyActive = false
		end
		
		-- Pickup goes past screen (top)
		if bigEnemy.y <= -102 then
			bigEnemy.onTheMove = false
			bigEnemy.isVisible = false
			bigEnemy.isBodyActive = false
			bigEnemy.isDestroyed = false
			
			bigEnemy.x = randomBunnyLocations[bunnyIndice];
			bunnyIndice = bunnyIndice + 1
			if bunnyIndice > maxBunnyIndice then
				bunnyIndice = 1
			end
			bigEnemy.y = 900
			
		end
	end
	
	-- ************************************************************** --
	
	-- createPond() -- Create the pond object
	
	-- ************************************************************** --
	local createPond = function()
		
		local onPondCollision = function( self, event )
			if event.phase == "began" and event.other.myName == "player" then
				local doCollision = function()
					if playerObject.isInvisible == false then
						-- collision with player
						
						if gameLives == 2 then
							
							self.onTheMove = false
							self.isBodyActive = false
							
							flashAnimation( "damage" )
							gameLives = 1; heartLeft.alpha = .25
							
							local soundsOn = gameSettings[ "soundsOn" ]
							
							if soundsOn == true then
								local freeChan = audio.findFreeChannel()
								audio.play( hurtSound, { channel=freeChan } )
							end
						
						elseif gameLives == 1 then
							gameLives = 0
							gameIsActive = false
							
							local gameOverTimer = timer.performWithDelay( 200, callGameOver(), 1 )
						end
						
						return true
					else
						if playerObject.isElectro == true then
							-- in electro mode, player can still be damaged by the pond
							if gameLives == 2 then
								
								self.onTheMove = false
								self.isBodyActive = false
								
								flashAnimation( "damage" )
								gameLives = 1; heartLeft.alpha = .25
								
								local soundsOn = gameSettings[ "soundsOn" ]
								
								if soundsOn == true then
									local freeChan = audio.findFreeChannel()
									audio.play( hurtSound, { channel=freeChan } )
								end
							
							elseif gameLives == 1 then
								gameLives = 0
								gameIsActive = false
								
								local gameOverTimer = timer.performWithDelay( 200, callGameOver(), 1 )
							end
							
							return true
						else
							return true
						end
					end
				end
				
				local collisionTimer = timer.performWithDelay( 1, doCollision, 1 )
			end
		end
		
		local gameTheme = gameSettings["gameTheme"]
		
		if gameTheme == "classic" then
			pondObject = display.newImageRect( "pond.png", 82, 50 )
		
		elseif gameTheme == "spook" then
			pondObject = display.newImageRect( "pond_spook.png", 82, 50 )
		
		end
		
		local theShape = { -17,-10, 17,-10, 17,10, -17,10 }
		physics.addBody( pondObject, "dynamic", { isSensor = true, density = 0, friction = 0, bounce = 0, shape = theShape, filter = itemMonsterFilter } )
		
		pondObject.isFixedRotation = true
		pondObject.onTheMove = false	--> when set to true, moves up like other game objects (otherwise, is on standby)
		pondObject.isVisible = false
		pondObject.isDestroyed = false
		
		-- set collisions
		pondObject.collision = onPondCollision
		pondObject:addEventListener( "collision", pondObject )
		
		-- set initial location for big enemy object
		pondObject.x = randomBunnyLocations[bunnyIndice]
		bunnyIndice = bunnyIndice + 1;
		if bunnyIndice > maxBunnyIndice then
			bunnyIndice = 1
		end
		pondObject.y = 500
		
		
		gameGroup:insert( pondObject )
	end
	
	-- ************************************************************** --
	
	-- movePond() -- move pond based on game speed
	
	-- ************************************************************** --
	
	local movePond = function()
		
		if pondObject.onTheMove then
			local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
			
			pondObject.isVisible = true
			pondObject.isBodyActive = true
			
			pondObject.y = pondObject.y - gameMoveSpeed
			
		elseif pondObject.onTheMove == false and pondObject.isDestroyed == false and pondObject.y > -84 then
			local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
			pondObject.y = pondObject.y - gameMoveSpeed
			pondObject.isBodyActive = false
		end
		
		if pondObject.isDestroyed then
			local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
			pondObject.y = pondObject.y - gameMoveSpeed
			pondObject.isVisible = false
			pondObject.isBodyActive = false
		end
		
		-- Pond goes past screen (top)
		if pondObject.y <= -84 then
			pondObject.onTheMove = false
			pondObject.isVisible = false
			pondObject.isBodyActive = false
			pondObject.isDestroyed = false
			
			pondObject.x = randomBunnyLocations[bunnyIndice];
			bunnyIndice = bunnyIndice + 1
			if bunnyIndice > maxBunnyIndice then
				bunnyIndice = 1
			end
			pondObject.y = 500
			
		end
	end
	
	-- ************************************************************** --
	
	-- checkObjectSpawn() -- spawn certain objects on new tree cycle
	
	-- ************************************************************** --
	local checkObjectSpawn = function()
		
		-- ITEM PICKUPS (not including gems)
		local unlockedItems = tonumber(gameSettings["unlockedItems"])
		
		if unlockedItems >= 1 then
			if pickupCycle >= pickupSpawnRate then
				pickupCycle = 1		--> reset pickup cycle
				
				pickupObject.x = randomGemLocations[gemIndice];
				gemIndice = gemIndice + 1
				if gemIndice > maxGemIndice then
					gemIndice = 1
				end
				pickupObject.y = 520
				pickupObject.onTheMove = true
			end
		end
		
		-- CHECKPOINT
		if checkPointCycle >= checkPointSpawnRate then
			checkPointCycle = 1		--> reset pickup cycle
			
			checkPointObject.x = 240
			checkPointObject.y = 600
			checkPointObject.onTheMove = true
			checkPointObject.isVisible = true
			checkPointObject.isBodyActive = true
		end
		
		-- STAR ITEM
		if starCycle >= starSpawnRate then
			starCycle = 1		--> reset star cycle
			
			starObject.x = randomGemLocations[gemIndice];
			gemIndice = gemIndice + 1
			if gemIndice > maxGemIndice then
				gemIndice = 1
			end
			starObject.y = 720
			starObject.onTheMove = true
		end
		
		-- BIG ENEMY
		if bigEnemyCycle >= bigEnemySpawnRate then
			bigEnemyCycle = 1		--> reset big enemy cycle
			
			bigEnemy.x = randomBunnyLocations[bunnyIndice];
			bunnyIndice = bunnyIndice + 1
			if bunnyIndice > maxBunnyIndice then
				bunnyIndice = 1
			end
			bigEnemy.y = 900
			bigEnemy.onTheMove = true
		end
		
		-- GREEN POND
		if pondCycle >= pondSpawnRate then
			pondCycle = 1		--> reset big enemy cycle
			
			pondObject.x = randomBunnyLocations[bunnyIndice];
			bunnyIndice = bunnyIndice + 1
			if bunnyIndice > maxBunnyIndice then
				bunnyIndice = 1
			end
			pondObject.y = 500
			pondObject.onTheMove = true
		end
	end
	
	-- ************************************************************** --
	
	-- createTrees() -- Draw trees
	
	-- ************************************************************** --
	local createTrees = function()
		
		local gameTheme = gameSettings["gameTheme"]
		
		if gameTheme == "classic" then
			treeObjects["left1"] = display.newImageRect( "trees-left.png", 64, 256 )
			treeObjects["left2"] = display.newImageRect( "trees-left.png", 64, 256 )
			treeObjects["right1"] = display.newImageRect( "trees-right.png", 64, 256 )
			treeObjects["right2"] = display.newImageRect( "trees-right.png", 64, 256 )
			
		elseif gameTheme == "spook" then
			treeObjects["left1"] = display.newImageRect( "trees-left_spook.png", 64, 256 )
			treeObjects["left2"] = display.newImageRect( "trees-left_spook.png", 64, 256 )
			treeObjects["right1"] = display.newImageRect( "trees-right_spook.png", 64, 256 )
			treeObjects["right2"] = display.newImageRect( "trees-right_spook.png", 64, 256 )
			
		end
		
		treeObjects["left1"].x = 0 + (treeObjects["left1"].width / 2)
		treeObjects["left1"].y = (display.contentHeight) / 2 - 128
		treeObjects["left2"].x = treeObjects["left1"].x
		treeObjects["left2"].y = treeObjects["left1"].y + treeObjects["left1"].height + 100
		
		treeObjects["right1"].x = 480 - (treeObjects["right1"].width / 2)
		treeObjects["right1"].y = (display.contentHeight / 2) - 32
		treeObjects["right2"].x = treeObjects["right1"].x
		treeObjects["right2"].y = treeObjects["right1"].y + treeObjects["right1"].height + 100
		
		gameGroup:insert( treeObjects["left1"] )
		gameGroup:insert( treeObjects["left2"] )
		gameGroup:insert( treeObjects["right1"] )
		gameGroup:insert( treeObjects["right2"] )
	end
	
	-- ************************************************************** --
	
	-- moveTrees() -- move trees upward
	
	-- ************************************************************** --
	local moveTrees = function()
		local gameMoveSpeed = gameSettings[ "gameMoveSpeed" ]
		
		treeObjects["left1"].y = treeObjects["left1"].y - gameMoveSpeed
		treeObjects["left2"].y = treeObjects["left2"].y - gameMoveSpeed
		treeObjects["right1"].y = treeObjects["right1"].y - gameMoveSpeed
		treeObjects["right2"].y = treeObjects["right2"].y - gameMoveSpeed
		
		-- move trees back to the bottom once they go too far up
		-- also, increment score by 10 everytime the first tree cycles
		
		if treeObjects["left1"].y < -256 then
			treeObjects["left1"].y = 448
			
			--[[
			local currentScore = getScore()
			currentScore = currentScore + 10
			setScore( currentScore )
			]]--
			
			treeCycle = treeCycle + 1
			pickupCycle = pickupCycle + 1
			checkPointCycle = checkPointCycle + 1
			starCycle = starCycle + 1
			bigEnemyCycle = bigEnemyCycle + 1
			pondCycle = pondCycle + 1
			
			checkObjectSpawn()
			
			-- if in easy mode, increment score
			if gameSettings[ "difficulty" ] == "easy" then
				local gameScore = getScore()
				gameScore = gameScore + 25
				setScore( gameScore )
			end
			
			-- Handle player invisibility
			if playerObject.isInvisible == true then
				playerObject.invisibleCycle = playerObject.invisibleCycle + 1
				
				if playerObject.invisibleCycle >= 5 then
					playerObject.isInvisible = false
					playerObject.isElectro = false
					electroBubble.isVisible = false; electroBubble.x = -100; electroBubble.y = -100
					playerObject.alpha = 1.0
				end
			end
			
			-- See if combo display needs to be hidden
			if gemCombo < 2 then
				comboText.isVisible = false
				comboIcon.isVisible = false
				comboBackground.isVisible = false
			end
		end
		
		if treeObjects["left2"].y < -256 then
			treeObjects["left2"].y = 448
			
			-- if in easy mode, increment score
			if gameSettings[ "difficulty" ] == "easy" then
				local gameScore = getScore()
				gameScore = gameScore + 25
				setScore( gameScore )
			end
			
			-- See if combo display needs to be hidden
			if gemCombo < 2 then
				comboText.isVisible = false
				comboIcon.isVisible = false
				comboBackground.isVisible = false
			end
		end
		
		if treeObjects["right1"].y < -256 then
			treeObjects["right1"].y = 448
		end
		
		if treeObjects["right2"].y < -256 then
			treeObjects["right2"].y = 448
		end
	end
	
	
	-- ************************************************************** --
	
	-- drawHUD() -- Draw things on the heads up display
	
	-- ************************************************************** --
	local drawHUD = function()
		local scoreInfo = getInfo()
		local border = 5
		
		-- Combo Background
		comboBackground = display.newRoundedRect( 30, 31, 122, 28, 5 )
		comboBackground:setFillColor( 0, 0, 0, 255 )
		comboBackground.alpha = 0.80
		comboBackground.isVisible = false
		
		-- Combo Icon
		comboIcon = display.newImageRect( "comboicon.png", 18, 16 )
		comboIcon.x = 48; comboIcon.y = 45
		comboIcon.isVisible = false
		
		-- Combo text
		comboText = display.newText( "Combo 2x", 400, 277, "Helvetica-Bold", 28 )
		comboText:setTextColor( 213, 213, 213, 255 )
		comboText.xScale = 0.5; comboText.yScale = 0.5
		comboText.x = 103; comboText.y = 46
		comboText.isVisible = false
		
		-- Notification Banner
		notificationBanner = display.newImageRect( "notification-banner.png", 480, 30 )
		notificationBanner:setReferencePoint( display.TopLeftReferencePoint )
		notificationBanner.x = 0; notificationBanner.y = -32
		notificationBanner.isVisible = false
		
		-- Notification Text
		notificationText = display.newText( " ", 30, -16, "Helvetica-Bold", 13 )
		notificationText:setTextColor( 116, 211, 246, 255 )
		notificationText:setReferencePoint( display.CenterLeftReferencePoint )
		notificationText.x = 34; notificationText.y = -18
		notificationText.isVisible = false
		
		-- Score Init
		--x = scoreInfo.width - ((scoreInfo.width + border) * 2)
		init( { 
			x = 10, 
			y = 272 }
		)
		setScore( 0 )
		theBackground.isVisible = true
		
		-- Round border
		local roundBorder = display.newImageRect( "round-border.png", 480, 320 )
		roundBorder.x = 240; roundBorder.y = 160
		
		-- Difficulty display
		local diffText = display.newText( "Medium", 350, 310, "Helvetica-Bold", 32 )
		diffText:setTextColor( 252, 255, 255, 255 )
		if gameSettings[ "difficulty" ] == "easy" then
			diffText.text = "Easy"
		elseif gameSettings[ "difficulty" ] == "medium" then
			diffText.text = "Medium"
		elseif gameSettings[ "difficulty" ] == "hard" then
			diffText.text = "Hard"
		end
		diffText.xScale = 0.5; diffText.yScale = 0.5
		diffText.x = 460 - (diffText.contentWidth / 2); diffText.y = 310
		
		-- Heart Background
		heartBackground = display.newImageRect( "heartbg.png", 88, 42 )
		heartBackground.x = 430; heartBackground.y = 28
		
		-- Heart Display
		heartLeft = display.newImageRect( "heart.png", 28, 28 )
		heartLeft.x = 414; heartLeft.y = 28
		
		heartRight = display.newImageRect( "heart.png", 28, 28 )
		heartRight.x = 448; heartRight.y = 28
		
		-- Damage Rectangle
		damageRect = display.newRect( 0, 0, display.contentWidth, display.contentHeight )
		damageRect:setFillColor( 172, 0, 0, 255 )
		damageRect.isVisible = false
		damageRect.alpha = 0
		
		-- Pickup Rectangle
		pickupRect = display.newRect( 0, 0, display.contentWidth, display.contentHeight )
		pickupRect:setFillColor( 255, 255, 255, 255 )
		pickupRect.isVisible = false
		pickupRect.alpha = 0
		
		-- Best Score Text Display (upper left corner)
		local theBestScore = comma_value( gameSettings["bestScore"] )
		bestScoreText = display.newText( theBestScore, 25, 10, "Helvetica-Bold", 30 )
		
		-- For displaying final image optimization count:
		--[[
		local optimCount = loadValue( "optim.data" )
		bestScoreText = display.newText( optimCount, 25, 10, "Helvetica-Bold", 15 )
		]]--
		
		bestScoreText:setTextColor( 0, 0, 0, 255 )
		--bestScoreText:setReferencePoint( display.CenterLeftReferencePoint )
		--bestScoreText.x = 25; bestScoreText.y = 11
		bestScoreText.xScale = 0.5; bestScoreText.yScale = 0.5
		bestScoreText.x = (bestScoreText.contentWidth / 2) + 25; bestScoreText.y = 10
		
		-- Pause Overlay
		--[[
		pauseOverlay = display.newImageRect( "pauseoverlay.png", 440, 277 )
		pauseOverlay.x = 240; pauseOverlay.y = 160
		pauseOverlay.isVisible = false
		
		-- Locked items
		lockedFire = display.newImageRect( "locked-pickup.png", 30, 30 )
		lockedFire.x = 120; lockedFire.y = 209
		lockedFire.isVisible = false
		
		lockedInvisible = display.newImageRect( "locked-pickup.png", 30, 30 )
		lockedInvisible.x = 273; lockedInvisible.y = 209
		lockedInvisible.isVisible = false
		
		lockedElectro = display.newImageRect( "locked-pickup.png", 30, 30 )
		lockedElectro.x = 120; lockedElectro.y = 250
		lockedElectro.isVisible = false
		
		lockedHeart = display.newImageRect( "locked-pickup.png", 30, 30 )
		lockedHeart.x = 273; lockedHeart.y = 252
		lockedHeart.isVisible = false
		]]--
		
		-- Floating Text Display and Floating Text Star and Floating Text Big Enemy
		floatingText = display.newText( "", 500, -100, "Helvetica-Bold", 15 )
		floatingText.alpha = 0
		floatingText.isVisible = false
		
		floatingTextStar = display.newText( "", 500, -100, "Helvetica-Bold", 15 )
		floatingTextStar.alpha = 0
		floatingTextStar.isVisible = false
		
		
		gameGroup:insert( floatingText )
		gameGroup:insert( floatingTextStar )
		gameGroup:insert( damageRect )
		gameGroup:insert( pickupRect )
		gameGroup:insert( bestScoreText )
		gameGroup:insert( comboBackground )
		gameGroup:insert( comboIcon )
		gameGroup:insert( comboText )
		--[[
		gameGroup:insert( pauseOverlay )
		gameGroup:insert( lockedFire )
		gameGroup:insert( lockedInvisible )
		gameGroup:insert( lockedElectro )
		gameGroup:insert( lockedHeart )
		]]--
		gameGroup:insert( roundBorder )
		gameGroup:insert( diffText )
		gameGroup:insert( notificationBanner )
		gameGroup:insert( notificationText )
		gameGroup:insert( theScoreGroup )
		gameGroup:insert( heartBackground )
		gameGroup:insert( heartLeft )
		gameGroup:insert( heartRight )
	end
	
	-- ************************************************************** --
	
	--	gameLoop() -- Accelerometer Code for Player Movement
	
	-- ************************************************************** --
	
	local gameLoop = function( event )
		
		--if gameIsActive and frameCounter >= 2 then	--> uncomment for 60 fps
		if gameIsActive then
			menuIsActive = false
			
			moveTrees()
			moveGrass()
			moveGems()
			movePickups()
			moveCheckPoint()
			moveStar()
			moveBombs()
			moveBunnies()
			moveBigEnemy()
			movePond()
			
			-- Change high score text when high score is passed
			if newHighScore == false then
				local theScore = tonumber(getScore())
				local bestScore = tonumber(gameSettings["bestScore"])
				
				if theScore > bestScore then
					newHighScore = true
					dropNotification( "New High Score!" )
					
					bestScoreText:setTextColor( 234, 63, 168, 255)
				end
			else
				local theScore = tonumber(getScore())
				bestScoreText.text = comma_value( theScore )
				--bestScoreText:setReferencePoint( display.CenterLeftReferencePoint )
				--bestScoreText.x = 25; bestScoreText.y = 11
				bestScoreText.xScale = 0.5; bestScoreText.yScale = 0.5
				bestScoreText.x = (bestScoreText.contentWidth / 2) + 25; bestScoreText.y = 10
			end
			
			-- electroBubble
			if electroBubble.isVisible == true then
				electroBubble.x = playerObject.x
				electroBubble.y = playerObject.y
			end
			
			-- ***********************************************************
			-- ***********************************************************
			
			-- Score-Based Achievements
			
			-- ***********************************************************
			
			local unlockedItems = tonumber(gameSettings["unlockedItems"])
			
			if unlockedItems < 4 then
				if unlockedItems == 3 then
					local gameScore = tonumber(getScore())
					
					if gameScore >= 70000 then
						
						gameSettings["unlockedItems"] = 4
						unlockedItems = 4
						
						dropNotification("Unlocked New Item!")
						
						-- OpenFeint:
						if ofAch[ "score_70k" ] == false then
							--openfeint.unlockAchievement( 720742 )
							ofAch[ "score_70k" ] = true
							
							-- Also unlock all of previous achievements
							--openfeint.unlockAchievement( 721002 )
							ofAch[ "score_50k" ] = true
							
							--openfeint.unlockAchievement( 720732 )
							ofAch[ "score_20k" ] = true
							
							--openfeint.unlockAchievement( 720722 )
							ofAch[ "score_10k" ] = true
						end
						
					end
				elseif unlockedItems == 2 then
					local gameScore = tonumber(getScore())
					
					if gameScore >= 70000 then
						
						gameSettings["unlockedItems"] = 4
						unlockedItems = 4
						
						dropNotification("Unlocked New Item!")
						
						-- OpenFeint:
						if ofAch[ "score_70k" ] == false then
							--openfeint.unlockAchievement( 720742 )
							ofAch[ "score_70k" ] = true
							
							-- Also unlock all of previous achievements
							--openfeint.unlockAchievement( 721002 )
							ofAch[ "score_50k" ] = true
							
							--openfeint.unlockAchievement( 720732 )
							ofAch[ "score_20k" ] = true
							
							--openfeint.unlockAchievement( 720722 )
							ofAch[ "score_10k" ] = true
						end
						
					elseif gameScore < 70000 and gameScore >= 50000 then
						
						gameSettings["unlockedItems"] = 3
						unlockedItems = 3
						
						dropNotification("Unlocked New Item!")
						
						-- OpenFeint:
						if ofAch[ "score_50k" ] == false then
							--openfeint.unlockAchievement( 721002 )
							ofAch[ "score_50k" ] = true
							
							-- Also unlock all of previous achievements
							--openfeint.unlockAchievement( 720732 )
							ofAch[ "score_20k" ] = true
							
							--openfeint.unlockAchievement( 720722 )
							ofAch[ "score_10k" ] = true
						end
						
					end
				elseif unlockedItems == 1 then
					local gameScore = tonumber(getScore())
					
					if gameScore >= 70000 then
						
						gameSettings["unlockedItems"] = 4
						unlockedItems = 4
						
						dropNotification("Unlocked New Item!")
						
						-- OpenFeint:
						if ofAch[ "score_70k" ] == false then
							--openfeint.unlockAchievement( 720742 )
							ofAch[ "score_70k" ] = true
							
							-- Also unlock all of previous achievements
							--openfeint.unlockAchievement( 721002 )
							ofAch[ "score_50k" ] = true
							
							--openfeint.unlockAchievement( 720732 )
							ofAch[ "score_20k" ] = true
							
							--openfeint.unlockAchievement( 720722 )
							ofAch[ "score_10k" ] = true
						end
						
					elseif gameScore < 70000 and gameScore >= 50000 then
						
						gameSettings["unlockedItems"] = 3
						unlockedItems = 3
						
						dropNotification("Unlocked New Item!")
						
						-- OpenFeint:
						if ofAch[ "score_50k" ] == false then
							--openfeint.unlockAchievement( 721002 )
							ofAch[ "score_50k" ] = true
							
							-- Also unlock all of previous achievements
							--openfeint.unlockAchievement( 720732 )
							ofAch[ "score_20k" ] = true
							
							--openfeint.unlockAchievement( 720722 )
							ofAch[ "score_10k" ] = true
						end
						
					elseif gameScore < 50000 and gameScore >= 20000 then
						
						gameSettings["unlockedItems"] = 2
						unlockedItems = 2
						
						dropNotification("Unlocked New Item!")
						
						-- OpenFeint:
						if ofAch[ "score_20k" ] == false then
							--openfeint.unlockAchievement( 720732 )
							ofAch[ "score_20k" ] = true
							
							-- Also unlock all of previous achievements
							--openfeint.unlockAchievement( 720722 )
							ofAch[ "score_10k" ] = true
						end
					end
				elseif unlockedItems == 0 then
					local gameScore = tonumber(getScore())
					
					if gameScore >= 70000 then
						
						gameSettings["unlockedItems"] = 4
						unlockedItems = 4
						
						dropNotification("Unlocked New Item!")
						
						-- OpenFeint:
						if ofAch[ "score_70k" ] == false then
							--openfeint.unlockAchievement( 720742 )
							ofAch[ "score_70k" ] = true
							
							-- Also unlock all of previous achievements
							--openfeint.unlockAchievement( 721002 )
							ofAch[ "score_50k" ] = true
							
							--openfeint.unlockAchievement( 720732 )
							ofAch[ "score_20k" ] = true
							
							--openfeint.unlockAchievement( 720722 )
							ofAch[ "score_10k" ] = true
						end
						
					elseif gameScore < 70000 and gameScore >= 50000 then
						
						gameSettings["unlockedItems"] = 3
						unlockedItems = 3
						
						dropNotification("Unlocked New Item!")
						
						-- OpenFeint:
						if ofAch[ "score_50k" ] == false then
							--openfeint.unlockAchievement( 721002 )
							ofAch[ "score_50k" ] = true
							
							-- Also unlock all of previous achievements
							--openfeint.unlockAchievement( 720732 )
							ofAch[ "score_20k" ] = true
							
							--openfeint.unlockAchievement( 720722 )
							ofAch[ "score_10k" ] = true
						end
						
					elseif gameScore < 50000 and gameScore >= 20000 then
						
						gameSettings["unlockedItems"] = 2
						unlockedItems = 2
						
						dropNotification("Unlocked New Item!")
						
						-- OpenFeint:
						if ofAch[ "score_20k" ] == false then
							--openfeint.unlockAchievement( 720732 )
							ofAch[ "score_20k" ] = true
							
							-- Also unlock all of previous achievements
							--openfeint.unlockAchievement( 720722 )
							ofAch[ "score_10k" ] = true
						end
						
					elseif gameScore < 20000 and gameScore >= 10000 then	--> 10000
						
						gameSettings["unlockedItems"] = 1
						unlockedItems = 1
					
						dropNotification("Unlocked New Item!")
						
						-- Openfeint:
						if ofAch[ "score_10k" ] == false then
							--openfeint.unlockAchievement( 720722 )
							ofAch[ "score_10k" ] = true
						end
						
					end
				end
					
			end
			
			-- ***********************************************************
			
			-- END - Score-Based Achievements
			
			-- ***********************************************************
			-- ***********************************************************
			
			--frameCounter = 1		--> uncomment for 60 fps
			
			
			-- DOUBLE-HEART BASED ACHIEVEMENTS
			local gameScore = tonumber(getScore())
			
			if gameLives >= 2 and gameScore >= 90000 and ofAch[ "life_preserver" ] == false then
				ofAch[ "life_preserver" ] = true
			end
			
			if gameLives >= 2 and gameScore >= 70000 and ofAch[ "stingy_heart" ] == false then
				ofAch[ "stingy_heart" ] = true
			end
			
			if gameLives >= 2 and gameScore >= 50000 and ofAch[ "heart_saver" ] == false then
				ofAch[ "heart_saver" ] = true
			end
		end
		--[[
		else
			frameCounter = frameCounter + 1
		end
		]]--
		
		if menuIsActive == true then
			gameIsActive = false
			moveTrees()	
			moveGrass()
			moveGems()
			moveStar()
			moveBombs()
			moveBigEnemy()
			movePond()
		end
	end
	
	-- END gameLoop()
	
	-- ************************************************************** --
	
	-- drawGameOverObjects() -- Draw things for the game over display
	
	-- ************************************************************** --
	
	local drawGameOverObjects = function()
		
		-- Draw banner for game title for quick start menu
		quickStartBanner = display.newImageRect( "quickstartbanner.png", 480, 84 )
		quickStartBanner.x = 720; quickStartBanner.y = 84
		quickStartBanner.isVisible = false
		
		gameGroup:insert( quickStartBanner )
		
		-- Setup "Play Now" Button
		local touchPlayNowBtn = function( event )
			if event.phase == "release" and playNowBtn.isActive == true then
				
				playNowBtn.isActive = false
				
				-- Turn off gameLoop event listener just in case
				Runtime:removeEventListener( "enterFrame", gameLoop )
		
				-- Start the gameLoop again
				Runtime:addEventListener( "enterFrame", gameLoop )
				
				-- Play Sound
				local soundsOn = gameSettings[ "soundsOn" ]
				local musicOn = gameSettings[ "musicOn" ]
				
				if soundsOn == true then
					local freeChan = audio.findFreeChannel()
					audio.play( tapSound, { channel=freeChan } )
					
					-- running sound effect
					local freeChan2 = audio.findFreeChannel()
					audio.play( runningSound, { loops=-1, channel=freeChan2 } )
				end
				
				if musicOn then					
					audio.stop( gameMusic1 )
					musicChan = audio.findFreeChannel()
					audio.setVolume( 0.5, { channel=musicChan } )
					
					if gameSettings[ "gameTheme" ] == "classic" then
						audio.play( gameMusic3, { loops=-1, channel=musicChan, fadein=4000  } )
						
					elseif gameSettings[ "gameTheme" ] == "spook" then
						audio.play( gameMusic2, { loops=-1, channel=musicChan, fadein=4000  } )
						
					end
				end
				
				recycleRound()
				
			end
		end
		
		playNowBtn = ui.newButton{
			defaultSrc = "playnow-btn.png",
			defaultX = 155,
			defaultY = 59,
			overSrc = "playnow-btn-over.png",
			overX = 155,
			overY = 59,
			onEvent = touchPlayNowBtn,
			id = "playNowButton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		
		playNowBtn.xOrigin = 240; playNowBtn.yOrigin = 600
		playNowBtn.isVisible = false
		
		gameGroup:insert( playNowBtn )
		
		-- Setup "OpenFeint" Button
		local touchOFBtn = function( event )
			if event.phase == "release" then
				-- Play Sound
				local soundsOn = gameSettings[ "soundsOn" ]
				
				if soundsOn == true then
					local freeChan = audio.findFreeChannel()
					audio.play( tapSound, { channel=freeChan } )
				end
				
				--openfeint call
				if onDevice then
					----openfeint.launchDashboard()
				end
			end
		end
		
		ofBtn = ui.newButton{
			defaultSrc = "openfeint.png",
			defaultX = 155,
			defaultY = 59,
			overSrc = "openfeint-over.png",
			overX = 155,
			overY = 59,
			onEvent = touchOFBtn,
			id = "openfeintButton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		
		ofBtn.xOrigin = 150; ofBtn.yOrigin = 625
		ofBtn.isVisible = false
		
		gameGroup:insert( ofBtn )
		
		-- Setup "Help" Button
		local touchHelpBtn = function( event )
			if event.phase == "release" and helpBtn.isActive == true then
				helpBtn.isActive = false	--> prevent double-pushing of the button
				
				-- Play Sound
				local soundsOn = gameSettings[ "soundsOn" ]
				local musicOn = gameSettings[ "musicOn" ]
				
				if soundsOn == true then
					local freeChan = audio.findFreeChannel()
					audio.play( tapSound, { channel=freeChan } )
				end
				
				if musicOn == true then
					audio.stop( gameMusic1 )
				end
				
				-- remove event listeners
				gameIsActive = false
				menuIsActive = false
				Runtime:removeEventListener( "enterFrame", gameLoop )
				Runtime:removeEventListener( "system", onSystem )
				
				-- main menu call
				director:changeScene( "helpScreen" )
			end
		end
		
		helpBtn = ui.newButton{
			defaultSrc = "helpbtn.png",
			defaultX = 106,
			defaultY = 36,
			overSrc = "helpbtn-over.png",
			overX = 106,
			overY = 36,
			onEvent = touchHelpBtn,
			id = "helpButton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		
		helpBtn:setReferencePoint( display.BottomRightReferencePoint )
		helpBtn.xOrigin = 480; helpBtn.yOrigin = 450
		helpBtn.isVisible = false
		
		gameGroup:insert( helpBtn )
		
		-- Setup "Themes & Settings" Button
		local touchThemesBtn = function( event )
			if event.phase == "release" then
				-- Play Sound
				local soundsOn = gameSettings[ "soundsOn" ]
				local musicOn = gameSettings[ "musicOn" ]
				
				if soundsOn == true then
					local freeChan = audio.findFreeChannel()
					audio.play( tapSound, { channel=freeChan } )
				end
				
				if musicOn == true then
					audio.stop( gameMusic1 )
				end
				
				-- remove event listeners
				gameIsActive = false
				menuIsActive = false
				Runtime:removeEventListener( "enterFrame", gameLoop )
				Runtime:removeEventListener( "system", onSystem )
				
				--themes and settings page call
				director:changeScene( "optionsScreen" )
			end
		end
		
		themesBtn = ui.newButton{
			defaultSrc = "themes-btn.png",
			defaultX = 155,
			defaultY = 59,
			overSrc = "themes-btn-over.png",
			overX = 155,
			overY = 59,
			onEvent = touchThemesBtn,
			id = "themesButton",
			text = "",
			font = "Helvetica",
			textColor = { 255, 255, 255, 255 },
			size = 16,
			emboss = false
		}
		
		themesBtn.xOrigin = 330; themesBtn.yOrigin = 625
		themesBtn.isVisible = false
		
		gameGroup:insert( themesBtn )
		
		-- Draw two rectangles, one for above the display and one for below (so things look good on iPad)
		local topRect = display.newRect( 0, -160, 480, 160 )
		topRect:setFillColor( 0, 0, 0, 255 )
		
		local bottomRect = display.newRect( 0, 320, 480, 160 )
		bottomRect:setFillColor( 0, 0, 0, 255 )
		
		gameGroup:insert( topRect )
		gameGroup:insert( bottomRect )
	end
	
	-- ************************************************************** --
	
	--	showQuickStartMenu() -- When app is first opened
	
	-- ************************************************************** --
	
	local showQuickStartMenu = function()
		-- Pause all game movement (if it was on for some odd reason)
		if gameIsActive == true then gameIsActive = false; end
		menuIsActive = true
		
		--Runtime:removeEventListener( "accelerometer", onTilt )
		--Runtime:removeEventListener( "touch", touchPause )
		
		system.setIdleTimer( true ) -- turn on device sleeping
		
		-- Hide the player from the screen
		playerObject.isVisible = false
		playerObject.isBodyActive = false
		
		-- Make game move speed slow (for menu only)
		gameSettings["gameMoveSpeed"] = gameSettings["gameMoveSpeed"] * 0.4
		
		-- Hide some of the on-screen elements
		theScoreGroup.isVisible = false
		heartBackground.isVisible = false
		heartLeft.isVisible = false
		heartRight.isVisible = false
		comboText.isVisible = false
		comboIcon.isVisible = false
		comboBackground.isVisible = false
		
		local loadQuickStartMenu = function()
		
			-- Fade in the game over shade
			--[[
			gameOverShade.isVisible = true
			gameOverShade.alpha = 0
			transition.to( gameOverShade, { time=500, alpha=1 } )
			]]--
			
			-- Slide the score banner from the right
			quickStartBanner.isVisible = true
			transition.to( quickStartBanner, { time=1000, x=240, transition=easing.inOutExpo } )
			
			-- Show "Play Now" Button
			playNowBtn.isVisible = true
			transition.to( playNowBtn, { time=2500, y=248, transition=easing.inOutExpo } )
			
			-- Show "OpenFeint" Button
			ofBtn.isVisible = true
			transition.to( ofBtn, { time=1500, y=174, transition=easing.inOutExpo } )
			
			-- Show "Themes & Settings" Button
			themesBtn.isVisible = true
			transition.to( themesBtn, { time=2000, y=174, transition=easing.inOutExpo } )
			
			-- Show "Help" Button
			helpBtn.isVisible = true
			helpBtn:setReferencePoint( display.BottomRightReferencePoint )
			helpBtn.x = 480
			transition.to( helpBtn, { time=1000, y=320, transition=easing.inOutExpo } )
			
			-- Show "Tournament" Button
			--[[
			tournamentBtn.isVisible = true
			tournamentBtn:setReferencePoint( display.BottomLeftReferencePoint )
			tournamentBtn.x = 0
			transition.to( tournamentBtn, { time=1000, y=320, transition=easing.inOutExpo } )
			]]--
		end
		
		loadQuickStartMenu()
		
	end
	
	-- ************************************************************** --

	-- gameInit() --> set initial settings and call creation functions
	
	-- ************************************************************** --
	local gameInit = function()
		local i
		local musicOn = gameSettings[ "musicOn" ]
		local soundsOn = gameSettings[ "soundsOn" ]
		
		-- load difficulty from settings file
		local difficultySetting = loadValue( "difficulty.data" )
		
		if difficultySetting == "0" then
			-- Medium
			gameSettings[ "difficulty" ] = "medium"
			gameSettings["gameMoveSpeed"] = 7.7
			gameSettings["defaultMoveSpeed"] = 7.7
			
			print ( "Difficulty: Medium" )
		
		elseif difficultySetting == "1" then
			-- Easy
			gameSettings[ "difficulty" ] = "easy"
			gameSettings["gameMoveSpeed"] = 7.3
			gameSettings["defaultMoveSpeed"] = 7.3
			
			print ( "Difficulty: Easy" )
		
		elseif difficultySetting == "2" then
			-- Hard
			gameSettings[ "difficulty" ] = "hard"
			gameSettings["gameMoveSpeed"] = 8.1
			gameSettings["defaultMoveSpeed"] = 8.1
			
			print ( "Difficulty: Hard" )
		end
		
		-- load best score, lifetime gems, highest combo, and unlocked items
		
		if gameSettings[ "difficulty" ] ~= "easy" then
			gameSettings[ "bestScore" ] = loadValue( "TiMQGcpCZv.data" )	
			gameSettings[ "lifeGems" ] = loadValue( "SadzCtDWmK.data" )
			gameSettings[ "highCombo" ] = loadValue( "UVIMSPUuCb.data" )
			gameSettings[ "unlockedItems" ] = loadValue( "nxMzUBnOeN.data" )
		else
			gameSettings[ "bestScore" ] = loadValue( "TpjixLATIZ.data" )	
			gameSettings[ "lifeGems" ] = loadValue( "sOfvDxAlkH.data" )
			gameSettings[ "highCombo" ] = loadValue( "wnpzK3g55u.data" )
			gameSettings[ "unlockedItems" ] = loadValue( "neiEFXdaiLIa.data" )
		end
		
		gameSettings[ "oldUnlocked" ] = gameSettings[ "unlockedItems" ]
		
		gameSettings[ "tiltSpeed" ] = loadValue( "tilt.data" )
		
		local musicData = loadValue( "music.data" )
		local soundData = loadValue( "sound.data" )
		local themeData = loadValue( "theme.data" )
		local charData = loadValue( "char.data" )
		
		gameSettings["shouldOptimize"] = false
		
		if gameSettings[ "tiltSpeed" ] == "0" then
			gameSettings[ "tiltSpeed" ] = "3"
			saveValue( "tilt.data", "3" )
		end
		
		if musicData == "0" then
			gameSettings["musicOn"] = false
			musicOn = false
			
			musicData = "no"
			saveValue( "music.data", musicData )
		else
			if musicData == "yes" then
				gameSettings["musicOn"] = true
				musicOn = true
			elseif musicData == "no" then
				gameSettings["musicOn"] = false
				musicOn = false
			end
		end
		
		if soundData == "0" then
			soundData = "yes"	--> default: yes
			saveValue( "sound.data", soundData )
			
			gameSettings["soundsOn"] = true	--> default: true
			soundsOn = true		--> default: true
		elseif soundData == "yes" then
			
			gameSettings["soundsOn"] = true
			soundsOn = true
		
		elseif soundData == "no" then
			
			gameSettings["soundsOn"] = false
			soundsOn = false
		
		end
		
		-- set up proper theme based on saved file
		
		if themeData == "0" then
			themeData = "classic"
			saveValue( "theme.data", themeData )
			gameSettings["gameTheme"] = themeData
		
		else
			gameSettings["gameTheme"] = themeData
		end
		
		-- set up proper character based on saved file
		
		if charData == "0" then
			charData = "d"
			saveValue( "char.data", charData )
			gameSettings["gameChar"] = charData
		else
			gameSettings["gameChar"] = charData
		end
			
		
		-- start physics and set initial settings
		physics.start( true )
		physics.setGravity( 0, 0 )
		
		if musicOn then			
			musicChan = audio.findFreeChannel()
			
			audio.setVolume( 0.5, { channel=musicChan } )
			audio.play( gameMusic1, { loops=-1, channel=musicChan } )
		end
		
		
		-- Initial settings
		gemCombo = 0
		
		-- Populate random tables
		for i = 1, maxBunnyIndice do
			randomBunnyLocations[i] = mRandom( 1, 479 )
		end
		
		for i = 1, maxGemIndice do
			randomGemLocations[i] = mRandom( 70, 410 )
		end
		
		for i = 1, maxOneFourIndice do
			random1to4Table[i] = mRandom( 1, 4 )
		end
		
		drawBackground()
		createGrass()
		createCheckPoint()
		createPond()
		createGems()
		createStar()
		createPickups()
		createBombs()
		createPlayer()
		createBigEnemy()
		createBunnies()
		createTrees()
		
		drawHUD()
		drawGameOverObjects()
		
		Runtime:addEventListener( "enterFrame", gameLoop )
		Runtime:addEventListener( "system", onSystem )
		
		-- Set the game in motion
		showQuickStartMenu()
	end
	
	local onOrientationChange = function( event )
		-- update variable for orientation changes
		orientationDirection = event.type
	end
	 
	Runtime:addEventListener( "orientation", onOrientationChange )
	
	--***************************************************

	-- clean() --> stop timers and event listeners
	
	--***************************************************
	
	clean = function()
		gameIsActive = false
		menuIsActive = false
		physics.stop()
		
		-- stop event listeners
		Runtime:removeEventListener( "accelerometer", onTilt )
		Runtime:removeEventListener( "enterFrame", gameLoop )
		Runtime:removeEventListener( "touch", touchPause )
		Runtime:removeEventListener( "system", onSystem )
		Runtime:removeEventListener( "orientation", onOrientationChange )
		
		-- stop timers
		if playerObject.animTimer then
			timer.cancel( playerObject.animTimer )
		end
		
		if flyingBunny1.animTimer then
			timer.cancel( flyingBunny1.animTimer )
		end

		if flyingBunny2.animTimer then
			timer.cancel( flyingBunny2.animTimer )
		end
		
		if flyingBunny3 then
			if flyingBunny3.animTimer then
				timer.cancel( flyingBunny3.animTimer )
			end
		end
		
		-- unload all sounds and music
		unloadSoundsAndMusic()
	end
	
	
	-- LOAD THIS MODULE AND START A NEW ROUND:
	gameInit()
	
	-- MUST return a display.newGroup()
	return gameGroup
end
