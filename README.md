# TTT Randomat 2.0 - "Christmas Cheer" Event
Adds a new event that turns one player into an elf that must spread christmas cheer and convert all other players to elves to win.

## Dependencies
[TTT Randomat 2.0](https://steamcommunity.com/sharedfiles/filedetails/?id=2055805086) - Base Randomat mod which will automatically load this event.\
[Custom Roles for TTT](https://steamcommunity.com/sharedfiles/filedetails/?id=2421039084) - Base roles mod which this event uses to create the bee-themed roles.\

## Configuration
Configurations can be temporarily changed using the ULX admin system and the [Randomat 2.0 ULX Plugin](https://steamcommunity.com/sharedfiles/filedetails/?id=2096758509)

More permanently, the ConVars below can be put in the server.cfg (for dedicated servers) or listenserver.cfg (for peer-to-peer servers).

### ConVars
_ttt_randomat_christmascheer_ - Default: 1 - Whether this event is enabled.\
_ttt_randomat_christmascheer_min_players_ - Default: 0 - The minimum number of players required for this event to start.\
_ttt_randomat_christmascheer_weight_ - Default: -1 - The weight this event should use during the randomized event selection process.\
_randomat_christmascheer_activation_timer_ - Default: 20 - Time in seconds before the starting elf is revealed.
_randomat_christmascheer_elf_size_ - Default: 0.5 - The size multiplier for the elf to use when they are revealed. (e.g. 0.5 = 50% size)
_randomat_christmascheer_disable_santa_ - Default: 1 - Whether players with the Santa role should be switched to regular detectives.
