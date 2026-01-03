-- scripts/net-games/displayer/nameplate.lua
-- BN-style nameplate that unfolds from the center and sizes to the text.
-- Draws as 3-slice: left + N*middle + right, using TINY_BLACK for the label.

local Nameplate = {}
Nameplate.__index = Nameplate

local function ceil_div(a, b)
  return math.floor((a + b - 1) / b)
end

function Nameplate:new(font_system)
  local o = setmetatable({}, self)
  o.font_system = font_system

  -- textures
  o.tex_left  = "/server/assets/net-games/displayer/textbox_bn6_nameplate_left.png"
  o.tex_mid   = "/server/assets/net-games/displayer/textbox_bn6_nameplate_middle.png"
  o.tex_right = "/server/assets/net-games/displayer/textbox_bn6_nameplate_right.png"

  -- slice sizes (px at scale=1)
  o.w_left  = 5
  o.w_mid   = 3
  o.w_right = 5
  o.h_plate = 13

  -- allocated sprite ids (texture holders). draw uses explicit ids per instance.
  o.SID_LEFT  = 5400
  o.SID_RIGHT = 5401
  o.SID_MID0  = 5410
  o.MAX_MIDS  = 60

  return o
end

function Nameplate:_alloc_once(player_id, player_data)
  player_data._nameplate_alloc = player_data._nameplate_alloc or false
  if player_data._nameplate_alloc then return end
  player_data._nameplate_alloc = true

  Net.provide_asset_for_player(player_id, self.tex_left)
  Net.provide_asset_for_player(player_id, self.tex_mid)
  Net.provide_asset_for_player(player_id, self.tex_right)

  Net.player_alloc_sprite(player_id, self.SID_LEFT,  { texture_path = self.tex_left })
  Net.player_alloc_sprite(player_id, self.SID_RIGHT, { texture_path = self.tex_right })

  for i = 0, self.MAX_MIDS - 1 do
    Net.player_alloc_sprite(player_id, self.SID_MID0 + i, { texture_path = self.tex_mid })
  end
end

function Nameplate:erase(player_id, player_data, box_data)
  local np = box_data.nameplate
  if not np then return end

  -- erase pieces by DRAW ids (NOT sprite ids)
  Net.player_erase_sprite(player_id, np.idp .. "_L")
  Net.player_erase_sprite(player_id, np.idp .. "_R")
  for i = 0, self.MAX_MIDS - 1 do
    Net.player_erase_sprite(player_id, np.idp .. "_M" .. i)
  end

  -- erase the name text
  if self.font_system and np.text_display_id then
    self.font_system:eraseTextDisplay(player_id, np.text_display_id)
  end

  box_data.nameplate = nil
end

function Nameplate:attach(player_id, player_data, box_id, box_data, cfg)
  if not cfg then return end

  -- cfg can be "NAME" or { text="NAME", ... }
  local text = cfg
  if type(cfg) == "table" then text = cfg.text end
  if type(text) ~= "string" or text == "" then return end

  self:_alloc_once(player_id, player_data)

  -- wipe any existing plate on this box before overwriting
  if box_data.nameplate then
    self:erase(player_id, player_data, box_data)
  end

  local scale = box_data.scale or 2.0
  local z     = (box_data.z_order or 100) + 3

  -- Anchor to the ACTUAL rendered textbox panel position (includes render offsets)
  local bx = box_data.x or 0
  local by = box_data.y or 0
  if box_data.backdrop then
    bx = bx + (tonumber(box_data.backdrop.render_offset_x) or 0)
    by = by + (tonumber(box_data.backdrop.render_offset_y) or 0)
  end

  -- Text metrics
  local font_name  = "TINY_BLACK"
  local text_scale = (type(cfg) == "table" and cfg.text_scale) or scale
  local pad_px     = (type(cfg) == "table" and cfg.pad_px) or (4 * scale)

  local text_w = self.font_system:getTextWidth(text, font_name, text_scale)
  local inner_needed = math.max(1, math.floor(text_w + pad_px * 2))

  local mid_w = self.w_mid * scale
  local mids_target = math.min(self.MAX_MIDS, math.max(1, ceil_div(inner_needed, mid_w)))

  local total_w = (self.w_left + self.w_right) * scale + (mids_target * mid_w)

    -- Placement
    local gap_x = (type(cfg) == "table" and cfg.gap_x) or (6 * scale)
    local gap_y = (type(cfg) == "table" and cfg.gap_y) or (4 * scale)

    local anchor = (type(cfg) == "table" and cfg.anchor) or "above_left"
    local align  = (type(cfg) == "table" and cfg.align)  or "left"

    local bw = box_data.width or 0

    local x, y

    if anchor == "above" then
      -- Above the textbox panel
      if align == "center" then
        x = bx + (bw - total_w) / 2
      elseif align == "right" then
        x = bx + bw - total_w - gap_x
      else
        -- left
        x = bx + gap_x
      end

      y = by - (self.h_plate * scale) - gap_y
    else
      -- legacy: above-left OUTSIDE the box
      x = bx - total_w - gap_x
      y = by - (self.h_plate * scale) - gap_y
    end
  
  -- Optional absolute override
  if type(cfg) == "table" then
    if cfg.x ~= nil then x = cfg.x end
    if cfg.y ~= nil then y = cfg.y end
  end

  local center_x = x + (total_w / 2)
  local idp = tostring(box_id) .. "_np"

  box_data.nameplate = {
    idp = idp,

    text = text,
    font = font_name,
    text_scale = text_scale,
    pad_px = pad_px,

    x = x,
    y = y,
    base_y = y,
    z = z,

    -- bob animation (NEW)
    bob_t = 0,
    bob_amp = (type(cfg) == "table" and cfg.bob_amp) or (3 * scale), -- 3–4 px vibe (scaled)
    bob_speed = (type(cfg) == "table" and cfg.bob_speed) or 1.0,     -- calm speed


    mids_target = mids_target,
    mid_w = mid_w,
    total_w_full = total_w,
    center_x = center_x,

    -- animation
    t = 0,
    dur = (type(cfg) == "table" and cfg.dur) or 0.14, -- snappier default
    close_dur = (type(cfg) == "table" and cfg.close_dur) or nil,
    mids_drawn = 0,
    complete = false,

    text_display_id = "nameplate:" .. tostring(box_id),
  }
