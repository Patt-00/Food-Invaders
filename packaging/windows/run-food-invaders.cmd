@echo off
setlocal
set "APP_ROOT=%~dp0"
pushd "%APP_ROOT%game"
"%APP_ROOT%DOSBox-X\dosbox-x.exe" -nopromptfolder -fastlaunch -conf "%APP_ROOT%config\desktop.conf" -noautoexec -c "mount c ." -c "c:" -c "INVADERS.COM" -c "exit"
set "RESULT=%ERRORLEVEL%"
popd
exit /b %RESULT%
