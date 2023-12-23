@echo off & cls & setlocal

:: This Windows command script is designed to automatically maintain game save backups. The script is intended to run
:: at all times and loops on a schedule, periodically checking to see whether the specified game executable is running.
:: Once the game has been detected as running, the script (1) waits for the game to exit, (2) backs up the current game
:: saves to a new backup directory (named with the then-current date and time), (3) deletes the oldest game save backup
:: directory (if necessary), and (4) returns to watching for the game to run again.
::
:: The following things are configurable in the "Configuration" section below:
::
::    The game save source directory.
::    Default: %UserProfile%\Documents\Avalanche Studios\GenerationZero\Saves
::
::    The game save backup directory.
::    Default: %UserProfile%\Documents\Avalanche Studios\GenerationZero\Saves Backups
::
::    The game executable name.
::    Default: GenerationZero_F.exe
::
::    How many game save backup directories should be maintained.
::    Default: 20
::
::    How often the script should check whether or not the game is running (in seconds).
::    Default: 60
::
:: Backup subdirectories are created in the "YYYY-MM-DD @ HHMMSS" naming format. The oldest game save backup directory
:: is identified by name and is only deleted if the configured maximum number of game save backup directories has
:: already been met. The script operates on all subdirectories under the "BackupDir" configured below, so it is
:: very important to avoid using that directory for anything else.
::
:: If the game is never detected as running, the script will do nothing at all. And importantly, the game save source
:: directory is never touched, under ANY circumstances. To be clear: The ONLY changes this script makes is to create and
:: delete game save backup directories under the "BackupDir" configured below, or to create the "BackupDir" itself.
::
:: This script was created with Generation Zero in mind, but is easily adaptable to other games, or really any use case
:: where you'd like to back up a directory after a certain application runs and exits. By default, Generation Zero game
:: saves are stored under your user directory, and administrator rights are NOT required. You are strongly advised to
:: run this script without elevation.
::
:: Since it's doubtful you want this script's command window to be displayed at all times, and taking up task bar space,
:: you may want to use the free NirCmd utility, available at https://www.nirsoft.net/utils/nircmd.html. Using NirCmd,
:: you can run the script with a command line of the format:
::
:: nircmd.exe execmd "[path to this script]"
::
:: For example:
::
:: nircmd.exe execmd "%UserProfile%\Documents\Generation Zero game save auto-backup.cmd"
::
:: This will cause the script to run without a command window showing. You can show its window using this command:
::
:: nircmd.exe win show title "Generation Zero game save auto-backup"
::
:: Whether you run the script normally, or using "nircmd.exe execmd", you can hide its window using this command:
::
:: nircmd.exe win hide title "Generation Zero game save auto-backup"
::
:: Before making changes to this script, it's a good idea to first ensure that it is not running. You can stop the script
:: simply by closing its window. If its window is hidden, you can show it using the command provided above. You can also
:: stop the script -- whether or not its window is showing -- using this command:
::
:: nircmd.exe win close title "Generation Zero game save auto-backup"
::
:: Changes made to the script configuration will not be in effect until the script has been restarted. Finally, DO NOT
:: enable the read-only attribute on this script, or it will not run at all.
::
:: This script should work on Windows 7/8/8.1/10/11 and later with any locale and date/time format settings.
::
:: Version history:
:: v1.0: Initial release.

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Configuration
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Specify the full path to the directory where the game saves are located, omitting quotes and trailing backslash. This
:: setting is not case-sensitive. The default should work for most systems. Note that %UserProfile% will be
:: automatically converted to your user directory (e.g. C:\Users\SniperGirl).

set SourceDir=%UserProfile%\Documents\Avalanche Studios\GenerationZero\Saves

:: Specify the full path to the directory where the game save backups will be located, omitting quotes and trailing
:: backslash. This setting is not case-sensitive. The default should work for most systems. The script will attempt to
:: create this directory, if necessary. IMPORTANT: Choose a directory that will ONLY be used for game save backups
:: created by this script.

set BackupDir=%UserProfile%\Documents\Avalanche Studios\GenerationZero\Saves Backups

:: Specify the name of the game's .EXE file, omitting quotes. This setting is not case-sensitive.

set EXEName=GenerationZero_F.exe

:: Specify how many backup directories should be maintained. This setting must be a positive integer. Be mindful of how
:: much space backups are using. The default is 20, which will probably result in a few hundred MB of space consumption
:: for most users. The minimum allowed value is 1, and the maximum allowed value is 100.

set MaxBackups=20

:: Specify how often the script should check whether or not the game (i.e. EXEName, as set above) is running.
:: The default is 60, which will result in just a few seconds of CPU usage for every 24 hours the script runs.
:: If you make this number too large, you run the risk of running and exiting the game without the script catching it.
:: Or, the script may catch it, but you may exit the game and shut down Windows before the script performs a backup.
:: The minimum allowed value is 10, and the maximum allowed value is 3600.

set ProcessCheckFrequency=60

::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Do not make routine changes below this line.
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

:: Run the script in append mode to prevent multiple instances from running:
call :Lock
exit /b
:Lock
call :Script 9>>"%~f0"
exit /b
:Script

:: Set the command window title, and also BackupMessage, to indicate that the script hasn't done anything yet:
title Generation Zero game save auto-backup
set BackupMessage=N/A

