-- game scene

-- place all the require statements here
local composer = require( "composer" )
local physics = require("physics")
local json = require( "json" )
local tiled = require( "com.ponywolf.ponytiled" )
 
local scene = composer.newScene()
 
local map = nil
local ninja = nil
local ninjaGirl = nil
local rightArrow = nil
local jumpButton = nil
local shootButton = nil
local playerKunais = {}

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------



local function onJumpButtonTouch( event )
    if ( event.phase == "began" ) then
        if ninja.sequence ~= "jump" then
            ninja:setLinearVelocity( 0, -750 )
            ninja.sequence = "jump"
            ninja:setSequence( "jump" )
            ninja:play()
        end
    elseif ( event.phase == "ended" ) then
        
       
    end       
    return true
end

local ninjaThrow = function( event )

    ninja.sequence = "idle"
    ninja:setSequence( "idle" )
    ninja:play()    
end


local function onShootButtonTouch( event )
    if ( event.phase == "began" ) then
        if ninja.sequence ~= "throw" then
            ninja.sequence = "throw"
            ninja:setSequence( "throw" )
            ninja:play()
            timer.performWithDelay( 1000, ninjaThrow )

            local aSingleKunai = display.newImage( "./assets/sprites/kunai.png" )
            aSingleKunai.x = ninja.x
            aSingleKunai.y = ninja.y
            physics.addBody( aSingleKunai, 'dynamic' )
            aSingleKunai.isBullet = true
            aSingleKunai.isFixedRotation = true
            aSingleKunai.gravityScale = 0
            aSingleKunai.id = "bullet"
            aSingleKunai:setLinearVelocity( 1500, 0 )

            table.insert(playerKunais, aSingleKunai)
            print("# of bullet: " .. tostring(#playerKunais))
        end
    elseif ( event.phase == "ended" ) then
      
    end
    return true
end


local function onRightArrowTouch( event )
   if ( event.phase == "began" ) then
 	   if ninja.sequence ~= "run" then
 			ninja.sequence = "run"
 			ninja:setSequence( "run" )
 			ninja:play()
 	   end   
   elseif ( event.phase == "ended" ) then
       if ninja.sequence ~= "idle" then
        	ninja.sequence = "idle"
        	ninja:setSequence( "idle" )
        	ninja:play()
       end
   end
   return true
end

 
local moveninja = function( event )
    if ninja.sequence == "run" then
       transition.moveBy( ninja, {
           x = 10,
           y = 0,
           time = 0
     	   } )
    end

    if ninja.sequence == "jump" then
        local ninjaVelocityX, ninjaVelocityY = ninja:getLinearVelocity()

        if ninjaVelocityY == 0 then

            ninja.sequence = "idle"
            ninja:setSequence( "idle" )
            ninja:play()
        end
    end
end 


local checkPlayerKunaisOutOfBounds = function( event )

    local kunaisCounter

    if #playerKunais > 0 then
        for kunaisCounter = #playerKunais, 1, -1 do
            if playerKunais[kunaisCounter].x > display.contentWidth * 2 then
                playerKunais[kunaisCounter]:removeSelf()
                playerKunais[kunaisCounter] = nil
                table.remove(playerKunais, kunaisCounter)
                print("remove kunais")
            end
        end
    end
end

local function ememyShot( event )
 
    if ( event.phase == "began" ) then
 
        local obj1 = event.object1
        local obj2 = event.object2
        local whereCollisonOccurredX = obj1.x
        local whereCollisonOccurredY = obj1.y

        if ( ( obj1.id == "ninja Girl" and obj2.id == "bullet" ) or
             ( obj1.id == "bullet" and obj2.id == "ninja Girl" ) ) then
            -- Remove both the laser and asteroid
            --display.remove( obj1 )
            --display.remove( obj2 )
            
            -- remove the bullet
            local kunaisCounter = nil
            
            for kunaisCounter = #playerKunais, 1, -1 do
                if ( playerKunais[kunaisCounter] == obj1 or playerKunais[kunaisCounter] == obj2 ) then
                    playerKunais[kunaisCounter]:removeSelf()
                    playerKunais[kunaisCounter] = nil
                    table.remove( playerKunais, kunaisCounter )
                    break
                end
            end

            --remove character
            ninjaGirl.sequence = "dead"
            ninjaGirl:setSequence( "dead" )
            ninjaGirl:play()
            
            
            transition.to( ninjaGirl, { time=4000, x=x, y=y, alpha = 0} )

            timer.performWithDelay( 5000, removeninjaGirl)
            
           

            -- make an explosion sound effect
            local expolsionSound = audio.loadStream( "./assets/sounds/8bit_bomb_explosion.wav" )
            local explosionChannel = audio.play( expolsionSound )

            -- make an explosion happen
            -- Table of emitter parameters
            local emitterParams = {
                startColorAlpha = 1,
                startParticleSizeVariance = 250,
                startColorGreen = 0.3031555,
                yCoordFlipped = -1,
                blendFuncSource = 770,
                rotatePerSecondVariance = 153.95,
                particleLifespan = 0.7237,
                tangentialAcceleration = -1440.74,
                finishColorBlue = 0.3699196,
                finishColorGreen = 0.5443883,
                blendFuncDestination = 1,
                startParticleSize = 400.95,
                startColorRed = 0.8373094,
                textureFileName = "./assets/sprites/fire.png",
                startColorVarianceAlpha = 1,
                maxParticles = 256,
                finishParticleSize = 540,
                duration = 0.25,
                finishColorRed = 1,
                maxRadiusVariance = 72.63,
                finishParticleSizeVariance = 250,
                gravityy = -671.05,
                speedVariance = 90.79,
                tangentialAccelVariance = -420.11,
                angleVariance = -142.62,
                angle = -244.11
            }
            local emitter = display.newEmitter( emitterParams )
            emitter.x = whereCollisonOccurredX
            emitter.y = whereCollisonOccurredY

        end
    end
end

   
-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------
 
-- create()
function scene:create( event )
 
    local sceneGroup = self.view
    -- start physics
    physics.start()
    physics.setGravity(0, 32)
    physics.setDrawMode("normal")
    
    local filename = "assets/maps/level0.json"
    local mapData = json.decodeFile( system.pathForFile( filename, system.ResourceDirectory ) )
    map = tiled.new( mapData, "assets/maps" )

    sceneGroup:insert( map )
     
    local sheetOptionsIdle = require("assets.spritesheets.ninjaBoy.ninjaBoyIdle")
    local sheetIdleninja = graphics.newImageSheet( "./assets/spritesheets/ninjaBoy/ninjaBoyIdle.png", sheetOptionsIdle:getSheet() )

    local sheetOptionsRun = require("assets.spritesheets.ninjaBoy.ninjaBoyRun")
    local sheetRunningninja = graphics.newImageSheet( "./assets/spritesheets/ninjaBoy/ninjaBoyRun.png", sheetOptionsRun:getSheet() )
    
    local sheetOptionsJump = require("assets.spritesheets.ninjaBoy.ninjaBoyJump")
    local sheetJumpingninja = graphics.newImageSheet( "./assets/spritesheets/ninjaBoy/ninjaBoyJump.png", sheetOptionsJump:getSheet() )

    local sheetOptionsThrow = require("assets.spritesheets.ninjaBoy.ninjaBoyThrow")
    local sheetThrowingninja = graphics.newImageSheet( "./assets/spritesheets/ninjaBoy/ninjaBoyThrow.png", sheetOptionsThrow:getSheet() )

    
    local sequence_data = {

        {
            name = "idle",
            start = 1,
            count = 10,
            time = 800,
            loopCount = 0,
            sheet = sheetIdleninja
        },
        {
            name = "run",
            start = 1,
            count = 10,
            time = 1000,
            loopCount = 1,
            sheet = sheetRunningninja
        },
        {
            name = "jump",
            start = 1,
            count = 10,
            time = 900,
            loopCount = 1,
            sheet = sheetJumpingninja
        },
        {
            name = "throw",
            start = 1,
            count = 10,
            time = 1000,
            loopCount = 1,
            sheet = sheetThrowingninja
        },
    }
    
    ninja = display.newSprite( sheetIdleninja, sequence_data )
    physics.addBody( ninja, "dynamic", { density = 3, bounce = 0, friction = 1.0 } )
    ninja.isFixedRotation = true
    ninja.x = display.contentWidth * .5
    ninja.y = 0
    ninja:setSequence( "idle" )
    ninja.sequence = "idle"
    ninja:play()

    local sheetOptionsIdle2 = require("assets.spritesheets.ninjaGirl.ninjaGirlIdle")
    local sheetIdleninjaGirl = graphics.newImageSheet( "./assets/spritesheets/ninjaGirl/ninjaGirlIdle.png", sheetOptionsIdle2:getSheet() )

    local sheetOptionsDead = require("assets.spritesheets.ninjaGirl.ninjaGirlDead")
    local sheetDeadninjaGirl = graphics.newImageSheet( "./assets/spritesheets/ninjaGirl/ninjaGirlDead.png", sheetOptionsDead:getSheet() )
    
        
    
    local sequence_data = {
        {
            name = "idle",
            start = 1,
            count = 10,
            time = 1000,
            loopCount = 0,
            sheet = sheetIdleninjaGirl
        },
        {
            name = "dead",
            start = 1,
            count = 10,
            time = 1000,
            loopCount = 1,
            sheet = sheetDeadninjaGirl
        },
    }
    
    ninjaGirl = display.newSprite( sheetIdleninjaGirl, sequence_data )
    physics.addBody( ninjaGirl, "dynamic", { density = 3, bounce = 0, friction = 1.0 } )
    ninjaGirl.isFixedRotation = true
    ninjaGirl.id = "ninja Girl"
    ninjaGirl.sequence = "idle"
    ninjaGirl.x = display.contentWidth - 250
    ninjaGirl.y = display.contentCenterY
    ninjaGirl:setSequence( "idle" )
    ninjaGirl:play()

    rightArrow = display.newImage( "./assets/sprites/rightButton.png")
    rightArrow.x = 260
    rightArrow.y = display.contentHeight - 200
    rightArrow.id = "right arrow"
    rightArrow.Alpha = 0.5

    jumpButton = display.newImage( "./assets/sprites/jumpButton.png" )
    jumpButton.x = display.contentWidth - 80
    jumpButton.y = display.contentHeight - 80
    jumpButton.id = "jump button"
    jumpButton.alpha = 0.5

    shootButton = display.newImage( "./assets/sprites/jumpButton.png" )
    shootButton.x = display.contentWidth - 250
    shootButton.y = display.contentHeight - 80
    shootButton.id = "shootButton"
    shootButton.alpha = 0.5

    sceneGroup:insert( map )
    sceneGroup:insert( ninja )
    sceneGroup:insert( ninjaGirl )
    sceneGroup:insert( rightArrow )
    sceneGroup:insert( jumpButton )
    sceneGroup:insert( shootButton )

    end

-- show()
function scene:show( event )
 
    local sceneGroup = self.view
    local phase = event.phase
    
    if ( phase == "will" ) then
    	jumpButton:addEventListener( "touch", onJumpButtonTouch )
        shootButton:addEventListener( "touch", onShootButtonTouch )
    	rightArrow:addEventListener( "touch", onRightArrowTouch )
 
    elseif ( phase == "did" ) then
    	Runtime:addEventListener( "enterFrame", moveninja )
    	Runtime:addEventListener( "collision", ememyShot )
    	Runtime:addEventListener( "enterFrame", checkPlayerKunaisOutOfBounds )
    end
end
 
 
-- hide()
function scene:hide( event )
 
    local sceneGroup = self.view
    local phase = event.phase
 
    if ( phase == "will" ) then
        -- Code here runs when the scene is on screen (but is about to go off screen)

 
    elseif ( phase == "did" ) then
        -- Code here runs immediately after the scene goes entirely off screen
        rightArrow:removeEventListener( "touch", onRightArrowTouch )
        shootButton:removeEventListener( "touch", onShootButtonTouch )
        jumpButton:removeEventListener( "touch", onJumpButtonTouch )
        
        Runtime:removeEventListener( "enterFrame", moveninja )
        Runtime:removeEventListener( "enterFrame", checkPlayerKunaisOutOfBounds )
        Runtime:removeEventListener( "collision", ememyShot )
    end
end
 
 
-- destroy()
function scene:destroy( event )
 
    local sceneGroup = self.view
    -- Code here runs prior to the removal of scene's view
 
end
 
 
-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------
 
return scene