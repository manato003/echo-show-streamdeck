' Runs update_switchbot_status.ps1 with no console window (for Task Scheduler).
' The script directory is resolved automatically - no path to edit.
Set objFSO = CreateObject("Scripting.FileSystemObject")
scriptDir = objFSO.GetParentFolderName(WScript.ScriptFullName)
Set objShell = CreateObject("WScript.Shell")
objShell.Run "powershell.exe -ExecutionPolicy Bypass -NoProfile -File """ & scriptDir & "\update_switchbot_status.ps1""", 0, False