:: Make sure SourceDir and BackupDir each exist, first creating BackupDir if necessary:
if not exist "%SourceDir%\"       set ErrorMessage=SourceDir "%SourceDir%" not found. & goto :Error
if not exist "%BackupDir%" md "%BackupDir%"
if not exist "%BackupDir%\"       set ErrorMessage=BackupDir "%BackupDir%" does not exist and could not be created & goto :Error

:: Check that the MaxBackups and ProcessCheckFrequency variables are within reasonable limits:
if %MaxBackups% lss   1             set ErrorMessage=MaxBackups must be 1 or greater. & goto :Error
if %MaxBackups% gtr 100             set ErrorMessage=MaxBackups must be no greater than 100. & goto :Error
if %ProcessCheckFrequency% lss 10   set ErrorMessage=ProcessCheckFrequency must be no lower than 10. & goto :Error
if %ProcessCheckFrequency% gtr 3600 set ErrorMessage=ProcessCheckFrequency must be no greater than 3600. & goto :Error

:: Turn off the %BackupNeeded% flag, so we don't create another backup until we've seen %EXEName% run and then exit:
set BackupNeeded=0

:CheckIfRunning

cls & echo.

:: Display status messages, including the last directories that were created and deleted, as applicable:
echo Last action(s) during this run: & echo. & echo    %BackupMessage%
if defined DeletionMessage echo    %DeletionMessage%
echo. & echo Watching for "%EXEName%" every %ProcessCheckFrequency% seconds... & echo.

set EXERunning=0

:: Check whether or not EXEName is running:
tasklist /FI "IMAGENAME eq %EXEName%" /FO CSV 2>nul | find /i "%EXEName%" >nul
if "%ErrorLevel%" == "0" (set EXERunning=1) & (set BackupNeeded=1) & (echo Detected "%EXEName%"; waiting for it to exit to perform a backup... & echo.)

if "%BackupNeeded%" == "0"                           timeout %ProcessCheckFrequency% >nul & goto :CheckIfRunning
if "%BackupNeeded%" == "1" (if "%EXERunning%" == "1" timeout %ProcessCheckFrequency% >nul & goto :CheckIfRunning)
if "%BackupNeeded%" == "1" (if "%EXERunning%" == "0" goto :PerformBackup)

:PerformBackup

:: Obtain the date and time regardless of Windows locale, language or date/time format:
for /f "tokens=1-6 delims=/: " %%a in ('robocopy "|" . /NJH ^| find ":"') do (set "Year=%%a" & set "Month=%%b"  & set "Day=%%c"
                                                                              set "Hour=%%d" & set "Minute=%%e" & set "Second=%%f")

:: Name and create the new backup directory, based on the current date and time, in "YYYY-MM-DD @ HHMMSS" format:
set NewBackupDir=%Year%-%Month%-%Day% @ %Hour%%Minute%%Second%
md "%BackupDir%\%NewBackupDir%"
if not exist "%BackupDir%\%NewBackupDir%\" set ErrorMessage=Error creating NewBackupDir "%NewBackupDir%". & goto :Error

:: Copy the game save directory to the new backup directory:
:: /S:         Copy subdirectories, but not empty ones.
:: /COPY:DAT:  Copy data (D), attributes (A), and timestamps (T) when copying files.
:: /DCOPY:DAT: Copy data (D), attributes (A), and timestamps (T) when copying directories.
:: /R:10:      Number of times to retry failed copy operations.
:: /W:10:      How much time to wait between retries, in seconds.
:: /NJH:       Don't print the RoboCopy job header in the output.
robocopy "%SourceDir%\\" "%BackupDir%\%NewBackupDir%\\" /S /COPY:DAT /DCOPY:DAT /R:10 /W:10 /NJH >nul

:: Exit if the copy failed, otherwise update BackupMessage, to include it in the next status message:
set ExitCode=%ErrorLevel%
if not "%ExitCode%" == "1" set ErrorMessage=Error copying "%SourceDir%" to "%BackupDir%\%NewBackupDir%". & goto :Error

set BackupMessage=Backed up "%SourceDir%" to "%BackupDir%\%NewBackupDir%"

:: Turn off the BackupNeeded flag, so we don't create a backup until we've seen EXEName run and then exit again:
set BackupNeeded=0

:: Count the number of existing backup directories, and identify the oldest one by name:
set BackupDirCount=0
set OldestBackupDir=
for /f "tokens=*" %%a in ('dir "%BackupDir%" /a:d /b /o:n') do (if not defined OldestBackupDir (set "OldestBackupDir=%BackupDir%\%%a")) & set /a BackupDirCount+=1

:: If MaxBackups has been exceeded, delete the oldest backup directory, and update DeletionMessage, to include it in the next status message:
if %BackupDirCount% gtr %MaxBackups% (
   rd /s /q "%OldestBackupDir%\"
   if exist "%OldestBackupDir%\" (set ErrorMessage=Error deleting OldestBackupDir "%OldestBackupDir%". & goto :Error)
   set DeletionMessage=Deleted "%OldestBackupDir%")

:: Loop back and check if EXEName is running:
goto :CheckIfRunning

:Error

:: Display an explanatory message for any error that has been detected before exiting the script:
cls
echo.
echo %ErrorMessage%
echo.
echo Exiting.
echo.
pause
exit /b

:: End of script
