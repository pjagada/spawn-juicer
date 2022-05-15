# Spawn Juicer

Reset macro for single and multi-instance Minecraft Java Edition set seed speedrunning with automatic spawn resetting

## Features

- Each instance continuously and automatically resets until a good spawn is found.
- The player will automatically be switched to the instance with the best spawn.
- Any instance not being played or resetted can be suspended automatically to use no processing resources, with the option to free memory.
- Custom affinity can be set for playing versus background instances for performance.
- Compatible with Fast Reset mod
- Compatible with WorldPreview mod
- v1.2 and beyond are compatible with and require [atum] (legal as of February 4, 2022)
- The "goodness" of a spawn is judged off of its distance to a user-defined centerpoint.
- The player can set their own whitelist and/or blacklist to supplement the centerpoint+radius resetting.
- Scenes in OBS are automatically switched.
- Track flint rates and attempts
- Perch hotkey and villager killer hotkey
- Move speedrun worlds into an oldWorlds folder
- Show F3 automatically at run start
- Give angle to initial destination through TTS at run start

### Planned features and fixes
- Settings reset
- Practice mode (go to instance 1 title screen)
- Initialize all instances' seeds
- Toggle all instances' sprint, hitboxes

## Setup instructions

Download the [latest release] and extract all files into one folder.

Watch [the setup video] and follow those instructions (the macro options are slightly different). The setup script in the video is the same as the one you just downloaded, and the actual reset script is replaced by spawn_juicer.ahk.

When starting up the macro, make sure that all instances are either on the title screen or on the pause menu of an atum-ed world.

### Autoresetter blacklists
- [My blacklist] (for 1.17 ssg gravel seed)
- [LeonToast's blacklist] (for 1.17 ssg gravel seed but stricter)

### Muting resets
If the WorldPreview reset sounds are annoying, use [this resource pack].

## List of hotkeys

Ctrl + End: unmute and unsuspend all instances and close the script

All of the following hotkeys are only functional if an unsuspended minecraft is the active window:

RAlt: Pause macro

Page Down: Give good spawn

F5: unmute and unsuspend all instances and reload the script

Ctrl + B: add the most recent spawn to the blacklist

Delete: open to LAN and give netherite sword with sharpness

End: open to LAN and put dragon in perch approach

## Help

Ask in [#public-help] in the [SSG Discord] if you have any questions about anything.

## Credits

Char - WorldPreview support

Specnr - original creator of this macro

jojoe77777 - miscellaneous help, initial creator of automatic spawn resetting

EvanKae - affinity help

MagneticMaybe, Rayoh, HanabiYaki - early testing

Void_X_Walker - atum and WorldPreview mods

  [latest release]: <https://github.com/pjagada/spawn-juicer/releases/latest>
  [the setup video]: <https://youtu.be/0xAHMW93MQw>
  [My blacklist]: <https://cdn.discordapp.com/attachments/846477312438566934/919571471737704508/blacklist.txt>
  [LeonToast's blacklist]: <https://cdn.discordapp.com/attachments/854508085422325770/859798746098696222/blacklist.txt>
  [atum]: <https://github.com/VoidXWalker/atum/releases/latest>
  [this resource pack]: <https://cdn.discordapp.com/attachments/755882336209338388/970560304763273297/mutesounds.zip>
  [#public-help]: <https://discord.com/channels/755878212571103392/861679137805434930>
  [SSG Discord]: <https://discord.gg/EFvygzt>
