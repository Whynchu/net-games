--=====================================================
-- prog_shop4.lua
-- PROG Shop 4 (lightweight Talk.shop_menu authoring)
--=====================================================

local Talk = require("scripts/net-games/npcs/talk")

--========================
-- Tunables
--========================
local PRICE_PER = 250
local MAX_QTY   = 999

-- Optional: shop art for a few specific selections (only used if the shop layout draws it)
local SHOP_ART = {
  [1]  = "/server/assets/net-games/ui/card_shop_hpmem1.png",
  [2]  = "/server/assets/net-games/ui/card_shop_hpmem2.png",
  [3]  = "/server/assets/net-games/ui/card_shop_hpmem3.png",
  [14] = { path = "/server/assets/net-games/ui/bewd.png", w = 40, h = 40 },
}

Talk.npc({
  area_id = "default",
  object  = "ProgShop4",
  name    = "PROG SHOP 4",

  -- Overworld visuals (swap these to whatever you want)
  texture_path   = "/server/assets/ow/prog/prog_ow_purple.png",
  animation_path = "/server/assets/ow/prog/prog_ow.animation",

  on_interact = function(player_id, _bot_id, bot_name)
    Talk.shop_menu(player_id, bot_name,
      -- Optional identity overrides (usually redundant with npc() fields)
      {
        preset    = "prog_shop",
        frame     = "purple",
        mug       = "prog_purple",
        nameplate = "prog",
      },
      -- Shop config
      {
        catalog = {
          kind      = "bulk_qty",
          label     = "HPMEM",
          max_qty   = MAX_QTY,
          price_per = PRICE_PER,

          -- Wrapper default is fine; keep this only if you add multiple formats later
          format    = "label_qty_price",

          art       = SHOP_ART,
          exit_text = "Exit",
        },

        -- For bulk_qty shops, wrapper should grant the selected qty automatically for this kind
        grant = { kind = "hp_mem" },

        texts = {
          open_question  = "Yo!{p_0.5} Welcome to ProgShop 4!",
          intro_text     = "See anything you like?",
          decline_open   = "No worries.{p_0.5} Come back when your wallet stops dodging you!",
          confirm_format = "Buy %s?",
          after_yes      = "Anything else?",
          after_no       = "Alright. Want something else?",
          exit_goodbye   = "Later!",
        },
      }
    )
  end,
})
