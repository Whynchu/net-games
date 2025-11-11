### Installation
> 1. Copy `/scripts/net-games/` to your server script folder.
> 2. Copy `/assets/net-games/` to your server assets folder.
> 3. Include the following code at the start of any script that needs to access net-games.

```
local games = require("scripts/net-games/framework")
```

> You will then access the functions via the variable you specify. For example, if you use `games` as your variable (like the example above) you would access the functions with this variable appended to the beginning like so `games.freeze_player(player_id)`. 

### Features
> 1. Freeze player movement while still reporting button inputs. <br>
> &nbsp; &nbsp; For example, the moveable camera during Liberation Missions
> 2. Easily position sprites on screen relative to the player's camera <br>
> &nbsp; &nbsp; For example, add a persistent Order Points UIs during Liberation Missions <br>
> 3. Create custom selectors with customizable cursor sprites and positioning <br>
> &nbsp; &nbsp; For example, the liberate panel selector. <br>
> 4. Respond to currently hovered cursor selection <br>
> &nbsp; &nbsp; For example, change highlighted tiles based on which power is hovered over during liberation tile selection. <br>
> 5. Show in-game timers <br>
> &nbsp; &nbsp; For example, you can have races and time trial leaderboards.
> 6. Show in-game countdowns <br>
> &nbsp; &nbsp; For example, the sixty second countdown used in BN3 for the CyberSimon Says <br>

## Positioning Sprites

When a function asks you for a x, y, z (except for map elements), it is asking for a position relative to the camera. 

