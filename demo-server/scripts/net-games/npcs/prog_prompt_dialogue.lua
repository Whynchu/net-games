--=====================================================
-- prog_prompt_dialogue.lua
-- Tiled-spawned NPC that shows a YES/NO prompt using
-- the SAME textbox_panel UI as prog_basic_dialogue.lua,
-- then follows up with Dialogue.start.
--=====================================================

local Direction = require("scripts/libs/direction")
local Dialogue  = require("scripts/net-games/dialogue/dialogue")

local DEBUG = false
local function dbg(msg)
  if DEBUG then print("[prog_prompt_dialogue] " .. tostring(msg)) end
end

--=====================================================
-- Area / placement (must match your TMX object)
--=====================================================
local area_id  = "default"
local obj_name = "ProgPromptDialogue" -- <-- create a Tiled object with this exact name

local bot_pos = Net.get_object_by_name(area_id, obj_name)
assert(bot_pos, "[prog_prompt_dialogue] Missing Tiled object named '" .. obj_name .. "' in area: " .. tostring(area_id))

local bot_id = Net.create_bot({
  name = "Prompt Prog",
  area_id = area_id,
  texture_path = "/server/assets/ow/prog/prog_ow.png",
  animation_path = "/server/assets/ow/prog/prog_ow.animation",
  x = bot_pos.x,
  y = bot_pos.y,
  z = bot_pos.z or 0,
  direction = Direction.Down,
  solid = true,
})

dbg("LOADED bot_id=" .. tostring(bot_id))

--=====================================================
-- Shared UI (clone of prog_basic_dialogue.lua settings)
--=====================================================
local function basic_prog_ui(box_id)
  return {
    box_id = box_id,
    font = "THIN_BLACK",
    scale = 2.0,
    z = 100,
    typing_speed = 30,
    type_sfx_path = "/server/assets/net-games/sfx/text.ogg",
    type_sfx_min_dt = 0.05,

    backdrop = {
      render_offset_x = 3,
      render_offset_y = 46,
      style = "textbox_panel",
      x = 1,
      y = 209,
      width = 478,
      height = 104,
      padding_x = 16,
      padding_y = 4,
      max_lines = 3,

      indicator = {
        enabled = true,
        width = 2,
        height = 2,
        offset_x = 24,
        offset_y = 26,
        indicator_timer = 0,
        indicator_base_x = nil,
        indicator_base_y = nil,
      },
    },

    -- Keep mugshot consistent with prog_basic
    mugshot = {
      enabled = true,
      texture_path = "/server/assets/ow/prog/prog_mug.png",
      anim_path = "/server/assets/ow/prog/prog_mug.animation",
      talk_anim_state = "TALK",
      idle_anim_state = "IDLE",
      reserve_w = 40,
      reserve_h = 40,

      offset_x = 6,
      offset_y = -46,

      gap_px = 6,
      sprite_id = 5300,
      z_bias = 50,
    },
  }
end

--=====================================================
-- Interaction handler
--=====================================================
Net:on("actor_interaction", function(event)
  if event.actor_id ~= bot_id then return end

  local player_id = event.player_id
  if Dialogue.is_active(player_id) then
    -- already in dialogue/prompt; ignore retriggers
    return
  end

  -- Face the player
  local player_pos = Net.get_player_position(player_id)
  Net.set_bot_direction(bot_id, Direction.from_points(bot_pos, player_pos))

  -- YES/NO prompt using the SAME textbox_panel UI
  -- IMPORTANT: unique box_id vs the follow-up dialogue box_id
  Dialogue.prompt_yesno(player_id, {
    question = "Want to check out my themes?",

    ui = basic_prog_ui("prog_prompt_yesno_box"),

    on_yes = function()
      Dialogue.start(player_id, {
        "Sweet. This NPC is strictly for tuning the textbox UI.",
        "Prompt used textbox_panel + THIN_BLACK, same as basic prog.",
        "Next: we wire theme selection without breaking sizing/cursor. :] ",
      }, {
        page_advance = "wait_for_confirm",
        confirm_during_typing = true,
        ui = basic_prog_ui("prog_prompt_followup_box"),
      })
    end,

    on_no = function()
      Dialogue.start(player_id, {
        "All good.",
        "Come back when you want to poke the textbox UI again. :] ",
      }, {
        page_advance = "wait_for_confirm",
        confirm_during_typing = true,
        ui = basic_prog_ui("prog_prompt_no_box"),
      })
    end,

    on_cancel = function()
      -- Silent cancel (no extra chatter)
    end,
  })
end)
