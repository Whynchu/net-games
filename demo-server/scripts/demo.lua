
--[[
* ---------------------------------------------------------- *
          Net Games Demo by Indiana - Version 0.06
	      https://github.com/indianajson/net-games 
* ---------------------------------------------------------- *
]]--

--the below line is required to access net-games functions
local games = require("scripts/net-games/framework")

--------------------------------------------------------------
-- DEMO CODE FOR THE BAT NPC THAT SPAWNS THE ORDER POINT UI --
--------------------------------------------------------------

local marquee_active = {}

Net.create_bot("marquee_demo", { 
    area_id="default", 
    warp_in=false, 
    texture_path="/server/assets/demo/cyber_bat.png", 
    animation_path="/server/assets/demo/cyber_bat.animation", 
    x=24, y=21, z=0, 
    solid=true
})

-- Update the marquee creation in demo.lua to be simpler:
local backdrop_config = {
    x = 10,        -- Just set backdrop position
    y = 10,        -- Text will be automatically centered
    width = 220,    
    height = 30,    -- Backdrop height (text will be centered within this)
    padding_x = 4,  -- Horizontal padding only
    -- No need to worry about padding_y for vertical centering anymore
}

Net:on("actor_interaction", function (event)
    local marque_npc_check = false
    -- Add new marquee demo interaction
    if event.actor_id == "marquee_demo" and event.button == 0 then
        games.draw_marquee_text("demo_marquee", event.player_id, 
        "Welcome  to  the  Net  Games  Demo!  This  text  has  proper  spacing!", 
        0, -- This y is ignored when backdrop is provided, but kept for API consistency
        "THICK", 2.0, 100, "medium", backdrop_config)
        marquee_active[event.player_id] = true
        Net.message_player(event.player_id, "Marquee text activated! Watch it scroll across the screen.","","") 
    end
end)

Net:on("actor_interaction", function(event)
    if event.actor_id == "marquee_demo" and event.button == 0 then
        -- Create a marquee with backdrop
        local backdrop_config = {
            x = 0,        -- X position of backdrop
            y = 210,        -- Y position of backdrop  
            width = 220,    -- Width of backdrop
            height = 30,    -- Height of backdrop
            padding_x = 10,  -- Padding inside backdrop
            padding_y = 2   -- Padding inside backdrop
        }
        
        games:draw_marquee_text("demo_marquee", event.player_id, "Welcome to the Net Games Demo! This is a scrolling marquee text!", 15, "THICK", 2.0, 100, "medium", backdrop_config)
        marquee_active[event.player_id] = true
        Net.message_player(event.player_id, "Marquee text activated! Watch it scroll across the screen.") 
    end
end)

local bat_active = {} 

Net.create_bot("bat", { area_id="default", warp_in=false, texture_path="/server/assets/demo/cyber_bat.png", animation_path="/server/assets/demo/cyber_bat.animation", x=26, y=21, z=0, solid=true})

Net:on("button_press", function(event)
    if event.button == "LS" and bat_active[event.player_id] == true then
        if points > 0 then
            points = points - 1 
            games.set_ui_animation("points",event.player_id,tostring(points.."POINT"),true)
        else 
            points = 8
            games.set_ui_animation("points",event.player_id,tostring(points.."POINT"),true)
        end 
    end
        
end)

Net:on("actor_interaction", function (event)

    if event.actor_id == "bat" and event.button == 0 and bat_active[event.player_id] == false then
        points = 8
        Net.message_player(event.player_id, "I grant you 8 Order Points. Press LS to reduce them. Talk to me again to remove it.","","") 
        games.add_ui_element("points",event.player_id,"/server/assets/demo/order_points.png","/server/assets/demo/order_points.animation","8POINT",161,2,0)
        bat_active[event.player_id] = true

    elseif event.actor_id == "bat" and event.button == 0 and bat_active[event.player_id] == true then
        Net.message_player(event.player_id, "Let me get rid of that UI for you.","","") 
        games.remove_ui_element("points",event.player_id)
        bat_active[event.player_id] = false
    end
end)

Net:on("player_join", function(event)
    bat_active[event.player_id] = false
    marquee_active[event.player_id] = false
end)

Net:on("player_disconnect", function(event)
    bat_active[event.player_id] = false
    marquee_active[event.player_id] = nil
end)

----------------------------------------------------------------------
-- DEMO CODE FOR THE NPC THAT SPAWNS A CURSOR TO CHANGE IT'S AVATAR --
----------------------------------------------------------------------

local points = 8

Net.create_bot("changer", { area_id="default", warp_in=false, texture_path="/server/assets/demo/protoman-bn5.png", animation_path="/server/assets/demo/protoman-bn5.animation", animation="IDLE_DL", x=26, y=19.5, z=0, solid=true})

Net:on("cursor_selection", function(event)
    if event.cursor == "navi_changer" then
        print("Player ".. event.player_id .." used cursor "..event.cursor.." to select "..event.selection)
        games.remove_text("roll_label",event.player_id)
        games.remove_text("megaman_label",event.player_id)
        games.remove_text("protoman_label",event.player_id)
        games.remove_cursor("navi_changer",event.player_id)
        local texture = ""
        local animation = ""
        if event.selection == "protoman" then
            texture = "/server/assets/demo/protoman-bn5.png"
            animation = "/server/assets/demo/protoman-bn5.animation"
        elseif event.selection == "roll" then
            texture = "/server/assets/demo/roll.png"
            animation = "/server/assets/demo/roll.animation"
        elseif event.selection == "megaman" then
            texture = "/server/assets/demo/megaman.png"
            animation = "/server/assets/demo/megaman.animation"    
        end 
        Net.provide_asset_for_player(event.player_id, texture)
        Net.provide_asset_for_player(event.player_id, animation)

        Net.set_bot_avatar("changer",texture,animation)
        local keyframes = {{properties={{property="Animation",value="IDLE_DL"}},duration=0}}
        Net.animate_bot_properties("changer", keyframes)

    end
end)

Net:on("actor_interaction", function (event)

    if event.actor_id == "changer" and event.button == 0 then

        local green_cursor_texture = "/server/assets/net-games/text_cursor.png"
        local green_cursor_anim = "/server/assets/net-games/text_cursor.animation"
        cursor_options = {
            texture=green_cursor_texture,
            animation=green_cursor_anim,
            movement = "vertical", 
            selections = {
                { x=35,y=45,z=0,name='roll',state="CURSOR_RIGHT" },
                { x=35,y=65,z=0,name='megaman',state="CURSOR_RIGHT" },
                { x=35,y=85,z=0,name='protoman',state="CURSOR_RIGHT" }
            }
        }

        games.spawn_cursor("navi_changer",event.player_id,cursor_options)
        games.draw_text("roll_label",event.player_id,"Roll.EXE",40,40,100,"THICK")
        games.draw_text("megaman_label",event.player_id,"Megaman.EXE",40,60,100,"THICK")
        games.draw_text("protoman_label",event.player_id,"Protoman.EXE",40,80,100,"THICK")

    end 
end)
