#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, force

/*
args:
1: speakString
2: speakRate
*/

#Include functions.ahk

speak_String = %1%
speak_Rate = %2%

oSPVoice := ComObjCreate("SAPI.SpVoice")
oSpVoice.Rate := speak_Rate
oSpVoice.Speak(speak_String, 0) ;SVSFlagsAsync := 0x1