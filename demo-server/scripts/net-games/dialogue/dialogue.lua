-- scripts/net-games/dialogue/dialogue.lua

local Displayer = require("scripts/net-games/displayer/displayer")
local Input     = require("scripts/net-games/input/input")
local C         = require("scripts/net-games/dialogue/constants")

local Dialogue = {}
Dialogue.instances = {}

local LISTENER_ATTACHED = false

--=====================================================
-- Input lock helper (correct ONB signatures)
--=====================================================
local function set_input_locked(player_id, locked)
  if not Net then
    print("[Dialogue] Net is nil; cannot lock input")
    return false
  end

  if locked then
    if Net.lock_player_input then
      local ok = pcall(function()
        Net.lock_player_input(player_id)
      end)
      if not ok then
        print("[Dialogue] input lock FAIL via Net.lock_player_input")
      end
      return ok
    end
    print("[Dialogue] WARNING: Net.lock_player_input missing")
    return false
  else
    if Net.unlock_player_input then
      local ok = pcall(function()
        Net.unlock_player_input(player_id)
      end)
      if not ok then
        print("[Dialogue] input unlock FAIL via Net.unlock_player_input")
      end
      return ok
    end
    print("[Dialogue] WARNING: Net.unlock_player_input missing")
    return false
  end
end

local function ensure_listener()
  if LISTENER_ATTACHED then return end
  LISTENER_ATTACHED = true
  Input.attach_virtual_input_listener()
end

local function default_opts()
  return {
    x = 8, y = 110, w = 224, h = 42,
    font = "THICK",
    scale = 2.0,
    z = 100,
    typing_speed = 30,

    page_advance = C.PageAdvance.WAIT_FOR_CONFIRM,
    advance_delay = 2.0,
    confirm_during_typing = true,

    input_mode = C.InputMode.DIALOGUE_OWNS_INPUT,
    cancel_behavior = "close_dialogue",

    debug = false,
  }
end

local function merge(a, b)
  if not b then return a end
  for k, v in pairs(b) do a[k] = v end
  return a
end

local function mk_box_id(player_id, ui)
  if ui and ui.box_id then
    return tostring(ui.box_id)
  end
  return "ng_dialogue_" .. tostring(player_id)
end


local function close_instance(player_id, reason)
  local inst = Dialogue.instances[player_id]
  if not inst then return end

  if inst.box_id then
    Displayer.Text.removeTextBox(player_id, inst.box_id)
  end

  if inst.opts and inst.opts.input_mode == C.InputMode.DIALOGUE_OWNS_INPUT then
    set_input_locked(player_id, false)
  end

    -- swallow to prevent carry-press closes / reopens
    Input.consume(player_id)
    Input.swallow(player_id, 0.10)

  Dialogue.instances[player_id] = nil

  if inst.opts and inst.opts.debug then
    print("[Dialogue] close player=" .. tostring(player_id) .. " reason=" .. tostring(reason))
  end
end

local function attach_tick()
  if Dialogue._tick_attached then return end
  Dialogue._tick_attached = true

      Net:on("tick", function(event)
      for player_id, inst in pairs(Dialogue.instances) do
        local state = Displayer.Text.getTextBoxState(player_id, inst.box_id)

        if not state then
          close_instance(player_id, "finish")
        else
          -- Prevent confirm-carry when transitioning into WAITING
          if state == "waiting" and inst.last_state ~= "waiting" then
            Input.consume(player_id)
            Input.swallow(player_id, 0.08)
          end
          inst.last_state = state

          -- CANCEL: actually do something (right now your code does nothing)
          if Input.pop(player_id, "cancel") then
            if inst.opts and inst.opts.debug then
              print("[Dialogue] CANCEL edge player=" .. tostring(player_id))
            end
            close_instance(player_id, "cancel")

          -- CONFIRM
          elseif Input.pop(player_id, "confirm") then
            if inst.opts and inst.opts.debug then
              print("[Dialogue] CONFIRM edge player=" .. tostring(player_id) .. " state=" .. tostring(state))
            end

            if state == "printing" then
              if inst.opts.confirm_during_typing then
                Displayer.Text.advance_text_box(player_id, inst.box_id)
              end

            elseif state == "waiting" then
              Displayer.Text.advance_text_box(player_id, inst.box_id)
              local new_state = Displayer.Text.getTextBoxState(player_id, inst.box_id)
              if new_state == "completed" or new_state == nil then
                close_instance(player_id, "finish")
              end

            elseif state == "completed" then
              close_instance(player_id, "finish")
            end
          end
        end
      end
   end)
end

--=====================================================
-- Public API
--=====================================================

function Dialogue.is_active(player_id)
  return Dialogue.instances[player_id] ~= nil
end

