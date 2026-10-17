@echo off
TEST.COM > TESTLOG.TXT
if errorlevel 1 goto failed
echo PASS>STATUS.TXT
goto done
:failed
echo FAIL>STATUS.TXT
:done
exit
