powershell $Host.ui.RawUI.WindowTitle = Convert-Path (pwd).path
powershell ./main.ps1 -port 58080
