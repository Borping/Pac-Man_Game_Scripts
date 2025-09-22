# Pac-Man_Game_Scripts
A collection of gdscript files used in my Pac Man game!

## Features  
- **Modular Power-Up System**: All power-ups (speed, magnet, teleport, eat) are handled through a SignalBus (autoloaded singleton), making them easy to modify, extend, or swap out without breaking the rest of the game.
- **Dynamic Enemy States**: Enemy cats feature multiple states (chasing, grace, edible), complete with albedo blinking effects to visually signal their behavior, just like classic Pac-Man.
- **Flexible Collectible Spawner**: Cheese/cheese wheel spawns are managed via a coordinate-based spawner system, which dynamically tracks consumed items and only respawns what’s missing—perfect for level scaling and replayability.
- **Scene Reload Safety**: Careful handling of timers, signals, and state resets ensures the game can be paused or restarted without issue.
- **Player Feedback & Immersion**: Effects like smoke puffs on teleport, invincibility blinking, and cutscenes before cheese spawns add polish and give the game a professional feel.

## Visuals
- **Rat character being chased**
  
![RatChase](https://i.imgur.com/JyYp1Wq.png)

- **Consuming enemy with power-cheese wheel**
  
![RatEat](https://i.imgur.com/fvkFuc8.png)

- **Cheese spawning from above**
  
![CheeseSpawn](https://i.imgur.com/DsK6OMK.png)

- **Death Screen**
  
![RatDeath](https://i.imgur.com/Ayk98QM.png)
