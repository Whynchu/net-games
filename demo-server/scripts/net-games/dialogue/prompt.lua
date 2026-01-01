-- scripts/net-games/dialogue/prompt.lua
-- YES/NO prompt helper for net-games Dialogue

local Displayer  = require("scripts/net-games/displayer/displayer")
local Input      = require("scripts/net-games/input/input")
local FontSystem = require("scripts/net-games/displayer/font-system")

local Prompt = {}
Prompt.instances = {}
Prompt._tick_attached = false

-- Dedicated sprite id ONLY for the selector cursor (do NOT reuse textbox indicator sprite id)
local SELECTOR_SPRITE_ID = 5200

local LISTENER_ATTACHED = false
local function ensure_listener()
  if LISTENER_ATTACHED then return end
  LISTENER_ATTACHED = true
  Input.attach_virtual_input_listener()
end

local function set_input_locked(player_id, locked)
  if locked then
    if Net.lock_player_input then pcall(function() Net.lock_player_input(player_id) end) end
  else
    if Net.unlock_player_input then pcall(function() Net.unlock_player_input(player_id) end) end
  end
end

local function mk_id(player_id)
  return "ng_prompt_" .. tostring(player_id)
end

local function ensure_tick()
  if Prompt._tick_attached then return end
  Prompt._tick_attached = true

  Net:on("tick", function(event)
    for player_id, inst in pairs(Prompt.instances) do
      local state = Displayer.Text.getTextBoxState(player_id, inst.box_id)
      if not state then
        Prompt.close(player_id, "textbox_missing")
      else
        inst:update(event.delta_time or 0)
      end
    end
  end)
end

--========================
-- Selector cursor drawing
--========================

local function ensure_selector_cursor_allocated(player_id)
  Net.provide_asset_for_player(player_id, "/server/assets/net-games/text_cursor.png")
  Net.provide_asset_for_player(player_id, "/server/assets/net-games/text_cursor.animation")

  Net.player_alloc_sprite(player_id, SELECTOR_SPRITE_ID, {
    texture_path = "/server/assets/net-games/text_cursor.png",
    anim_path    = "/server/assets/net-games/text_cursor.animation",
    anim_state   = "CURSOR_RIGHT",
  })
end

local function selector_draw(player_id, draw_id, x, y, z, scale)
  ensure_selector_cursor_allocated(player_id)

  Net.player_draw_sprite(player_id, SELECTOR_SPRITE_ID, {
    id = draw_id,
    x = x,
    y = y,
    z = z,
    sx = scale,
    sy = scale,
    anim_state = "CURSOR_RIGHT",
  })
end

local function selector_erase(player_id, draw_id)
  Net.player_erase_sprite(player_id, draw_id)
end

--========================
-- UI normalize (padding)
--========================

local function normalize_ui(ui)
  local o = {
    box_id = ui.box_id,
    font  = ui.font or "THIN_BLACK",
    scale = ui.scale or 2.0,
    z     = ui.z or 100,

    x = ui.x or 8,
    y = ui.y or 110,
    w = ui.w or 224,
    h = ui.h or 42,

    backdrop = ui.backdrop or ui.backdrop_config or nil,
    mugshot  = ui.mugshot or nil,

    typing_speed = ui.typing_speed or 99999,
    type_sfx_path = ui.type_sfx_path,
    type_sfx_min_dt = ui.type_sfx_min_dt,
  }

  if o.backdrop then
    local px = o.backdrop.padding_x or 0
    local py = o.backdrop.padding_y or 0
    if o.backdrop.x      then o.x = o.backdrop.x + px end
    if o.backdrop.y      then o.y = o.backdrop.y + py end
    if o.backdrop.width  then o.w = o.backdrop.width  - (px * 2) end
    if o.backdrop.height then o.h = o.backdrop.height - (py * 2) end
  end

  return o
end

--========================
-- Text + positioning
--========================

