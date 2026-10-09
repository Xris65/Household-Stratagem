@echo off
:start
cls
echo Lancement de HouseholdStratagem (Choix de l'appareil)...
cd app
call flutter run
cd ..
echo.
echo =======================================================
echo [r] Relancer le script
echo [q] Quitter
set /p RESTART="Choix (r/q) > "
if /i "%RESTART%"=="r" goto start