end

function Nameplate:begin_close(player_id, player_data, box_data, cfg)
  local np = box_data.nameplate
  if not np then return end
  if np.closing then return end

  np.closing = true
  np.close_t = 0

  -- allow per-box override, else per-nameplate config, else fall back
  local cd =
    (type(cfg) == "table" and cfg.close_dur)
    or np.close_dur
    or (type(cfg) == "table" and cfg.dur)
    or np.dur
    or 0.12

  np.close_dur = cd

  -- Hide text immediately so it doesn't ghost over transitions
  if self.font_system and np.text_display_id then
    self.font_system:eraseTextDisplay(player_id, np.text_display_id)
  end
end


function Nameplate:update(player_id, player_data, box_data, dt)
  local np = box_data.nameplate
  if not np then return end

  dt = math.min(dt or 0, 1/30)

  -- If closing: reverse-unfold then self-erase
  if np.closing then
    np.close_t = (np.close_t or 0) + dt
    local p = np.close_t / (np.close_dur or 0.12)
    if p >= 1 then
      -- fully closed, erase everything
      self:erase(player_id, player_data, box_data)
      return
    end

    local remain = 1 - p
    local mids = math.max(0, math.floor(np.mids_target * remain + 0.0001))
    np.mids_drawn = mids

  else
    -- unfold: center -> outward, snapping by segment count
    if not np.complete then
      np.t = np.t + dt
      local p = np.t / np.dur
      if p >= 1 then p = 1; np.complete = true end

      local mids = math.max(1, math.floor(np.mids_target * p + 0.0001))
      np.mids_drawn = mids
    end
  end


  local scale = box_data.scale or 2.0
  local z = np.z

  local mids = np.mids_drawn
  local total_w = (self.w_left + self.w_right) * scale + (mids * np.mid_w)

  -- keep the middle piece centered while unfolding
  local left_x = np.center_x - (total_w / 2)
  -- NEW: subtle floaty bob
  np.bob_t = (np.bob_t or 0) + (dt or 0) * (np.bob_speed or 1.0)
  local bob = math.sin(np.bob_t) * (np.bob_amp or 0)
  local y = (np.base_y or np.y) + bob

  -- LEFT
  Net.player_draw_sprite(player_id, self.SID_LEFT, {
    id = np.idp .. "_L",
    x = left_x,
    y = y,
    z = z,
    sx = scale,
    sy = scale,
  })

  -- MIDS
  local mx = left_x + (self.w_left * scale)
  for i = 0, mids - 1 do
    Net.player_draw_sprite(player_id, self.SID_MID0 + i, {
      id = np.idp .. "_M" .. i,
      x = mx + (i * np.mid_w),
      y = y,
      z = z,
      sx = scale,
      sy = scale,
    })
  end

  -- erase unused mids (from previous longer names / previous frames)
  for i = mids, self.MAX_MIDS - 1 do
    Net.player_erase_sprite(player_id, np.idp .. "_M" .. i)
  end

  -- RIGHT
  Net.player_draw_sprite(player_id, self.SID_RIGHT, {
    id = np.idp .. "_R",
    x = mx + (mids * np.mid_w),
    y = y,
    z = z,
    sx = scale,
    sy = scale,
  })

  -- TEXT (only after complete, and not while closing)
  if np.complete and not np.closing then
    local text_x = left_x + (self.w_left * scale) + np.pad_px
    local text_y = y + (3 * scale) + 2

    self.font_system:drawTextWithId(
      player_id,
      np.text,
      text_x,
      text_y,
      np.font,
      np.text_scale,
      z + 1,
      np.text_display_id
    )
  end
end

return Nameplate