local OPTIONS_INDENT = "       "  -- 7 spaces (tweak this)

local function build_yesno_text(question)
  return tostring(question or "Continue?") .. "\n" .. OPTIONS_INDENT .. "Yes    No"
end


local function compute_left_indent(ui)
  local mug = ui.mugshot
  if not mug or not mug.enabled then return 0 end
  local reserve_w = (mug.reserve_w or 0)
  local gap = (mug.gap_px or 0)
  return (reserve_w + gap) * ui.scale
end



local function yesno_cursor_pos(player_id, box_id, ui_norm, selection)
  local bd = Displayer.Text.getTextBoxData(player_id, box_id)
  if not bd then
    -- emergency fallback (what you set manually)
    return 20, 120
  end

  local scale  = bd.scale or ui_norm.scale or 2.0
  local font   = bd.font  or ui_norm.font  or "THIN_BLACK"
  local line_h = bd._line_height_px or (12 * scale)

-- Find the actual rendered line that contains our options text
local options_line = 2
if bd.pages and bd.pages[1] then
  local lines = bd.pages[1]
  for i = 1, #lines do
    local s = tostring(lines[i] or "")
    if s:find("Yes") then
      options_line = i
      break
    end
  end
  if options_line < 2 then options_line = 2 end
  if options_line > 3 then options_line = 3 end
end


  -- Start at the textbox's true inner origin
  local base_x = bd.inner_x or ((bd.x or 0) + (bd.padding_x or 0))
  local base_y = bd.inner_y or ((bd.y or 0) + (bd.padding_y or 0))

  -- Apply mugshot indent for that specific line, if present
  if bd.line_x_offsets and bd.line_x_offsets[options_line] then
    base_x = base_x + bd.line_x_offsets[options_line]
  end

  local options_y = base_y + ((options_line - 1) * line_h)

  -- Text we print is: "\n  Yes      No"
local yes_prefix = OPTIONS_INDENT
local no_prefix  = OPTIONS_INDENT .. "Yes    "

  local yes_x = base_x + FontSystem:getTextWidth(yes_prefix, font, scale)
  local no_x  = base_x + FontSystem:getTextWidth(no_prefix,  font, scale)

-- Cursor visual tuning:
-- We want the *triangle tip* just left of the word.
-- Treat cursor origin as "top-left of frame" and use a fixed offset instead of cursor_w math.
local cursor_h = 13 * scale

-- How far left of the word start the cursor should sit (tune this)
local left_of_word = 6 * scale

-- How far down from the line top to visually match the font baseline (tune this)
local down_in_line = 9 * scale

local target_x = (selection == 1) and yes_x or no_x

local cx = target_x - left_of_word
local cy = options_y + down_in_line + ((line_h - cursor_h) * 0.5)

return cx, cy

end

--========================
-- Instance
--========================

local PromptInstance = {}
PromptInstance.__index = PromptInstance

function PromptInstance:new(player_id, opts)
  local o = setmetatable({}, self)

  o.player_id = player_id
  o.box_id = (opts and opts.ui and opts.ui.box_id) or mk_id(player_id)

  o.ui = normalize_ui((opts and opts.ui) or {})
  o.question  = (opts and opts.question) or "Check out my themes?"
  o.on_yes    = (opts and opts.on_yes) or function() end
  o.on_no     = (opts and opts.on_no) or function() end
  o.on_cancel = (opts and opts.on_cancel) or function() end
  o.ready_for_input = false
  o.cursor_visible = false


  o.selection = 1
  o.cursor_id = o.box_id .. "_selcursor"

  o:render_initial()
  return o
end

