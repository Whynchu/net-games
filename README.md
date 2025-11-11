<!-- https://pandao.github.io/editor.md/en.html -->

# What is Net Games?

> For script coders, the Net Games framework provides tools for creating minigames and custom user interfaces within an Open Net Battle servers. It handles UI elements, text rendering, timers, countdowns, and cursors. This script is designed for server coders who are comfortable writing LUA scripts based on the ONB server API.
>
> For server creators, this repository will be the place to find plug-n-play games and experiences built on the Net Games framework, many of which you can add to your servers without any coding experience. 

&nbsp;
# Pre-Built Games (for server creators)

> Click on any of the titles below to read an extended description and find links to information.
<details><summary><h4>1. CyberSimon Says (game)</h4></summary>
Recreates the Green Navi from BN3 that plays Simon Says with the player. This script allows you to spawn customizable *CyberSimon Says* NPCs (each with adjustable time limits and score to win). [Documentation](# "Documentation")
</details><!--
<details><summary><h4>2. Tournaments</h4></summary>
Recreates the Tournaments from BN4 and EXE4.5, allowing you to spawn Tournament Boards on your server that (when interacted with) will allow players to compete in single player or multiplayer MMBN style tournaments. Even without eight players this module will fill empty roster with NPCs so groups of any size can play. [Documentation](# "Documentation")
</details>-->
<!--
<details><summary><h5>3. Zenny Gambler</h5></summary>
Recreates the Green Navi from BN3 that lets you bet your zenny that you can choose the winning position on a 2, 3, or 4 option board. [Documentation](# "Documentation")
</details>-->

&nbsp;
# Documentation (for coders)

If you're a coder looking to build a game or experience using Net Games check out the information below.

1. [Getting Started Guide](# "")
2. [API Documentation](# "")
3. Demo Server

The demo server currently spawns two NPCs (besides the Simon Says NPC): the CyberBat spawns a Libertaion Order Point UI (that can be incremented by pressing LS) and whereas Protoman spawns text and a cursor allowing the player to change the bot's avatar. The code that handles each NPC is seperated and easily readable in the `demo.lua` script. 


