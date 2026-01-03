--=====================================================
-- talk_presets.lua
-- Creator-facing presets for Dialogue NPCs (PROG-defaulted)
--=====================================================

local P = {}

-- ----------------------------
-- Nameplate presets
-- ----------------------------
P.nameplates = {
  prog = {
    -- text is filled in by talk.lua (BOT_NAME)
    anchor = "above",
    align = "left",
    gap_x = 6,
    gap_y = 59,
    dur = 0.20,
    close_dur = 0.20,
    bob_amp = 1.2,
    bob_speed = 2,
  },
}

-- ----------------------------
-- Mugshot presets
-- ----------------------------
P.mugs = {
  prog = {
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

-- ----------------------------
-- Textbox/backdrop presets
-- ----------------------------
P.boxes = {
  -- Canonical "PROG UI" defaults (matches prog_basic_nameplate + prog_prompt_dialogue)
  panel = {
    font = "THIN_BLACK",
    scale = 2.0,
    z = 100,

    -- YOU CONFIRMED THESE DEFAULTS
    typing_speed = 12,
    type_sfx_path = "/server/assets/net-games/sfx/text.ogg",
    type_sfx_min_dt = 0.05,

    backdrop = {
      render_offset_x = 3,
      render_offset_y = 46,
      style = "textbox_panel",
      open_seconds = 0.20,
      close_seconds = 0.25, -- harmless default; can override per NPC if desired

      x = 1,
      y = 209,
      width = 478,
      height = 104,
      padding_x = 16,
      padding_y = 4,
      max_lines = 3,

      -- Leave enabled by default. Prompt.lua can toggle visibility when selector is on-screen.
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
  },

  -- Legacy/simple black box (kept for convenience)
  black = {
    font = "THICK",
    scale = 2.0,
    z = 100,
    typing_speed = 30,
    type_sfx_path = "/server/assets/net-games/sfx/text.ogg",
    type_sfx_min_dt = 0.05,

    backdrop = {
      style = "black_box",
      x = 1,
      y = 209,
      width = 478,
      height = 104,
      padding_x = 16,
      padding_y = 16,
      max_lines = 3,

      indicator = {
        enabled = true,
        width = 2,
        height = 2,
        offset_x = 24,
        offset_y = 24,
        indicator_timer = 0,
        indicator_base_x = nil,
        indicator_base_y = nil,
      },
    },
  },
}

-- ----------------------------
-- Frame dye presets (only used with panel frame overlay style)
-- ----------------------------
P.frames = {
  lime   = { r = 80,  g = 255, b = 80,  a = 255, color_mode = 2 },
  red    = { r = 255, g = 80,  b = 80,  a = 255, color_mode = 2 },
  purple = { r = 200, g = 80,  b = 255, a = 255, color_mode = 2 },
}

-- ----------------------------
-- High-level “preset packs” (what creators should pick)
-- ----------------------------
P.packs = {
  -- This is your “PROG baseline” for almost everything.
  prog = {
    box = "panel",
    mug = "prog",
    nameplate = "prog",
  },

  -- Same UI as prog (kept explicit so prompt can opt into it cleanly)
  prog_prompt = {
    box = "panel",
    mug = "prog",
    nameplate = "prog",
  },
}

return P
