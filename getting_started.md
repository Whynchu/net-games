# Net Games (Getting Started)

### Installation
> 1. Copy `/scripts/net-games/` to your server script folder.
> 2. Copy `/assets/net-games/` to your server assets folder.
> 3. Include the following code at the start of any script that needs to access net-games.

```
local games = require("scripts/net-games/framework")
```

> You will then access the functions via the variable you specify. For example, if you use `games` as your variable (like the example above) you would access the functions with this variable appended to the beginning like so `games.freeze_player(player_id)`. 

### Map Requirement for player_freeze()

> For any server map that you need to use the player_freeze() function you will need to add a Custom Property (string) in Tiled named "Stasis" and give it an X,Y,Z coordinate (for example "15,10,2"). The coordinate must be a walkable tile in order for net-games to report button presses back to you (so you can allow players to navigate custom menus and things like that). 
> 
> **Important note:** The stasis location can be one of your map's existing walkable tiles as the player is made invisible when player_freeze() is called so it can be right in the middle of your walkable area and no one will see those players.  


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

<img width="575" height="384" alt="onb-ui-guide" src="https://github.com/user-attachments/assets/6b68c105-a7da-4c1e-8089-6ac47b085869" />

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
