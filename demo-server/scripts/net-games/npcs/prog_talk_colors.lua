--=====================================================
-- prog_talk_colors.lua
-- PROG talk NPCs: one per frame dye color
-- Tiled object names must be: prog_{color}
-- Example: prog_red, prog_sapphire, prog_charcoal_grey, etc.
--=====================================================

require("scripts/net-games/framework")

local Talk = require("scripts/net-games/npcs/talk")

local AREA_ID = "default"

--=====================================================
-- prog_lime
--=====================================================
Talk.npc({
  area_id = AREA_ID,
  object  = "prog_lime",
  name    = "PROG",
  preset  = "prog_prompt",
  frame   = "lime",
  lines = {
    "LIME PROG ONLINE.",
    "Everything is GO.{p_0.2} Fast.{p_0.2} Clean.{p_0.2} Alive.",
    "{end_page}If you need momentum, borrow mine.",
  },
})

--=====================================================
-- prog_red
--=====================================================
Talk.npc({
  area_id = AREA_ID,
  object  = "prog_red",
  name    = "PROG",
  preset  = "prog_prompt",
  frame   = "red",
  lines = {
    "RED PROG HERE!!",
    "OKAY OKAY OKAY—{p_0.15}WE’RE DOING IT!!",
    "{end_page}I DON’T KNOW WHAT IT IS BUT IT’S IMPORTANT.",
  },
})

--=====================================================
-- prog_purple
--=====================================================
Talk.npc({
  area_id = AREA_ID,
  object  = "prog_purple",
  name    = "PROG",
  preset  = "prog_prompt",
  frame   = "purple",
  lines = {
    "PURPLE PROG speaking.",
    "Mystery is just data wearing a cloak.",
    "{end_page}Keep staring.{p_0.2} Patterns confess eventually.",
  },
})

--=====================================================
-- prog_turquoise
--=====================================================
Talk.npc({
  area_id = AREA_ID,
  object  = "prog_turquoise",
  name    = "PROG",
  preset  = "prog_prompt",
  frame   = "turquoise",
  lines = {
    "TURQUOISE PROG online.",
    "Breathe.{p_0.3} Smooth inputs.{p_0.3} Smooth outputs.",
    "{end_page}No rush. We still win.",
  },
})

--=====================================================
-- prog_pink
--=====================================================
Talk.npc({
  area_id = AREA_ID,
  object  = "prog_pink",
  name    = "PROG",
  preset  = "prog_prompt",
  frame   = "pink",
  lines = {
    "PINK PROG reporting in.",
    "I made the UI cute so the bugs feel bad about existing.",
    "{end_page}It’s working.{p_0.2} You’re allowed to be proud.",
  },
})

--=====================================================
-- prog_emerald
--=====================================================
Talk.npc({
  area_id = AREA_ID,
  object  = "prog_emerald",
  name    = "PROG",
  preset  = "prog_prompt",
  frame   = "emerald",
  lines = {
    "EMERALD PROG operational.",
    "Stable.{p_0.2} Grounded.{p_0.2} Built to last.",
    "{end_page}We don’t just ship.{p_0.2} We endure.",
  },
})

--=====================================================
-- prog_sapphire
--=====================================================
Talk.npc({
  area_id = AREA_ID,
  object  = "prog_sapphire",
  name    = "PROG",
  preset  = "prog_prompt",
  frame   = "sapphire",
  lines = {
    "SAPPHIRE PROG here.",
    "Cool head.{p_0.2} Clear eyes.{p_0.2} Clean diff.",
    "{end_page}If it looks haunted, we log it until it apologizes.",
  },
})

--=====================================================
-- prog_yellow
--=====================================================
Talk.npc({
  area_id = AREA_ID,
  object  = "prog_yellow",
  name    = "PROG",
  preset  = "prog_prompt",
  frame   = "yellow",
  lines = {
    "YELLOW PROG online.",
    "Good news:{p_0.2} it’s bright for a reason.",
    "{end_page}Spot the issue.{p_0.2} Tag it.{p_0.2} Fix it.{p_0.2} Celebrate.",
  },
})

--=====================================================
-- prog_orange
--=====================================================
Talk.npc({
  area_id = AREA_ID,
  object  = "prog_orange",
  name    = "PROG",
  preset  = "prog_prompt",
  frame   = "orange",
  lines = {
    "ORANGE PROG active.",
    "I run hot.{p_0.2} I move fast.{p_0.2} I break walls.",
    "{end_page}Point me at the problem and stand back.",
  },
})

--=====================================================
-- prog_charcoal_grey
--=====================================================
Talk.npc({
  area_id = AREA_ID,
  object  = "prog_charcoal_grey",
  name    = "PROG",
  preset  = "prog_prompt",
  frame   = "charcoal_grey",
  lines = {
    "CHARCOAL PROG online.",
    "Quiet mode.{p_0.3} Minimal noise.{p_0.3} Maximum signal.",
    "{end_page}When you’re done, we ship. No drama.",
  },
})

--=====================================================
-- prog_white
--=====================================================
Talk.npc({
  area_id = AREA_ID,
  object  = "prog_white",
  name    = "PROG",
  preset  = "prog_prompt",
  frame   = "white",
  lines = {
    "WHITE PROG reporting.",
    "Baseline check:{p_0.2} no tricks.{p_0.2} no tint lies.",
    "{end_page}If this breaks, something else is VERY wrong.",
  },
})

return true
