@echo off
rem Abre o projeto no editor do Godot (Windows).
rem Se ainda nao houver Godot em tools\godot, descarrega-o primeiro (130 MB).
setlocal
cd /d "%~dp0"
set "GD=tools\godot"
set "GODOT=%GD%\Godot_v4.3-stable_win64.exe"

if exist "%GODOT%" goto :tem_godot
echo A descarregar o Godot 4.3 - 130 MB, so desta vez...
if not exist "%GD%" mkdir "%GD%"
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_win64.exe.zip' -OutFile '%GD%\godot.zip'; Expand-Archive -Force '%GD%\godot.zip' '%GD%'; Remove-Item '%GD%\godot.zip'"
if exist "%GODOT%" goto :tem_godot
echo Nao consegui descarregar o Godot. Verifica a ligacao a internet e tenta outra vez.
pause
exit /b 1

:tem_godot
echo A abrir o editor. Da primeira vez prepara as texturas e os modelos
echo (a barra de progresso aparece no proprio editor; pode demorar).
start "" "%GODOT%" --path . -e
exit /b 0
