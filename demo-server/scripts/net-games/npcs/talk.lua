--=====================================================
-- talk.lua
-- "Translator" / builder for easy Dialogue NPC scripts
--=====================================================

local Direction = require("scripts/libs/direction")
local Dialogue  = require("scripts/net-games/dialogue/dialogue")
local Presets   = require("scripts/net-games/npcs/talk_presets")

local Talk = {}

local function shallow_copy(t)
  local o = {}
  if t then
    for k, v in pairs(t) do o[k] = v end
  end
  return o
end

local function deep_merge(dst, src)
  if not src then return dst end
  for k, v in pairs(src) do
    if type(v) == "table" and type(dst[k]) == "table" then
      deep_merge(dst[k], v)
    else
      dst[k] = v
    end
  end
  return dst
end

local function build_ui(cfg)
  local ui = {}

  -- box preset
  local box_key = cfg.box or "panel"
  local box = Presets.boxes[box_key] or Presets.boxes.panel
  deep_merge(ui, shallow_copy(box))
  ui.backdrop = shallow_copy(box.backdrop)
  deep_merge(ui.backdrop, box.backdrop)

  -- frame dye preset: switches backdrop style + applies tint values
  if cfg.frame then
    local frame = Presets.frames[cfg.frame] or cfg.frame
    ui.backdrop.style = "textbox_panel_frame_tint"  -- requires your dual-draw style
    if type(frame) == "table" then
      ui.backdrop.r = frame.r
      ui.backdrop.g = frame.g
      ui.backdrop.b = frame.b
      ui.backdrop.a = frame.a
      ui.backdrop.color_mode = frame.color_mode
    end
  end

  -- mug preset
  if cfg.mug then
    local mug = Presets.mugs[cfg.mug] or cfg.mug
    if type(mug) == "table" then
      ui.mugshot = shallow_copy(mug)
    end
  end

  -- per-NPC overrides (optional)
  if cfg.ui then
    deep_merge(ui, cfg.ui)
  end

  -- stable default box_id if none provided
  ui.box_id = ui.box_id or ("talk_box_" .. tostring(cfg.object or "npc"))

  return ui
end

--=====================================================
-- Talk.npc(cfg)
-- Spawns + wires a Dialogue NPC from a tiny config
--=====================================================
function Talk.npc(cfg)
  assert(cfg and cfg.object, "[Talk.npc] cfg.object required (Tiled object name)")

  local area_id  = cfg.area_id or "default"
  local obj_name = cfg.object

  local bot_pos = Net.get_object_by_name(area_id, obj_name)
  assert(bot_pos, "[Talk.npc] Missing Tiled object named '" .. obj_name .. "' in area: " .. tostring(area_id))

  local bot_id = Net.create_bot({
    name = cfg.name or obj_name,
    area_id = area_id,
    texture_path = cfg.texture_path or "/server/assets/ow/prog/prog_ow.png",
    animation_path = cfg.animation_path or "/server/assets/ow/prog/prog_ow.animation",
    x = bot_pos.x,
    y = bot_pos.y,
    z = bot_pos.z or 0,
    direction = cfg.direction or Direction.Down,
    solid = (cfg.solid ~= false),
  })

  -- interaction -> Dialogue.start
  Net:on("actor_interaction", function(event)
    if event.actor_id ~= bot_id then return end

    local player_id = event.player_id
    if Dialogue.is_active(player_id) then return end

    -- face the player
    local player_pos = Net.get_player_position(player_id)
    Net.set_bot_direction(bot_id, Direction.from_points(bot_pos, player_pos))

    local lines = cfg.lines or cfg.text or { "..." }
    local ui = build_ui(cfg)

    Dialogue.start(player_id, lines, {
      page_advance = cfg.page_advance or "wait_for_confirm",
      confirm_during_typing = (cfg.confirm_during_typing ~= false),
      ui = ui,
      on_finish = cfg.on_finish,
    })
  end)

  return bot_id
end

return Talk
