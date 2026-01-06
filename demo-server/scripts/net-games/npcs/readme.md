============================================================
NET-GAMES NPC AUTHORING GUIDE
(Simple, Practical, No Bullshit)
============================================================

This file explains how to make NPCs in net-games using the
Talk system — from the absolute simplest NPC all the way
up to the fully condensed vertical menu NPC (like RED PROG).

This is written for:
- new contributors
- future you
- anyone who does NOT want to read engine lore

------------------------------------------------------------
CORE IDEA (READ THIS FIRST)
------------------------------------------------------------

You never start from scratch anymore.

You PICK a LEVEL of complexity:

1) Plain dialogue NPC (easy)
2) Yes/No prompt NPC (medium)
3) Vertical menu NPC (advanced)
4) Fully condensed vertical menu NPC (max power)

Each level BUILDS ON the previous one.
You can stop at any level and still be correct.

Nothing forces you to use the most condensed API.
Everything is optional and modular.

------------------------------------------------------------
MENTAL MODEL (IN HUMAN TERMS)
------------------------------------------------------------

Think of the system like layers:

- Talk.lua
  "I want the NPC to talk or ask something"

- TalkPresets.lua
  "What does this NPC look like? Frame? Mug? Box?"

- TalkVertMenu.lua
  "If there is a menu, handle ALL the hard stuff safely"

- Helpers (npc_api.lua, menu_options.lua)
  "Please stop making me write the same boilerplate forever"

NPC scripts should mostly contain:
- WHAT the NPC says
- WHAT options exist
- HOW it reacts

NPC scripts should NOT contain:
- Net:on boilerplate
- busy guards
- menu math
- repeated sound wiring
- repeated layout math

------------------------------------------------------------
LEVEL 1: SIMPLE DIALOGUE NPC
------------------------------------------------------------

Use this when:
- NPC just talks
- no menus
- no prompts

Example:

------------------------------------------------------------
local Talk = require("scripts/net-games/npcs/talk")

Talk.npc({
  area_id = "default",
  object  = "ProgTalkBlue",
  name    = "BLUE PROG",

  texture_path   = "/server/assets/ow/prog/prog_ow_blue.png",
  animation_path = "/server/assets/ow/prog/prog_ow.animation",

  preset = "prog_prompt",
  frame  = "blue",
  mug    = "prog_blue",
  nameplate = "prog",

  on_interact = function(player_id, _bot_id, bot_name)
    Talk.start(player_id, {
      "Hey.",
      "I am a simple NPC.",
      "I do not open menus.",
    }, {
      area_id = "default",
      object  = "ProgTalkBlue",
      preset  = "prog_prompt",
      frame   = "blue",
      mug     = "prog_blue",
      nameplate = "prog",
    }, bot_name)
  end,
})
------------------------------------------------------------

RULES:
- object name MUST exist in Tiled
- Talk.start shows dialogue and handles input safely
- You control the text, always

------------------------------------------------------------
LEVEL 2: YES / NO PROMPT NPC
------------------------------------------------------------

Use this when:
- NPC asks a question
- player chooses yes or no
- maybe shows follow-up dialogue

Example:

------------------------------------------------------------
Talk.prompt_yesno(player_id, "Wanna hear a secret?", cfg, bot_name, {
  on_yes = function()
    Talk.start(player_id, { "The secret is: drink water." }, cfg, bot_name)
  end,

  on_no = function()
    local next_cfg = {
      area_id = cfg.area_id,
      object  = cfg.object,
      preset  = cfg.preset,
      frame   = cfg.frame,
      mug     = cfg.mug,
      nameplate = cfg.nameplate,

      from_prompt = true,
      reuse_existing_box = true,
    }

    Talk.start(player_id, { "No worries. Maybe next time." }, next_cfg, bot_name)
  end,
})
------------------------------------------------------------

IMPORTANT RULE:
If dialogue happens AFTER a prompt:
- set from_prompt = true
- set reuse_existing_box = true

This prevents indicator bugs and input weirdness.