function PromptInstance:render_initial()
  local ui = self.ui
  local text = build_yesno_text(self.question)

  Displayer.Text.removeTextBox(self.player_id, self.box_id)

  -- We do NOT want the textbox "next" indicator here; prompt has its own selector cursor.
  local ops = {
    page_advance = "auto_advance",
    auto_advance_seconds = 999999,
    confirm_during_typing = false,
    type_sfx_path = ui.type_sfx_path,
    type_sfx_min_dt = ui.type_sfx_min_dt,
    mugshot = ui.mugshot,
    wrap_opts = { allow_leading_spaces = true },
  }

  if Displayer.Text.create_text_box then
    Displayer.Text.create_text_box(
      self.player_id, self.box_id, text,
      ui.x, ui.y, ui.w, ui.h,
      ui.font, ui.scale, ui.z,
      ui.backdrop,
      ui.typing_speed,
      ops
    )

    ---debug
local bd = Displayer.Text.getTextBoxData(self.player_id, self.box_id)
if bd and bd.pages and bd.pages[1] then
  print("[prompt DEBUG] page1_lines=" .. tostring(#bd.pages[1]))
  print("[prompt DEBUG] inner=(" .. tostring(bd.inner_x) .. "," .. tostring(bd.inner_y) .. ")")
end

  else
    Displayer.Text.createTextBox(
      self.player_id, self.box_id, text,
      ui.x, ui.y, ui.w, ui.h,
      ui.font, ui.scale, ui.z,
      ui.backdrop,
      ui.typing_speed,
      ops
    )
  end

end

function PromptInstance:render_cursor()
  local ui = self.ui
  local cx, cy = yesno_cursor_pos(self.player_id, self.box_id, self.ui, self.selection)
  selector_erase(self.player_id, self.cursor_id)
  selector_draw(self.player_id, self.cursor_id, cx, cy, ui.z + 2, ui.scale)
end

function PromptInstance:update(dt)
  local pid = self.player_id
  -- Wait until the textbox is done typing before we show the selector cursor
-- and accept inputs.
if not self.ready_for_input then
  local st = Displayer.Text.getTextBoxState(pid, self.box_id)
  if st == "waiting" or st == "completed" then
    self.ready_for_input = true

-- Only swallow if the player is currently holding confirm/cancel.
-- Otherwise we risk eating their first real press and it feels like "two confirms".
if Input.is_down(pid, "confirm") or Input.is_down(pid, "cancel") then
  Input.consume(pid)
  Input.require_release(pid, { "confirm", "cancel" })
end


    self.cursor_visible = true
    self:render_cursor()
  end
  return
end


local moved = false

if Input.pop(pid, "left") or Input.pop(pid, "right") then
  self.selection = (self.selection == 1) and 2 or 1
  self:render_cursor()
  moved = true
end

-- (optional) if you want to forbid confirm on the same tick as a move:
-- if moved then return end


 if Input.pop(pid, "confirm") then
    Prompt.close(pid, "confirm")
    if self.selection == 1 then self.on_yes() else self.on_no() end
    return
  end

  if Input.pop(pid, "cancel") then
    Prompt.close(pid, "cancel")
    self.on_cancel()
    return
  end
end

--========================
-- Public API
--========================

function Prompt.yesno(player_id, opts)
  ensure_listener()
  ensure_tick()

  if Prompt.instances[player_id] then
    Prompt.close(player_id, "replace")
  end

  -- Prompt owns input while open
  set_input_locked(player_id, true)

  -- Swallow the interaction press
  Input.consume(player_id)


  local inst = PromptInstance:new(player_id, opts or {})
  Prompt.instances[player_id] = inst
  return inst.box_id
end

function Prompt.close(player_id, reason)
  local inst = Prompt.instances[player_id]
  if not inst then return end

  selector_erase(player_id, inst.cursor_id)
  Displayer.Text.removeTextBox(player_id, inst.box_id)

  set_input_locked(player_id, false)

  -- Clean exit: avoid carry-press into world/NPC
Input.consume(player_id)
Input.require_release(player_id, { "confirm", "cancel" })

  Prompt.instances[player_id] = nil
end

return Prompt
