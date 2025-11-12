# Simon Says (Documentation)

### Installation
> 1. Copy the `/scripts/simon-says.lua` file to your server scripts folder.
> 2. Add the required object to your map to spawn a Simon NPC (see below)

&nbsp; 
### Spawning a Simon Says NPC
> You can add a CyberSimon Says NPC by including the `simon-says.lua` in your server's scripts folder and adding a point on your map in Tiled > with the Class set to `Simon Says` and the following custom properties:
> - `Limit` (optional) - A number greater than zero. This sets how many successful button presses the player must make to win. 
> - `Time` (optional) - A number greater than zero. This sets how many seconds the player has to complete the required button presses.

&nbsp;
### Reacting a Player's Win or Loss (coding required)

> If the player wins or loses the game will emit an event via `Net:on("game_complete")` with the following data returned:
>  - `event.player_id` (string): The ID of the frozen player
>  - `event.game` (string): The name of the game (in this case "Simon Says")
>  - `event.area` (string): The ID of the area where this Simon exists.
>  - `event.limit` (string): The limit set for this Simon.
>  - `event.time` (string): The time set for this Simon.
>  - `event.actor` (string): The bot ID of the Simon (the name of the object in your map).
> 
> These parameters will allow you to know exactly which Simon the player was playing with and reward them accordingly. This means you can have one Simon give Zenny for winning, while another gives a Bugfrag.  