------------------------------------------------------------
LEVEL 3: VERTICAL MENU NPC (MID-LEVEL)
------------------------------------------------------------

Use this when:
- NPC opens a menu
- menu has options
- confirm / post-select / exit behavior matters

At this level, you may still call TalkVertMenu.open directly.
This is fine and supported.

BUT:
- you must wire options
- you must wire flow
- you must wire sounds

This is similar to Lime / Pink.

------------------------------------------------------------
LEVEL 4: FULLY CONDENSED VERTICAL MENU NPC (RECOMMENDED)
------------------------------------------------------------

Use this when:
- you want the shortest, cleanest NPC script
- you want safety by default
- you want easy overrides without dropping to low-level code

This uses:
- Talk.vert_menu(...)
- menu_options.lua
- presets
- automatic exit handling

Example (RED PROG style):

------------------------------------------------------------
Talk.vert_menu(player_id, bot_name, cfg, {
  open_question = "Do you wanna check out the vertical menu?",
  intro_text = "Pick something.",

  options = {
    count = 40,
    prefix = "Red Option ",
    pad = 2,
    exit_text = "Exit",
    exit_id = "exit",
  },

  texts = {
    decline_open = "No worries. Maybe next time.",
    confirm_format = 'Are you sure you want "%s"?',
    post_select_format = 'You got "%s".',
    after_yes = "Thanks! Anything else?",
    after_no  = "All good. Anything else?",
    exit_goodbye = "Thanks for stopping by!",
  },

  sfx = "card_desc",
  layout = "prog_prompt",
  flow = "prog_prompt",
})
------------------------------------------------------------

WHAT YOU DID NOT HAVE TO DO:
- compute exit_index
- write Net:on
- guard input
- face the player
- write option loops
- manage menu close timing

------------------------------------------------------------
MENU OPTIONS (IMPORTANT)
------------------------------------------------------------

You NEVER need to manually build option tables anymore.

COUNT-BASED MENU:
------------------------------------------------------------
options = {
  count = 10,
  prefix = "Option ",
  pad = 2,
  exit_text = "Exit",
}
------------------------------------------------------------

LIST-BASED MENU:
------------------------------------------------------------
options = {
  list = { "Potion", "Antidote", "Escape Rope" },
  exit_text = "Exit",
}
------------------------------------------------------------

Exit is ALWAYS auto-added.
Exit index is ALWAYS inferred.

------------------------------------------------------------
OVERRIDES (YES, YOU CAN BREAK THE RULES)
------------------------------------------------------------

You can override ANYTHING if needed.

Examples:

CUSTOM SFX (no preset):
------------------------------------------------------------
sfx = {
  desc = "/server/assets/sfx/open.ogg",
  confirm = "/server/assets/sfx/confirm.ogg",
  close = "/server/assets/sfx/close.ogg",
}
------------------------------------------------------------

CUSTOM LAYOUT (escape hatch):
------------------------------------------------------------
layout = {
  anchor = "textbox",
  offset_x = 10,
  offset_y = -12,
}
------------------------------------------------------------

CUSTOM FLOW (escape hatch):
------------------------------------------------------------
flow = {
  keep_menu_open = true,
  confirm = { enabled = true },
  post_select = { enabled = false },
}
------------------------------------------------------------

If you need to override:
- do it
- you do NOT lose access to the wrapper
- you do NOT have to rewrite everything

------------------------------------------------------------
COMMON RULES (MEMORIZE THESE)
------------------------------------------------------------

1) Object name in code MUST match Tiled object name
2) Content stays in NPC scripts
3) Layout + behavior defaults live in presets
4) Use menu_options instead of loops
5) Use Talk.vert_menu unless you have a reason not to
6) If dialogue follows a prompt, chain it properly
7) Old NPCs do NOT need to be rewritten

------------------------------------------------------------
FINAL THOUGHT
------------------------------------------------------------

This system is designed so that:
- old code keeps working
- new code is dramatically smaller
- complexity is opt-in
- authors control content
- engine controls safety

If you are writing a lot of glue code,
you are probably skipping a layer that already exists.

============================================================
END OF FILE
============================================================
