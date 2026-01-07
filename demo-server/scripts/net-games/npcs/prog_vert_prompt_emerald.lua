--=====================================================
-- prog_vert_prompt_emerald.lua
-- Copy of prog_vert_prompt_red.lua:
-- - Same flow
-- - Same text
-- - Same options generation
-- Only changes:
-- - Emerald OW + frame + mug
-- - Uses shop-skinned menu assets via layout = "prog_prompt_shop"
--=====================================================

local Talk = require("scripts/net-games/npcs/talk")

Talk.npc({
  area_id = "default",
  object  = "ProgVertPromptEmerald", -- add this object name in Tiled
  name    = "EMERALD PROMPT PROG",

  texture_path   = "/server/assets/ow/prog/prog_ow_emerald.png",
  animation_path = "/server/assets/ow/prog/prog_ow.animation",

  preset = "prog_prompt",
  frame  = "emerald",
  mug    = "prog_emerald",
  nameplate = "prog",

  on_interact = function(player_id, _bot_id, bot_name)
    Talk.vert_menu(player_id, bot_name, {
      area_id = "default",
      object  = "ProgVertPromptEmerald",
      preset  = "prog_prompt",
      frame   = "emerald",
      mug     = "prog_emerald",
      nameplate = "prog",
    }, {
      options = { count = 99, prefix = "Option ", pad = 2, exit_text = "Exit", exit_id = "exit" },

      texts = {
        open_question = "Do you wanna check out the vertical menu?",
        intro_text    = "Awesome. Let me know if there's anything that you like.",
        decline_open  = "No worries. Maybe next time.",

        confirm_format     = 'Are you sure you want "%s"?',
        post_select_format = 'You got "%s".',

        after_yes    = "Thank you!{p_1} Is there anything else you'd like?",
        after_no     = "No worries. Anything else?",
        exit_goodbye = "Thanks for stopping by!",
      },

      sfx = "card_desc",
      flow = "prog_prompt",

      -- THIS is the whole point: same Red flow, shop-skinned menu art
      layout = "prog_prompt_shop",
    })
  end,
})
