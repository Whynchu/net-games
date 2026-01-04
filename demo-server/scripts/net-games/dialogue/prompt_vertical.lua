-- scripts/net-games/dialogue/prompt_vertical.lua
-- Vertical menu prompt helper for net-games Dialogue
-- - Keeps textbox open (optional handoff)
-- - Draws a separate menu window sprite + option text + cursor/highlight + scrollbar
-- - Supports N options with 3..5 (or any) visible rows via layout.visible_rows

local Displayer  = require("scripts/net-games/displayer/displayer")
local Input      = require("scripts/net-games/input/input")
local FontSystem = require("scripts/net-games/displayer/font-system")

local PromptVertical = {}
PromptVertical.instances = {}
PromptVertical._tick_attached = false

--========================
-- Assets (you said these exist under /server/assets/net-games/ui/)
-- Adjust paths here if your filenames differ.
--========================
local ASSET = {
  menu_bg       = "/server/assets/net-games/ui/prompt_vert_menu.png",
  highlight     = "/server/assets/net-games/ui/highlight_default.png",
  cursor        = "/server/assets/net-games/ui/green_cursor.png",
  scrollbar     = "/server/assets/net-games/ui/scrollbar.png",
}

--========================
-- Dedicated sprite IDs (do NOT collide with textbox internals)
--========================
local SPR = {
  MENU_BG   = 5400,
  HILITE    = 5401,
  CURSOR    = 5402,
  SCROLL    = 5403,
}

local CURSOR_MOVE_SFX_PATH = "/server/assets/net-games/sfx/cursor_move.ogg"
local function play_cursor_move_sfx(player_id)
  Net.provide_asset_for_player(player_id, CURSOR_MOVE_SFX_PATH)
  if Net.play_sound_for_player then
    pcall(function() Net.play_sound_for_player(player_id, CURSOR_MOVE_SFX_PATH) end)
  elseif Net.play_sound then
    pcall(function() Net.play_sound(player_id, CURSOR_MOVE_SFX_PATH) end)
  end
end

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
  return "ng_prompt_menu_" .. tostring(player_id)
end

local function clamp(v, a, b)
  if v < a then return a end
  if v > b then return b end
  return v
end

local function ensure_tick()
  if PromptVertical._tick_attached then return end
  PromptVertical._tick_attached = true

  Net:on("tick", function(event)
    for player_id, inst in pairs(PromptVertical.instances) do
      -- If textbox got removed externally, kill prompt safely
      local state = Displayer.Text.getTextBoxState(player_id, inst.box_id)
      if not state then
        PromptVertical.close(player_id, "textbox_missing")
      else
        inst:update(event.delta_time or 0)
      end
    end
  end)
end

--========================
-- Sprite allocation helpers
--========================
local function provide_ui_assets(player_id)
  Net.provide_asset_for_player(player_id, ASSET.menu_bg)
  Net.provide_asset_for_player(player_id, ASSET.highlight)
  Net.provide_asset_for_player(player_id, ASSET.cursor)
  Net.provide_asset_for_player(player_id, ASSET.scrollbar)
end

local function alloc_ui_sprites(player_id)
  provide_ui_assets(player_id)

  -- All are static textures (no anim)
  Net.player_alloc_sprite(player_id, SPR.MENU_BG, { texture_path = ASSET.menu_bg })
  Net.player_alloc_sprite(player_id, SPR.HILITE,  { texture_path = ASSET.highlight })
  Net.player_alloc_sprite(player_id, SPR.CURSOR,  { texture_path = ASSET.cursor })
  Net.player_alloc_sprite(player_id, SPR.SCROLL,  { texture_path = ASSET.scrollbar })
end

local function draw_sprite(player_id, sprite_id, draw_id, x, y, z, s)
  alloc_ui_sprites(player_id)

  Net.player_draw_sprite(player_id, sprite_id, {
    id = draw_id,
    x = x, y = y, z = z,
    sx = s or 2.0,
    sy = s or 2.0,
  })
end


local function erase_sprite(player_id, draw_id)
  Net.player_erase_sprite(player_id, draw_id)
end

