--=====================================================
-- talk.lua
-- Minimal author API for Dialogue NPCs with PROG-default UI
--=====================================================

local Direction = require("scripts/libs/direction")
local Dialogue  = require("scripts/net-games/dialogue/dialogue")
local Presets   = require("scripts/net-games/npcs/talk_presets")

local Talk = {}

--=====================================================
-- Small table helpers
--=====================================================
local function shallow_copy(t)
  local o = {}
  if t then for k, v in pairs(t) do o[k] = v end end
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

local function normalize_script(lines_or_text)
  if type(lines_or_text) == "string" then
    return { lines_or_text }
  elseif type(lines_or_text) == "table" then
    return lines_or_text
  end
  return { "..." }
end

local function stable_box_id(cfg)
  if cfg.box_id then return tostring(cfg.box_id) end
  local area = tostring(cfg.area_id or "default")
  local obj  = tostring(cfg.object or "npc")
  return "talk_" .. area .. "_" .. obj
end

local function force_indicator_on(player_id, box_id)
  if not (Displayer and Displayer.Text and Displayer.Text.getTextBoxData) then return end
  local bd = Displayer.Text.getTextBoxData(player_id, box_id)
  if bd and bd.backdrop and bd.backdrop.indicator then
    bd.backdrop.indicator.enabled = true
  end
end

--=====================================================
-- build_ui(cfg, bot_name, opts)
-- opts.mode = "dialogue" | "prompt"
--=====================================================
local function build_ui(cfg, bot_name, opts)
  opts = opts or {}

  -- 1) Choose pack (default = prog)
  local pack_key = cfg.preset or cfg.pack or "prog"
  local pack = Presets.packs[pack_key] or Presets.packs.prog

  -- 2) Choose component presets
  local box_key = cfg.box or pack.box or "panel"
  local mug_key = cfg.mug or pack.mug
  local np_key  = cfg.nameplate or pack.nameplate

  local ui = {}

  -- Box (base)
  local box = Presets.boxes[box_key] or Presets.boxes.panel
  deep_merge(ui, shallow_copy(box))

  -- IMPORTANT: keep a real table instance for backdrop (and its nested indicator table)
  ui.backdrop = shallow_copy(box.backdrop)
  deep_merge(ui.backdrop, box.backdrop)

  -- Frame dye optional: switches backdrop style + applies tint values
  -- We ALSO want to propagate this to the nameplate (later), so keep a resolved table.
  local resolved_frame = nil
  if cfg.frame then
    local frame = Presets.frames[cfg.frame] or cfg.frame
    ui.backdrop.style = "textbox_panel_frame_tint"
    if type(frame) == "table" then
      ui.backdrop.r = frame.r
      ui.backdrop.g = frame.g
      ui.backdrop.b = frame.b
      ui.backdrop.a = frame.a
      ui.backdrop.color_mode = frame.color_mode
      resolved_frame = frame
    end
  end

  -- Mugshot
  if mug_key == false then
    ui.mugshot = nil
  elseif mug_key then
    local mug = Presets.mugs[mug_key] or mug_key
    if type(mug) == "table" then
      ui.mugshot = shallow_copy(mug)
    end
  end

  -- Nameplate
  if np_key == false then
    ui.nameplate = nil
  elseif np_key then
    local np = Presets.nameplates[np_key] or np_key
    if type(np) == "table" then
      ui.nameplate = shallow_copy(np)
      ui.nameplate.text = ui.nameplate.text or bot_name

      -- NEW: if textbox frame dye was requested, apply same dye to nameplate overlay frame
      -- (your nameplate.lua reads ui.nameplate.frame.{r,g,b,a,color_mode})
      if resolved_frame then
        ui.nameplate.frame = ui.nameplate.frame or {}
        ui.nameplate.frame.r = resolved_frame.r
        ui.nameplate.frame.g = resolved_frame.g
        ui.nameplate.frame.b = resolved_frame.b
        ui.nameplate.frame.a = resolved_frame.a
        ui.nameplate.frame.color_mode = resolved_frame.color_mode
      end
    end
  end

  -- Stable box id (prompt + dialogue reuse)
  ui.box_id = stable_box_id(cfg)

  -- Per-NPC overrides (last)
  if cfg.ui then
    deep_merge(ui, cfg.ui)

    -- If someone overwrote nameplate, ensure text is still sane unless explicitly set
    if ui.nameplate and ui.nameplate.text == nil then
      ui.nameplate.text = bot_name
    end

    -- Keep stable id unless explicitly overwritten
    ui.box_id = ui.box_id or stable_box_id(cfg)
  end

  -- =====================================================
  -- INDICATOR SAFETY:
  -- Some configs accidentally replace backdrop without carrying indicator.
  -- We restore the preset indicator unless the author explicitly disabled it.
  -- =====================================================
  if ui.backdrop then
    local base_ind = box and box.backdrop and box.backdrop.indicator

    if ui.backdrop.indicator == nil and base_ind then
      ui.backdrop.indicator = shallow_copy(base_ind)
    end

    if ui.backdrop.indicator and ui.backdrop.indicator.enabled == nil then
      ui.backdrop.indicator.enabled = true
    end
  end

  return ui