![onb-ui-guide](https://github.com/user-attachments/assets/3459e10b-8658-4c8b-a43c-376a42c7a920)

Per the graphic above, the following positions would require the associated values:
```
position = x,y
top left = 0,0
top middle = 120,0
top right = 240,0
middle = 120,80
bottom left = 0,160
bottom middle = 120,160
bottom right = 240,160
```

# Net Games (Documentation)

### Click any header below to expand it. 

<details><summary><h3>Player Functions</h3></summary>

#### `freeze_player(player_id)`
> **Description**: Freezes the player's movement while preserving input access.  
> **Parameters**:
> - `player_id` (string): The ID of the player to freeze  

#### `unfreeze_player(player_id)`
> **Description**: Releases a player from being frozen, returning them to their original position.  
> **Parameters**:
> - `player_id` (string): The ID of the player to unfreeze

#### `move_frozen_player(player_id, X, Y, Z)`
> **Description**: Instantly moves a frozen player to specified coordinates without animation.  
> **Parameters**:
> - `player_id` (string): The ID of the frozen player
> - `X`, `Y`, `Z` (number): Target coordinates

#### `walk_frozen_player(player_id, X, Y, Z, duration, wait)`
> **Description**: Moves a frozen player to coordinates with walking animation.  
> **Parameters**:
> - `player_id` (string): The ID of the frozen player
> - `X`, `Y`, `Z` (number): Target coordinates
> - `duration` (number): Animation duration in seconds
> - `wait` (boolean): Whether to wait for animation to complete  

#### `animate_frozen_player(player_id, animation_state)`
> **Description**: Plays an animation on the frozen player's avatar.  
> **Parameters**:
> - `player_id` (string): The ID of the frozen player
> - `animation_state` (string): Name of animation state to play
</details>

#### `Net:on("button_press")`
> **Description**: Called when a button pressed by a player, useful to get inputs when player is frozen. 
> **Parameters**:
> - `event.player_id` (string): The ID of the frozen player
> - `event.button` (string): The button can be "A","LS","U","D","L","R","DR","DL","UR", or "UL"
</details>


<details><summary><h3>Map Element Functions</h3></summary>

#### `add_map_element(name, player_id, texture, animation, animation_state, X, Y, Z, exclude)`
> **Description**: Adds a map element at specified coordinates.  
> **Parameters**:
> - `name` (string): Unique identifier for the element
> - `player_id` (string): The ID of the player
> - `texture` (string): Path to texture file
> - `animation` (string): Path to animation file
> - `animation_state` (string): Initial animation state
> - `X`, `Y`, `Z` (number): Map coordinates
> - `exclude` (boolean): Whether to exclude from other players

#### `change_map_element(name, player_id, animation_state, loop)`
> **Description**: Changes the animation state of a map element.  
> **Parameters**:
> - `name` (string): Identifier of the element to change
> - `player_id` (string): The ID of the player
> - `animation_state` (string): New animation state
> - `loop` (boolean): Whether to loop the animation

#### `move_map_element(name, player_id, X, Y, Z)`
> **Description**: Moves a map element to new coordinates.  
> **Parameters**:
> - `name` (string): Identifier of the element to move
> - `player_id` (string): The ID of the player
> - `X`, `Y`, `Z` (number): New map coordinates

#### `remove_map_element(name, player_id)`
> **Description**: Removes a map element.  
> **Parameters**:
> - `name` (string): Identifier of the element to remove
> - `player_id` (string): The ID of the player
</details>

<details><summary><h3>UI Functions</h3></summary>

#### `add_ui_element(name, player_id, texture, animation, animation_state, X, Y, Z, ScaleX, ScaleY)`
> **Description**: Adds a UI element that tracks with the camera view.  
> **Parameters**:
> - `name` (string): Unique identifier for the element
> - `player_id` (string): The ID of the player
> - `texture` (string): Path to texture file
> - `animation` (string): Path to animation file
> - `animation_state` (string): Initial animation state
> - `X`, `Y` (number): Screen position offsets
> - `Z` (number): Z-index relative to UI (not player)
> - `ScaleX`, `ScaleY` (number): Scale factors for the element

#### `update_ui_element(name, player_id, properties)`
> **Description**: Updates properties of a UI element.  
> **Parameters**:
> - `name` (string): Identifier of the element to update
> - `player_id` (string): The ID of the player
> - `properties` (table): Table containing properties to update (x, y, z, ox, oy, scale, rotation, opacity, animation_state)

#### `set_ui_animation(name, player_id, animation_state)`
> **Description**: Changes the animation state of a UI element.  
> **Parameters**:
> - `name` (string): Identifier of the element to change
> - `player_id` (string): The ID of the player
> - `animation_state` (string): New animation state

#### `move_ui_element(name, player_id, X, Y, Z)`
> **Description**: Moves a UI element to new screen position.  
> **Parameters**:
> - `name` (string): Identifier of the element to move
> - `player_id` (string): The ID of the player
> - `X`, `Y` (number): New screen position offsets
> - `Z` (number): Z-index relative to UI (not player)

#### `remove_ui_element(name, player_id)`
> **Description**: Removes a UI element.  
> **Parameters**:
> - `name` (string): Identifier of the element to remove
> - `player_id` (string): The ID of the player
</details>

<details><summary><h3>Cursor Functions</h3></summary>

#### `spawn_cursor(cursor_id, player_id, options)`
> **Description**: Creates a multi-choice cursor based on `options`.  
> **Parameters**:
> - `cursor_id` (string): Unique identifier
> - `player_id` (string): The ID of the player
> - `options` (table): Configuration including texture, animation, and selections  

The options table should include a `movement` direction, a `selections` table, and a `texture` and `animation` for the cursor: 
`        options = {
            texture="/server/assets/net-games/text_cursor.png",
            animation="/server/assets/net-games/text_cursor.animation"
            movement = "vertical", 
            selections = {
                { x=35,y=45,z=0,name='roll',state="CURSOR_RIGHT" },
                { x=35,y=65,z=0,name='megaman',state="CURSOR_RIGHT" },
                { x=35,y=85,z=0,name='protoman',state="CURSOR_RIGHT" }
            }
        }
`

The `movement` parameter can be `horizontal`, `vertical`, or `shoulder`. If `horizontal` the cursor moves when Left or Right is pressed. If vertical the cursor moves if Up or Down. If shoulder the cursor moves when Left Shoulder is pressed.

The `selections` table defines each position the cursor can occupy. The `x`, `y`, and `z` parameters specify location (relative to screen); the `z` is relative to the UI not the player. The `name` is how you will identify the selection. The `cursor_hover` and `cursor_selection` will emit the name so you can react based on the player's selection. The `state` parameter specifies the animation state for the cursor at that position.

#### `Net:on("cursor_hover")`
> **Description**: An event used to react to a player's hovering over a selection when using a cursor. 
> **Parameters**:
> - `event.cursor` (string): Identifier of cursor
> - `event.player_id` (string): The ID of the player
> - `event.selection` (string): Identifier (name) of selection
</details>

#### `Net:on("cursor_selection")`
> **Description**: An event used to react to a player's selection when using a cursor. 
> **Parameters**:
> - `event.cursor` (string): Identifier of cursor
> - `event.player_id` (string): The ID of the player
> - `event.selection` (string): Identifier (name) of the hovered selection
</details>


#### `remove_cursor(cursor_id, player_id)`
> **Description**: Removes a cursor UI.  
> **Parameters**:
> - `cursor_id` (string): Identifier of cursor to remove
> - `player_id` (string): The ID of the player
</details>

<details><summary><h3>Text Functions</h3></summary>

#### `draw_text(text_id, player_id, text, X, Y, Z, font, scale)`
> **Description**: Renders text on screen.  
> **Parameters**:
> - `text_id` (string): Unique identifier
> - `player_id` (string): The ID of the player
> - `text` (string): Content to display
> - `X`, `Y` (number): Screen position
> - `Z` (number): Z-index relative to UI (not player)
> - `font` (string): Font style name
> - `scale` (number): Text scale factor

#### `update_text(text_id, player_id, text)`
> **Description**: Updates existing text content.  
> **Parameters**:
> - `text_id` (string): Identifier of text to update
> - `player_id` (string): The ID of the player
> - `text` (string): New content to display

#### `remove_text(text_id, player_id)`
> **Description**: Removes rendered text.  
> **Parameters**:
> - `text_id` (string): Identifier of text to remove
> - `player_id` (string): The ID of the player
</details>

<details><summary><h3>Timer Functions</h3></summary>

#### `spawn_timer(timer_id, player_id, X, Y, duration, loop)`
> **Description**: Creates a timer display counting up from zero.  
> **Parameters**:
> - `timer_id` (string): Unique identifier
> - `player_id` (string): The ID of the player
> - `X`, `Y` (number): Screen position
> - `duration` (number): Initial time in seconds
> - `loop` (boolean): Whether to loop the timer

#### `resume_timer(timer_id, player_id)`
> **Description**: Resumes a paused timer.  
> **Parameters**:
> - `timer_id` (string): Identifier of timer to resume
> - `player_id` (string): The ID of the player

#### `pause_timer(timer_id, player_id)`
> **Description**: Pauses an active timer.  
> **Parameters**:
> - `timer_id` (string): Identifier of timer to pause
> - `player_id` (string): The ID of the player

#### `update_timer(timer_id, player_id, duration)`
> **Description**: Updates timer duration.  
> **Parameters**:
> - `timer_id` (string): Identifier of timer to update
> - `player_id` (string): The ID of the player
> - `duration` (number): New duration in seconds

#### `remove_timer(timer_id, player_id)`
> **Description**: Removes a timer display.  
> **Parameters**:
> - `timer_id` (string): Identifier of timer to remove
> - `player_id` (string): The ID of the player
</details>

<details><summary><h3>Countdown Functions</h3></summary>

#### `spawn_countdown(countdown_id, player_id, X, Y, duration, loop)`
> **Description**: Creates a countdown display counting down to zero.  
> **Parameters**:
> - `countdown_id` (string): Unique identifier
> - `player_id` (string): The ID of the player
> - `X`, `Y` (number): Screen position
> - `duration` (number): Initial time in seconds
> - `loop` (boolean): Whether to loop the countdown

#### `resume_countdown(countdown_id, player_id)`
> **Description**: Resumes a paused countdown.  
> **Parameters**:
> - `countdown_id` (string): Identifier of countdown to resume
> - `player_id` (string): The ID of the player

#### `pause_countdown(countdown_id, player_id)`
> **Description**: Pauses an active countdown.  
> **Parameters**:
> - `countdown_id` (string): Identifier of countdown to pause
> - `player_id` (string): The ID of the player

#### `update_countdown(countdown_id, player_id, duration)`
> **Description**: Updates countdown duration.  
> **Parameters**:
> - `countdown_id` (string): Identifier of countdown to update
> - `player_id` (string): The ID of the player
> - `duration` (number): New duration in seconds

#### `remove_countdown(countdown_id, player_id)`
> **Description**: Removes a countdown display.  
> **Parameters**:
> - `countdown_id` (string): Identifier of countdown to remove
> - `player_id` (string): The ID of the player
</details>