--========================
-- Layout normalization
--========================
local function normalize_ui(ui)
  -- This is the textbox UI, same pattern as prompt.lua
  local o = {
    box_id = ui.box_id,
    font  = ui.font or "THIN_BLACK",
    scale = ui.scale or 2.0,
    z     = ui.z or 100,

    x = ui.x or 8,
    y = ui.y or 110,
    w = ui.w or 224,
    h = ui.h or 42,

    backdrop  = ui.backdrop or ui.backdrop_config or nil,
    mugshot   = ui.mugshot or nil,
    nameplate = ui.nameplate,

    typing_speed    = ui.typing_speed or 12,
    type_sfx_path   = ui.type_sfx_path,
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

local function normalize_layout(layout)
  layout = layout or {}

  -- Menu window geometry:
  -- You can anchor relative to textbox or use absolute screen coords.
  -- Default: anchor to textbox and sit above it.
  local o = {
    anchor = layout.anchor or "textbox", -- "textbox" or "absolute"

    -- For absolute anchor
    x = layout.x,
    y = layout.y,

    -- For textbox anchor
    offset_x = layout.offset_x or 0,
    offset_y = layout.offset_y or -200, -- above textbox by default
    gap      = layout.gap or 4,

    -- Size of menu window in pixels (these control sprite scaling)
    width  = layout.width  or 160,
    height = layout.height or 64,

    -- Text inside the menu
    font  = layout.font  or "THIN_BLACK",
    scale = layout.scale or 2.0,
    z     = layout.z or 130,

    padding_x   = layout.padding_x or 12,
    padding_y   = layout.padding_y or 10,
    row_height  = layout.row_height or 12, -- pixels BEFORE scale
    visible_rows = tonumber(layout.visible_rows or 5) or 5,

    -- Cursor/highlight positioning
    cursor_offset_x = layout.cursor_offset_x or 6,
    cursor_offset_y = layout.cursor_offset_y or 1,
    highlight_inset_x = layout.highlight_inset_x or 8,
    highlight_inset_y = layout.highlight_inset_y or 0,

    -- Scrollbar positioning (relative to menu top-left)
    scrollbar_x = layout.scrollbar_x or 148,
    scrollbar_y = layout.scrollbar_y or 12,
    scrollbar_h = layout.scrollbar_h or 40,
    thumb_min_h = layout.thumb_min_h or 6,
    thumb_w     = layout.thumb_w or 6, -- sprite scaled via sx
  }

  -- Safety: visible rows must be >= 1
  o.visible_rows = math.max(1, o.visible_rows)

  return o
end

--========================
-- Instance
--========================
local STATE = {
  TEXT      = "text",      -- textbox printing/paging; menu visible but locked
  MENU      = "menu",      -- menu input active
  SUBPROMPT = "subprompt", -- reserved for nested yes/no later
  CLOSING   = "closing",
}

local PromptMenuInstance = {}
PromptMenuInstance.__index = PromptMenuInstance

function PromptMenuInstance:new(player_id, opts)
  local o = setmetatable({}, self)

  opts = opts or {}
  o.player_id = player_id

  o.box_id = (opts.ui and opts.ui.box_id) or mk_id(player_id)
  o.ui = normalize_ui(opts.ui or {})
  o.layout = normalize_layout(opts.layout or {})

  o.question = tostring(opts.question or "Choose:")
  o.options  = opts.options or { { text = "Exit" } }

  -- Normalize options to { text=..., id=..., value=... }
  for i = 1, #o.options do
    local v = o.options[i]
    if type(v) == "string" then
      o.options[i] = { text = v }
    else
      o.options[i].text = tostring(v.text or v[1] or ("Option " .. i))
    end
  end

  o.default_index = clamp(tonumber(opts.default_index or 1) or 1, 1, #o.options)
  o.selection_index = o.default_index
  o.scroll_top_index = 1

  -- Cancel behavior:
  --   "jump_to_exit" (default): B jumps to exit_index; second B selects it
  --   "close"                 : close immediately and call on_cancel
  --   "ignore"                : do nothing
  o.cancel_behavior = opts.cancel_behavior or "jump_to_exit"
  o.exit_index = clamp(tonumber(opts.exit_index or #o.options) or #o.options, 1, #o.options)

  o.keep_textbox = (opts.keep_textbox ~= false) -- default true for handoff/reuse
  o.on_select = opts.on_select or function(_choice, _index) end
  o.on_cancel = opts.on_cancel or function() end

  o.state = STATE.TEXT
  o.ready_for_input = false

  -- Draw IDs (unique per instance)
  local base = o.box_id
  o.draw = {
    menu_bg   = base .. "_menu_bg",
    hilite    = base .. "_menu_hilite",
    cursor    = base .. "_menu_cursor",
    scroll    = base .. "_menu_scroll",
  }

  -- Text display IDs we create via FontSystem:drawText (store returned ids to erase)
  o.text_displays = {}

  o:render_textbox()
  o:render_menu_window()
  o:update_scroll_for_selection(true)
  o:render_menu_contents(true)

  return o
end

function PromptMenuInstance:render_textbox()
  local ui = self.ui
  local ops = {
    page_advance = "wait_for_confirm",
    auto_advance_seconds = 999999,
    confirm_during_typing = true,
    type_sfx_path = ui.type_sfx_path,
    type_sfx_min_dt = ui.type_sfx_min_dt,
    mugshot = ui.mugshot,
    nameplate = ui.nameplate,
    wrap_opts = { allow_leading_spaces = true },
  }

  if Displayer.Text.create_text_box then
    Displayer.Text.create_text_box(
      self.player_id, self.box_id, self.question,
      ui.x, ui.y, ui.w, ui.h,
      ui.font, ui.scale, ui.z,
      ui.backdrop,
      ui.typing_speed,
      ops
    )
  else
    Displayer.Text.createTextBox(
      self.player_id, self.box_id, self.question,
      ui.x, ui.y, ui.w, ui.h,
      ui.font, ui.scale, ui.z,
      ui.backdrop,
      ui.typing_speed,
      ops
    )
  end
end

function PromptMenuInstance:menu_origin()
  local L = self.layout
  local bd = Displayer.Text.getTextBoxData(self.player_id, self.box_id)

  if L.anchor == "absolute" or not bd then
    return (L.x or 24), (L.y or 32)
  end

  -- Anchor to the visible panel if we have a backdrop; otherwise fall back to textbox data.
local tx = (self.ui.backdrop and self.ui.backdrop.x) or bd.x or self.ui.x or 0
local ty = (self.ui.backdrop and self.ui.backdrop.y) or bd.y or self.ui.y or 0



  local mx = tx + (L.offset_x or 0)
  local my = ty + (L.offset_y or 0) - (L.gap or 0)

  return mx, my
end

function PromptMenuInstance:render_menu_window()
  local L = self.layout
  local x, y = self:menu_origin()

  -- Background window
draw_sprite(
  self.player_id, SPR.MENU_BG,
  self.draw.menu_bg,
  x, y,
  L.z,
  L.scale
)

end

function PromptMenuInstance:clear_menu_text()
  for _, id in ipairs(self.text_displays) do
    FontSystem:eraseTextDisplay(self.player_id, id)
  end
  self.text_displays = {}
end

function PromptMenuInstance:update_scroll_for_selection(force)
  local L = self.layout
  local total = #self.options
  local rows = L.visible_rows

  local sel = self.selection_index
  local top = self.scroll_top_index

  -- Keep selection in view
  if sel < top then
    top = sel
  elseif sel > (top + rows - 1) then
    top = sel - (rows - 1)
  end

  local max_top = math.max(1, total - rows + 1)
  top = clamp(top, 1, max_top)

  local changed = (top ~= self.scroll_top_index)
  self.scroll_top_index = top

  return force or changed
end

function PromptMenuInstance:render_menu_contents(force)
  local L = self.layout
  local x0, y0 = self:menu_origin()

  -- Always redraw highlight/cursor/scroll when selection changes or forced.
  -- Text displays: erase + redraw only when (force) or (scroll window changes) or (selection changes).
  self:clear_menu_text()

  local rows = L.visible_rows
  local total = #self.options
  local top = self.scroll_top_index
  local sel = self.selection_index

  local scale = tonumber(L.scale) or 2.0
  local row_h = (tonumber(L.row_height) or 12) * scale

  -- Content top-left inside window
  local cx = x0 + (L.padding_x or 0)
  local cy = y0 + (L.padding_y or 0)

  -- Draw each visible row text
  for i = 0, rows - 1 do
    local idx = top + i
    if idx > total then break end

    local text = tostring(self.options[idx].text or "")
    local tx = cx
    local ty = cy + (i * row_h)

    local display_id = FontSystem:drawText(
      self.player_id,
      nil,
      text,
      tx,
      ty,
      (L.z + 2),
      L.font,
      scale
    )
    if display_id then table.insert(self.text_displays, display_id) end
  end

  -- Highlight bar (behind selected row)
  local sel_row = sel - top
  if sel_row >= 0 and sel_row < rows then
    local hx = x0 + (L.highlight_inset_x or 0)
    local hy = cy + (sel_row * row_h) + ((L.highlight_inset_y or 0) * scale)

    draw_sprite(
      self.player_id, SPR.HILITE,
      self.draw.hilite,
      hx, hy,
      (L.z + 1),
      L.scale
    )


    -- Cursor (left of text)
    local curx = x0 + (L.cursor_offset_x or 0)
    local cury = cy + (sel_row * row_h) + ((L.cursor_offset_y or 0) * scale)

    draw_sprite(
      self.player_id, SPR.CURSOR,
      self.draw.cursor,
      curx, cury,
      (L.z + 3),
      L.scale
    )

  else
    -- Not visible (shouldn't happen), erase overlays
    erase_sprite(self.player_id, self.draw.hilite)
    erase_sprite(self.player_id, self.draw.cursor)
  end

  -- Scrollbar thumb (only if needed)
  if total > rows then
    local track_x = x0 + (L.scrollbar_x or 0)
    local track_y = y0 + (L.scrollbar_y or 0)
    local track_h = (L.scrollbar_h or 0) * scale

    -- Thumb sizing: proportional, with minimum
    local ratio = rows / total
    local thumb_h = math.max((L.thumb_min_h or 6) * scale, track_h * ratio)

    -- Thumb position: map scroll_top [1..max_top] into track
    local max_top = math.max(1, total - rows + 1)
    local t = 0
    if max_top > 1 then
      t = (top - 1) / (max_top - 1)
    end

    local thumb_y = track_y + (track_h - thumb_h) * t

    draw_sprite(
      self.player_id, SPR.SCROLL,
      self.draw.scroll,
      track_x,
      thumb_y,
      (L.z + 3),
      L.scale
    )

  else
    erase_sprite(self.player_id, self.draw.scroll)
  end
end

function PromptMenuInstance:become_ready()
  self.state = STATE.MENU
  self.ready_for_input = true

  -- Avoid carry-press from dialogue confirm spamming into menu selection
  local held = {}
  if Input.is_down(self.player_id, "up")      then table.insert(held, "up") end
  if Input.is_down(self.player_id, "down")    then table.insert(held, "down") end
  if Input.is_down(self.player_id, "confirm") then table.insert(held, "confirm") end
  if Input.is_down(self.player_id, "cancel")  then table.insert(held, "cancel") end

  if #held > 0 then
    Input.consume(self.player_id)
    Input.require_release(self.player_id, held)
  end
end

function PromptMenuInstance:select_current()
  local idx = self.selection_index
  local choice = self.options[idx]

  PromptVertical.close(self.player_id, "select", { keep_textbox = self.keep_textbox })

  self.on_select(choice, idx)
end

function PromptMenuInstance:do_cancel()
  local beh = self.cancel_behavior or "jump_to_exit"

  if beh == "ignore" then
    return
  end

  if beh == "close" then
    PromptVertical.close(self.player_id, "cancel", { keep_textbox = self.keep_textbox })
    self.on_cancel()
    return
  end

  -- Default: jump_to_exit
  if self.selection_index ~= self.exit_index then
    self.selection_index = self.exit_index
    local sc_changed = self:update_scroll_for_selection(false)
    play_cursor_move_sfx(self.player_id)
    self:render_menu_contents(true)
    return
  end

  -- Already on exit: treat cancel as select
  self:select_current()
end

function PromptMenuInstance:update(_dt)
  local player_id = self.player_id
  local st = Displayer.Text.getTextBoxState(player_id, self.box_id)

  -- While printing: allow hold-confirm to fast-forward textbox; menu locked
  if st == "printing" then
    Input.pop(player_id, "up")
    Input.pop(player_id, "down")
    Input.pop(player_id, "cancel")

    if Input.is_down(player_id, "confirm") then
      Input.pop(player_id, "confirm")
      Displayer.Text.advance_text_box(player_id, self.box_id)
    end
    return
  end

  -- While waiting but textbox has more pages: confirm advances pages
  if (st == "waiting") and (self.state == STATE.TEXT) then
    if Input.pop(player_id, "confirm") then
      Displayer.Text.advance_text_box(player_id, self.box_id)
      Input.consume(player_id)
      Input.require_release(player_id, { "confirm" })
      return
    end

    -- If we’re “waiting” and there are no more pages, textbox state usually becomes "completed".
    -- Some builds still report "waiting" on final page; we’ll treat waiting as ready too.
    -- We only become ready when the textbox has reached a stable wait/completed state.
    self:become_ready()
    return
  end

  if st == "completed" and self.state == STATE.TEXT then
    self:become_ready()
    return
  end

  -- MENU INPUT
  if self.state ~= STATE.MENU then
    -- swallow anything if not in MENU
    Input.pop(player_id, "up")
    Input.pop(player_id, "down")
    Input.pop(player_id, "confirm")
    Input.pop(player_id, "cancel")
    return
  end

  local total = #self.options

  if Input.pop(player_id, "up") then
    local prev = self.selection_index
    self.selection_index = clamp(self.selection_index - 1, 1, total)
    if self.selection_index ~= prev then
      local _ = self:update_scroll_for_selection(false)
      play_cursor_move_sfx(player_id)
      self:render_menu_contents(true)
    end
    return
  end

  if Input.pop(player_id, "down") then
    local prev = self.selection_index
    self.selection_index = clamp(self.selection_index + 1, 1, total)
    if self.selection_index ~= prev then
      local _ = self:update_scroll_for_selection(false)
      play_cursor_move_sfx(player_id)
      self:render_menu_contents(true)
    end
    return
  end

  if Input.pop(player_id, "confirm") then
    self:select_current()
    return
  end

  if Input.pop(player_id, "cancel") then
    self:do_cancel()
    return
  end
end

--========================
-- Public API
--========================
function PromptVertical.menu(player_id, opts)
  ensure_listener()
  ensure_tick()

  if PromptVertical.instances[player_id] then
    PromptVertical.close(player_id, "replace")
  end

  set_input_locked(player_id, true)

  -- swallow interaction press so we don’t insta-confirm/select
  Input.consume(player_id)

  local inst = PromptMenuInstance:new(player_id, opts or {})
  PromptVertical.instances[player_id] = inst
  return inst.box_id
end

function PromptVertical.close(player_id, _reason, opts)
  local inst = PromptVertical.instances[player_id]
  if not inst then return end

  opts = opts or {}
  local keep = (opts.keep_textbox == true)

  -- Erase sprites
  erase_sprite(player_id, inst.draw.menu_bg)
  erase_sprite(player_id, inst.draw.hilite)
  erase_sprite(player_id, inst.draw.cursor)
  erase_sprite(player_id, inst.draw.scroll)

  -- Erase menu text
  inst:clear_menu_text()

  if not keep then
    Displayer.Text.closeTextBox(player_id, inst.box_id)
  else
    -- Handoff: keep textbox alive but swallow inputs so next dialogue doesn’t auto-advance
    Input.consume(player_id)
    Input.clear_require_release(player_id, { "confirm", "cancel" })
    Input.swallow(player_id, 0.10)
  end

  set_input_locked(player_id, false)

  if not keep then
    Input.consume(player_id)
    if Input.is_down(player_id, "confirm") or Input.is_down(player_id, "cancel") then
      Input.require_release(player_id, { "confirm", "cancel" })
    end
  end

  PromptVertical.instances[player_id] = nil
end

return PromptVertical
