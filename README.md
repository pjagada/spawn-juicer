# Spawn Juicer

Reset macro for multi-instance Minecraft Java Edition 1.16+ set seed speedrunning with automatic spawn resetting

## Features

- Each instance continuously and automatically resets until a good spawn is found.
- The player will automatically be switched to the instance with the best spawn.
- Any instance not being played or resetted can be suspended automatically to use no processing resources.
- Compatible with Fast Reset mod
- Mute all resetting sounds
- Customizable seed and difficulty
- The "goodness" of a spawn is judged off of its distance to a user-defined centerpoint.
- The player can set their own whitelist and/or blacklist to supplement the centerpoint+radius resetting.
- Scenes in OBS are automatically switched.
- Track flint rates and attempts
- Perch hotkey and villager killer hotkey
- Move speedrun worlds into an oldWorlds folder
- Show F3 automatically at run start
- Give angle to initial destination through TTS at run start

### Planned features and fixes
- Fixing fullscreen
- Fixing stats
- Put world moving and stat tracking in separate script
- Fix OBS scenes not switching
- Option to pause resetting while playing
- Settings reset

## Setup instructions

Download the [latest release] and extract all files into one folder.

Watch [the setup video] and follow those instructions (the macro options are slightly different). The setup script in the video is the same as the one you just downloaded, and the actual reset script is replaced by spawn_juicer.ahk.

## List of hotkeys

Ctrl + End: unmute and unsuspend all instances and close the script

All of the following hotkeys are only functional if an unsuspended minecraft is the active window:

RAlt: Pause macro

Page Down: Reset

F5: unmute and unsuspend all instances and reload the script

Ctrl + B: add the most recent spawn to the blacklist

Delete: open to LAN and give netherite sword with sharpness

End: open to LAN and put dragon in perch approach

Ctrl + H: update the stats text file

## FAQ

## Credits

Specnr - original creator of this macro

jojoe77777 - miscellaneous help, initial creator of automatic spawn resetting

MagneticMaybe, Rayoh, HanabiYaki - early testing

  [latest release]: <https://github.com/pjagada/spawn-juicer/releases/latest>
  [the setup video]: <https://youtu.be/0xAHMW93MQw>
