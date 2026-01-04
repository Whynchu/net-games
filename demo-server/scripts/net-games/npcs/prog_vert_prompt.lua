--=====================================================
-- prog_vert_prompt.lua
-- Vertical prompt demo PROG (basic style, like prog_basic_nameplate)
--=====================================================

local Direction = require("scripts/libs/direction")
require("scripts/net-games/dialogue/startup")

local Dialogue       = require("scripts/net-games/dialogue/dialogue")
local PromptVertical = require("scripts/net-games/dialogue/prompt_vertical")

--=====================================================
-- Area / placement (must match your TMX object name)
--=====================================================
local area_id  = "default"
local obj_name = "ProgVertPrompt" -- create a Tiled object with THIS exact name

local bot_pos = Net.get_object_by_name(area_id, obj_name)
assert(bot_pos, "[prog_vert_prompt] Missing Tiled object named '" .. obj_name .. "' in area: " .. tostring(area_id))

local bot_id = Net.create_bot({
  name = "PROG.EXE",
  area_id = area_id,
  texture_path = "/server/assets/ow/prog/prog_ow.png",
  animation_path = "/server/assets/ow/prog/prog_ow.animation",
  x = bot_pos.x,
  y = bot_pos.y,
  z = bot_pos.z or 0,
  direction = Direction.Down,
  solid = true,
})

local BOT_NAME = Net.get_bot_name(bot_id)

--=====================================================
-- Options
--=====================================================
local function build_options()
  local t = {}
  for i = 1, 12 do
    t[#t+1] = { id = i, text = ("Option %02d"):format(i) }
  end
  t[#t+1] = { id = "exit", text = "Exit" }
  return t
end

--=====================================================
-- Interaction
--=====================================================
Net:on("actor_interaction", function(event)
  if event.actor_id ~= bot_id then return end
  if event.button ~= 0 then return end -- A / confirm

  local player_id = event.player_id
  if Dialogue.is_active(player_id) then return end

  -- Face the player (same nice touch as prog_basic_nameplate)
  local player_pos = Net.get_player_position(player_id)
  Net.set_bot_direction(bot_id, Direction.from_points(bot_pos, player_pos))

  PromptVertical.menu(player_id, {
    ui = {
      box_id = "prog_vert_prompt_box",
      font = "THIN_BLACK",
      scale = 2.0,
      z = 100,
      typing_speed = 12,
      type_sfx_path = "/server/assets/net-games/sfx/text.ogg",
      type_sfx_min_dt = 0.05,


      -- Optional: BN-ish backdrop like your other PROGs (keep simple here)
      backdrop = {
        render_offset_x = 3,
        render_offset_y = 46,
        style = "textbox_panel",
        open_seconds = 0.20,
        x = 1,
        y = 209,
        width = 478,
        height = 104,
        padding_x = 16,
        padding_y = 4,
        max_lines = 3,
        indicator = { enabled = true, width = 2, height = 2, offset_x = 24, offset_y = 26 },
      },

      nameplate = {
        text = BOT_NAME,
        anchor = "above",
        align = "left",
        gap_x = 6,
        gap_y = 59,
        dur = 0.20,
        close_dur = 0.20,
        bob_amp = 1.2,
        bob_speed = 2,
      },
    },

    layout = {
      anchor = "textbox",
      offset_x = 2,
      offset_y = -200,
      width = 160,
      height = 64,
      visible_rows = 5,
      row_height = 14,
      padding_x = 48,
      padding_y = 4,
      scrollbar_x = 452,
      scrollbar_y = 12,
      scrollbar_h = 90,
      highlight_inset_x = 12, -- + = starts farther right
      highlight_inset_y = 3, -- + = down (scaled)
      cursor_offset_x = 16, -- + = right
      cursor_offset_y = 4, -- + = down (scaled by layout.scale)


    },

    question = "DEFAULT PROG ONLINE{p_2}\nSIR,{p_2.2} This is the very definition of overkill... BUT LETS TAKE A LOOK SHALL WE?!",
    options = build_options(),
    default_index = 1,

    cancel_behavior = "jump_to_exit",
    exit_index = 13,

    keep_textbox = true,

on_select = function(choice, index)
  Dialogue.start(player_id, {
    "You picked: " .. tostring(choice.text) .. " (index " .. tostring(index) .. ")",
  }, {
    reuse_existing_box = true,
    ui = {
      box_id = "prog_vert_prompt_box",
      font = "THIN_BLACK",
      scale = 2.0,
      z = 100,
      typing_speed = 12,

      backdrop = {
        render_offset_x = 3,
        render_offset_y = 46,
        style = "textbox_panel",
        open_seconds = 0.20,
        x = 1,
        y = 209,
        width = 478,
        height = 104,
        padding_x = 16,
        padding_y = 4,
        max_lines = 3,
        indicator = { enabled = true, width = 2, height = 2, offset_x = 24, offset_y = 26 },
      },

      nameplate = {
        text = BOT_NAME,
        anchor = "above",
        align = "left",
        gap_x = 6,
        gap_y = 59,
        dur = 0.20,
        close_dur = 0.20,
        bob_amp = 1.2,
        bob_speed = 2,
      },
    },
  })
end,

  })
end)
