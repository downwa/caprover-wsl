# caprover-wsl
Install CapRover to run on Docker in WSL

If like me you are running a Windows server but would also like to run CapRover using Docker within WSL, you might run into the snags I ran into with the default installer.
These two scripts were produced through a trial and error session (with the aid of Gemini 2.5 Pro).  On the one hand, the AI assistant repeatedly suggested previously tried
solutions (the definition of insanity).  On the other hand, with some manual debugging and the right prompts it eventually helped with a working solution.

This solution consists of two files that must be placed in the same directory:

1. install-caprover-wsl.bat: The main Windows batch file you will run. It handles Windows-specific tasks, checks for prerequisites, and then calls the Linux script.
2. setup_caprover_inside_wsl.sh: A Linux shell script that contains the precise, battle-tested sequence of Docker commands to correctly install CapRover inside your WSL environment.
