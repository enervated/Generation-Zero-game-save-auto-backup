This Windows command script is designed to automatically maintain game save backups. The script is intended to run
at all times and loops on a schedule, periodically checking to see whether the specified game executable is running.
Once the game has been detected as running, the script (1) waits for the game to exit, (2) backs up the current game
saves to a new backup directory (named with the then-current date and time), (3) deletes the oldest game save backup
directory (if necessary), and (4) returns to watching for the game to run again.

The following things are configurable in the "Configuration" section below:

   The game save source directory.
   Default: %UserProfile%\Documents\Avalanche Studios\GenerationZero\Saves

   The game save backup directory.
   Default: %UserProfile%\Documents\Avalanche Studios\GenerationZero\Saves Backups

   The game executable name.
   Default: GenerationZero_F.exe

   How many game save backup directories should be maintained.
   Default: 20

   How often the script should check whether or not the game is running (in seconds).
   Default: 60

Backup subdirectories are created in the "YYYY-MM-DD @ HHMMSS" naming format. The oldest game save backup directory
is identified by name and is only deleted if the configured maximum number of game save backup directories has
already been met. The script operates on all subdirectories under the "BackupDir" configured below, so it is
very important to avoid using that directory for anything else.

If the game is never detected as running, the script will do nothing at all. And importantly, the game save source
directory is never touched, under ANY circumstances. To be clear: The ONLY changes this script makes is to create and
delete game save backup directories under the "BackupDir" configured below, or to create the "BackupDir" itself.

This script was created with Generation Zero in mind, but is easily adaptable to other games, or really any use case
where you'd like to back up a directory after a certain application runs and exits. By default, Generation Zero game
saves are stored under your user directory, and administrator rights are NOT required. You are strongly advised to
run this script without elevation.

Since it's doubtful you want this script's command window to be displayed at all times, and taking up task bar space,
you may want to use the free NirCmd utility, available at https://www.nirsoft.net/utils/nircmd.html. Using NirCmd,
you can run the script with a command line of the format:

nircmd.exe execmd "[path to this script]"

For example:

nircmd.exe execmd "%UserProfile%\Documents\Generation Zero game save auto-backup.cmd"

This will cause the script to run without a command window showing. You can show its window using this command:

nircmd.exe win show title "Generation Zero game save auto-backup"

Whether you run the script normally, or using "nircmd.exe execmd", you can hide its window using this command:

nircmd.exe win hide title "Generation Zero game save auto-backup"

Before making changes to this script, it's a good idea to first ensure that it is not running. You can stop the script
simply by closing its window. If its window is hidden, you can show it using the command provided above. You can also
stop the script -- whether or not its window is showing -- using this command:

nircmd.exe win close title "Generation Zero game save auto-backup"

Changes made to the script configuration will not be in effect until the script has been restarted. Finally, DO NOT
enable the read-only attribute on this script, or it will not run at all.

This script should work on Windows 7/8/8.1/10/11 and later with any locale and date/time format settings.
