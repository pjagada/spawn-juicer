#IfWinActive, Minecraft
{
  RAlt::  ; Pause all macros
    Suspend
  return

    PgDn:: ; Reset and give spawn
      Reset(0)
    return

    End:: ; Perch
      Perch()
	return

    F5:: ; Reload if macro locks up
      Reload
   return

   ^B:: ; Add a spawn (the one that the macro most recently gave you) to the blacklisted spawns.
		AddToBlacklist()
	return

  Delete:: ; kill villager
    GiveSword()
  return
}

^End:: ; Safely close the script
  ExitApp
return