function Dialogue.start(player_id, script, opts)
  ensure_listener()
  attach_tick()

  if Dialogue.instances[player_id] then
    close_instance(player_id, "cancel")
  end

  local o = merge(default_opts(), opts or {})

  if o.input_mode == C.InputMode.DIALOGUE_OWNS_INPUT then
    local ok = set_input_locked(player_id, true)
    if o.debug then
      print("[Dialogue] set_input_locked(true) => " .. tostring(ok))
    end
  end

    -- swallow the interaction press so it doesn't instantly advance
    -- IMPORTANT: do NOT require_release here, because virtual_input
    -- only exists while locked and we may never see the release event.
    Input.consume(player_id)
    Input.swallow(player_id, 0.10)

  -- normalize script/pages into one text blob (net-games Displayer handles paging internally)
  local pages = {}
  if type(script) == "string" then
    pages = { script }
  elseif type(script) == "table" then
    if script.pages then
      for _, p in ipairs(script.pages) do
        table.insert(pages, p.text or "")
      end
    else
      for _, p in ipairs(script) do
        table.insert(pages, tostring(p))
      end
    end
  else
    pages = { "" }
  end

  local full_text = table.concat(pages, "\n")

    --=====================================================
  -- UI passthrough (NPC can control sizing/styling)
  -- opts.ui (preferred) or opts.textbox (alias)
  --=====================================================
  local ui = o.ui or o.textbox or nil

  if ui then
    if ui.font         then o.font = ui.font end
    if ui.scale        then o.scale = ui.scale end
    if ui.z            then o.z = ui.z end
    if ui.typing_speed then o.typing_speed = ui.typing_speed end
    if ui.type_sfx_path   then o.type_sfx_path = ui.type_sfx_path end
    if ui.type_sfx_min_dt then o.type_sfx_min_dt = ui.type_sfx_min_dt end


    if ui.backdrop then
      if ui.backdrop.x then
        o.x = ui.backdrop.x + (ui.backdrop.padding_x or 0)
      end

      if ui.backdrop.y then
        o.y = ui.backdrop.y + (ui.backdrop.padding_y or 0)
      end

      if ui.backdrop.width then
        o.w = ui.backdrop.width - ((ui.backdrop.padding_x or 0) * 2)
      end

      if ui.backdrop.height then
        o.h = ui.backdrop.height - ((ui.backdrop.padding_y or 0) * 2)
      end
    end
  end

  if o.debug then
      print("[Dialogue] ui.font=" .. tostring(ui and ui.font) .. " -> o.font=" .. tostring(o.font))
  end


  local box_id = mk_box_id(player_id, ui)
  local backdrop = (ui and (ui.backdrop or ui.backdrop_config)) or nil

  -- Create textbox (prefer snake_case wrapper if present, otherwise call createTextBox)
  local created
  if Displayer.Text.create_text_box then
    created = Displayer.Text.create_text_box(
      player_id, box_id, full_text,
      o.x, o.y, o.w, o.h,
      o.font, o.scale, o.z,
      backdrop,
      o.typing_speed,
      {
        page_advance = o.page_advance,
        auto_advance_seconds = o.advance_delay,
        confirm_during_typing = o.confirm_during_typing,
        type_sfx_path = o.type_sfx_path,
        type_sfx_min_dt = o.type_sfx_min_dt,

        mugshot = (ui and ui.mugshot) or nil,

      }
    )
  else
    created = Displayer.Text.createTextBox(
      player_id, box_id, full_text,
      o.x, o.y, o.w, o.h,
      o.font, o.scale, o.z,
      backdrop,
      o.typing_speed,
      {
        page_advance = o.page_advance,
        auto_advance_seconds = o.advance_delay,
        confirm_during_typing = o.confirm_during_typing,
        type_sfx_path = o.type_sfx_path,
        type_sfx_min_dt = o.type_sfx_min_dt,
      }
    )
  end

  -- SAFETY: If the textbox didn't actually register in TextDisplay,
  -- don't leave the player locked in an invisible dialogue.
  local initial_state = Displayer.Text.getTextBoxState(player_id, box_id)
  if initial_state == nil then
    if o.debug then
      print("[Dialogue] WARNING: textbox state is nil right after create; closing to avoid softlock")
    end
    if o.input_mode == C.InputMode.DIALOGUE_OWNS_INPUT then
      set_input_locked(player_id, false)
    end
    return nil
  end

  if o.debug then
    print("[Dialogue] createTextBox returned: " .. tostring(created) .. " box_id=" .. tostring(box_id))
  end

  if not created then
    if o.input_mode == C.InputMode.DIALOGUE_OWNS_INPUT then
      set_input_locked(player_id, false)
    end
    return nil
  end

  Dialogue.instances[player_id] = {
    box_id = box_id,
    opts = o,
    wait_elapsed = 0,
    last_state = initial_state,
  }

  if o.debug then
    print("[Dialogue] start ok player=" .. tostring(player_id) .. " box_id=" .. tostring(box_id))
  end

  return box_id
end

function Dialogue.close(player_id)
  close_instance(player_id, "cancel")
end

return Dialogue