end


--=====================================================
-- Talk API (what authors should use)
--=====================================================

-- Talk.start(player_id, script, cfg, bot_name)
-- Most callers won't use this directly; Talk.npc() does.
function Talk.start(player_id, script, cfg, bot_name, extra_opts)
  cfg = cfg or {}
  local ui = build_ui(cfg, bot_name or (cfg.name or ""))
  local lines = normalize_script(script)

  local o = {
    page_advance = cfg.page_advance or "wait_for_confirm",
    confirm_during_typing = (cfg.confirm_during_typing ~= false),
    cancel_behavior = cfg.cancel_behavior or "battle_network",

    -- These matter mainly when chaining from prompts
    from_prompt = (cfg.from_prompt == true),
    reuse_existing_box = (cfg.reuse_existing_box == true),

    ui = ui,
    on_finish = cfg.on_finish,
    debug = cfg.debug,
  }

  if extra_opts then
    deep_merge(o, extra_opts)
  end

  -- Ensure indicator is ON if reusing existing box from prompt
  if o.from_prompt and o.reuse_existing_box and ui and ui.box_id then
    force_indicator_on(player_id, ui.box_id)
  end

  return Dialogue.start(player_id, lines, o)
end

-- Talk.prompt_yesno(player_id, question, cfg, bot_name, handlers)
-- handlers = { on_yes = fn, on_no = fn, on_cancel = fn }
function Talk.prompt_yesno(player_id, question, cfg, bot_name, handlers)
  cfg = cfg or {}
  handlers = handlers or {}
  local ui = build_ui(cfg, bot_name or (cfg.name or ""), { mode = "prompt" })

  return Dialogue.prompt_yesno(player_id, {
    question = question or "Continue?",
    cancel_behavior = cfg.prompt_cancel_behavior or cfg.cancel_behavior or "select_no",
    ui = ui,
    on_yes = handlers.on_yes,
    on_no = handlers.on_no,
    on_cancel = handlers.on_cancel,
  })
end

-- Talk.prompt_then_talk(player_id, question, yes_script, no_script, cfg, bot_name)
function Talk.prompt_then_talk(player_id, question, yes_script, no_script, cfg, bot_name)
  cfg = cfg or {}

  return Talk.prompt_yesno(player_id, question, cfg, bot_name, {
    on_yes = function()
      local next_cfg = shallow_copy(cfg)
      next_cfg.from_prompt = true
      next_cfg.reuse_existing_box = true
      Talk.start(player_id, yes_script, next_cfg, bot_name)
    end,
    on_no = function()
      local next_cfg = shallow_copy(cfg)
      next_cfg.from_prompt = true
      next_cfg.reuse_existing_box = true
      Talk.start(player_id, no_script, next_cfg, bot_name)
    end,
    on_cancel = cfg.on_cancel,
  })
end

--=====================================================
-- Talk.npc(cfg)
-- Minimal NPC wiring with sane defaults.
--
-- Authors should only need:
--   cfg.area_id, cfg.object, (optional) cfg.name, cfg.lines
--
-- Optional:
--   cfg.preset / cfg.box / cfg.mug / cfg.nameplate / cfg.frame
--   cfg.ui overrides (mugshot off, tweak offsets, etc.)
--   cfg.prompt = { question, yes_lines, no_lines }
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

  local BOT_NAME = Net.get_bot_name(bot_id)

  Net:on("actor_interaction", function(event)
    if event.actor_id ~= bot_id then return end

    local player_id = event.player_id
    if Dialogue.is_active(player_id) then return end

    -- Face the player
    local player_pos = Net.get_player_position(player_id)
    Net.set_bot_direction(bot_id, Direction.from_points(bot_pos, player_pos))

    -- Custom handler override (advanced users)
    if type(cfg.on_interact) == "function" then
      cfg.on_interact(player_id, bot_id, BOT_NAME)
      return
    end

    -- Prompt flow (optional)
    if cfg.prompt then
      local p = cfg.prompt
      Talk.prompt_then_talk(
        player_id,
        p.question or "Continue?",
        p.yes_lines or p.on_yes_lines or { "..." },
        p.no_lines  or p.on_no_lines  or { "..." },
        cfg,
        BOT_NAME
      )
      return
    end

    -- Normal dialogue
    local lines = cfg.lines or cfg.text or { "..." }
    Talk.start(player_id, lines, cfg, BOT_NAME)
  end)

  return bot_id
end

return Talk
