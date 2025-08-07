# caprover-wsl
Install CapRover to run on Docker in WSL

If like me you are running a Windows server but would also like to run CapRover using Docker within WSL, you might run into the snags I ran into with the default installer.
These two scripts were produced through a trial and error session (with the aid of Gemini 2.5 Pro).  On the one hand, the AI assistant repeatedly suggested previously tried
solutions (the definition of insanity).  On the other hand, with some manual debugging and the right prompts it eventually helped with a working solution.

This solution consists of two files that must be placed in the same directory:

1. install-caprover-wsl.bat: The main Windows batch file you will run. It handles Windows-specific tasks, checks for prerequisites, and then calls the Linux script.
2. setup_caprover_inside_wsl.sh: A Linux shell script that contains the Docker commands to correctly install CapRover inside your WSL environment.

How to Use

1. Save both files (install-caprover-wsl.bat and setup_caprover_inside_wsl.sh) in the same folder on your Windows machine.
2. Ensure Docker Desktop is running or Docker is installed within WSL.
3. Right-click on install-caprover-wsl.bat and select "Run as administrator".
4. The script will handle stopping the Windows service (that takes over port 80) and checking for Docker.
5. It will then open a WSL terminal window and execute the Linux script to install CapRover.
6. When prompted by the Linux script, enter your server's public IP address and press Enter.
7. The script will complete the entire cleanup and installation process automatically.
8. When it finishes, it will display the URL and default password for you to log in.
