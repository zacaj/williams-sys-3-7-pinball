Custom operating system written for Williams System 3, 4, 6, and 7 pinball machines

Supports:
- scanning the switch matrix, with per-switch configurable debounce settings
- firing the solenoids, with per-solenoid configurable timings
- controlling the lamp matrix, with built in support for blinking lights (single speed)
- six and seven digit displays, including automatically scrolling 6 digit displays to show the millions digit once someone rolls the score
- extra display memory for temporarily displaying things like hurry up scores, etc
- (hacky) delays and multi-threading support

Doesn't support:
- saving highscores or audits
- any coin-up logic
- test modes
- double buffering

The code:
- currently a bit of a mess.  There's separate files for about 5 different games I worked on at various times, but only the original Hot Tip game was ever finished or seriously tested.  Subsequent games added a lot of new features that hot tip didn't use, but that also means that hot tip doesn't currently compile either.  The newest game is Blackout.  It's mostly coded, but has a crash somewhere that I never tracked down before selling the machine.  

Making your own game:  
- if you'd like to try to use this code as a basis for making your own new ruleset for a game, contact me!  I'm happy to help out and walk you through it, etc.  You'll basically hae to just branch off of master, then copy the blackout.asm file, and update the .bat files to point to your new file, then start stripping out the exist game code and updating it to support your game. A lot of this should be a bit cleaner but without much interest so far from other people to use this, making it easily splittable and updatable hasn't been a big priority for me.