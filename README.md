# caprover-wsl
Install CapRover to run on Docker in WSL

If like me you are running a Windows server but would also like to run CapRover using Docker within WSL, you might run into the snags I ran into with the default installer.
These two scripts were produced through a trial and error session (with the aid of Gemini 2.5 Pro).  On the one hand, the AI assistant repeatedly suggested previously tried
solutions (the definition of insanity).  On the other hand, with some manual debugging and the right prompts it eventually helped with a working solution.

Here is... 
# The Complete Guide to Installing CapRover on WSL
This guide provides a fail-safe, two-script installation process and step-by-step instructions for the subsequent web-based setup and deployment of a static website.

# Introduction: Why is this necessary?
Installing CapRover on WSL presents a unique set of challenges due to the underlying networking (NAT hairpinning), filesystem interactions, and several bugs or edge cases within the CapRover startup scripts. This guide provides a tested manual installation that bypasses these issues, resulting in a stable and fully functional CapRover instance.

This solution consists of two files that must be placed in the same directory:

1. install-caprover-wsl.bat: The main Windows batch file you will run. It handles Windows-specific tasks, checks for prerequisites, and then calls the Linux script.  *It must be run as an Administrator*.
2. setup_caprover_inside_wsl.sh: A Linux shell script that contains the Docker commands to correctly install CapRover inside your WSL environment.

How to Use

1. Ensure you have public DNS set up for your public IP address, for the name you wish to have as your root domain.  You will need two names assigned, one for the actual root and a wildcard one for subdomains.  For example, for the root domain "mydomain.com" you would need:
   mydomain.com
   *.mydomain.com
3. Save both files (install-caprover-wsl.bat and setup_caprover_inside_wsl.sh) in the same folder on your Windows machine.
4. Ensure Docker Desktop is running or Docker is installed within WSL.
5. Right-click on install-caprover-wsl.bat and select "Run as administrator".
6. The script will handle stopping the Windows service (that takes over port 80) and checking for Docker.
7. It will then open a WSL terminal window and execute the Linux script to install CapRover.
8. When prompted by the Linux script, enter your server's public IP address and press Enter.
9. When prompted by the Linux script, enter your server's root domain and press Enter.
10. The script will complete the entire cleanup and installation process automatically.
11. When it finishes, it will display the URL and default password for you to log in.

# Part 2: First-Time CapRover Setup (Web UI)
After the script finishes successfully, follow these steps in your browser.

1. Navigate and Log In: Open your browser and go to http://YOUR_PUBLIC_IP:3000. You will be greeted by the CapRover login screen. Log in with the default password: captain42.
2. Change Password: The first thing you should do is change your password. Click on your username in the bottom-left corner and go to the "Change Password" tab.
3. Initial Setup Page: You will be taken to the "Initial Setup" page. The script has already set your root domain, but you must now enable HTTPS.
4. Enable HTTPS:
	- Enter a valid email address. Let's Encrypt will use this to send you notifications about your SSL certificates.
	- Click the "Enable HTTPS" button.
	- Wait a minute or two. CapRover will automatically obtain SSL certificates for your root domain (example.com) and the wildcard (*.example.com). The page will reload, and you will be on a secure https connection.
5. Acknowledge the HTTPS Warning: You will see the message: "IMPORTANT: Once you enable HTTPS, you cannot edit the root domain ever again." This is a strong precaution. You can change it later by temporarily disabling HTTPS, but this initial setup is now complete.

---
# Part 3: Deploying Your First Static Site

Follow these steps to deploy your static website.  This example is for a SvelteKit site, but the process should be similar for other static sites.
1. Prepare Your Project: In the root of your SvelteKit project, you need two configuration files.
	- **Dockerfile** (tells Docker how to build your site's container):


```
	# Use a lightweight, official Nginx image as the base
	FROM nginx:1.27-alpine
	
	# The SvelteKit build output is in the 'build' directory.
	# Copy the contents of our local 'build' folder into the
	# default web root directory of the Nginx container.
	COPY ./build /usr/share/nginx/html
```



	- **captain-definition** (tells CapRover to use your Dockerfile):

```
	{
	  "schemaVersion": 2,
	  "dockerfilePath": "./Dockerfile"
	}
```

2. Build and Package Your Site:
	- First, run your local build command to generate the static files:
	`npm run build`
	- Next, create a tarball that includes only the necessary files for deployment:
	`tar -cvf ../deploy.tar ./build ./Dockerfile ./captain-definition`
3. Deploy in CapRover:
	- In the CapRover dashboard, go to the "Apps" tab.
	- Create a new app, giving it a name (e.g., www).
	- Go to the new app's "Deployment" tab.
	- Under "Method 2: Upload Tarball", drag and drop the deploy.tar file you just created.
4. Watch the Build: The "Deployment Progress" window will appear, and you will see the live build logs from your Dockerfile being executed. It will end with a "Build has finished successfully!" message.
5. Verify: Your site is now live! You can access it at the URL provided on the app's dashboard, such as https://www.example.com
