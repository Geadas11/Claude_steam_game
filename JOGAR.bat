@echo off
rem Joga a partir do projeto descarregado do GitHub (Windows).
rem 1.a vez: descarrega o Godot 4.3 portatil (130 MB) e prepara as texturas
rem e os modelos (demora; depois so o que mudou). Depois abre o jogo.
setlocal
cd /d "%~dp0"
set "GD=tools\godot"
set "GODOT=%GD%\Godot_v4.3-stable_win64.exe"
set "GODOTC=%GD%\Godot_v4.3-stable_win64_console.exe"

if exist "%GODOT%" goto :tem_godot
echo A descarregar o Godot 4.3 - 130 MB, so desta vez...
if not exist "%GD%" mkdir "%GD%"
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol='Tls12'; $ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_win64.exe.zip' -OutFile '%GD%\godot.zip'; Expand-Archive -Force '%GD%\godot.zip' '%GD%'; Remove-Item '%GD%\godot.zip'"
if exist "%GODOT%" goto :tem_godot
echo Nao consegui descarregar o Godot. Verifica a ligacao a internet e tenta outra vez.
pause
exit /b 1

:tem_godot
echo.
echo A preparar texturas e modelos. Da primeira vez pode demorar de 20 minutos
echo a mais de uma hora, conforme o PC; depois so prepara o que mudou.
echo Nao feches esta janela.
echo.
"%GODOTC%" --headless --path . --import
if not exist ".godot\imported" goto :falhou

:jogar
start "" "%GODOT%" --path .
exit /b 0

:falhou
echo A preparacao nao terminou. Corre outra vez o JOGAR.bat para continuar.
pause
exit /b 1
