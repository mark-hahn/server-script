# server-script

*Atom editor package to sync files and/or run a script on the server*


![server-script](https://cloud.githubusercontent.com/assets/811455/13936809/970eaf56-ef7d-11e5-858b-589a63b23419.gif)


### Sync files (Optional)

You can sync local changed files to a server by using an Atom command and/or sync on every save.

### Run script on server (Optional)

Write and edit a script on the local machine with Atom and then run the script on a server using an Atom command and/or run it on every save. You will be able to move existing server scripts to a local project folder and then run them on any server without putting the script on the server.

### Install

Run `apm install server-script` on the command line or use the settings page.

**There is no need to install anything on the server.**

Your local machine must have `rsync` installed.
Your local machine and the server must have `ssh` running. Test that SSH works by executing `ssh myUser@myServer.com ls` on the command line.  If you need a password to access the server use `ssh myUser:myPwd@myServer.com ls`.

### Usage

- Load a project
- Run the Atom command `server-script:run`.  The keybinding `ctrl-alt-shift-R` is provided as a default.
- A notification will pop up to tell you the folder `.server-script` was created in the root of your project. Note that each project will have its own folder.
- At this point nothing will happen on execution of the `server-script:run` command or when saving. You must set up the config file first.
- After configuring, the server-script will be immediately active. Note that all server operations are run in the background.  So even though the commands in the console may appear slow nothing is blocking.  You may go back to editing with no delay.
- Any changes to the configuration are immediately applied.

### Contents Of The `.server-script` Folder

- `.gitignore`: This is a local version of a `.gitignore` file.  It contains one entry to block the commit of the file `secrets.cson` which contains sensitive login information.

- `secrets.cson`: Server login information. This doesn't need to be set up if you are using SSH key files and the local user is the same as the user on the server.  See the file for instructions.

- `setup.cson`: General configuation for the server connection and options.

- `build.sh`: A script file to run on the server. Initially this script just contains an `echo` command so that this package can be easily tested.  Later you can put your own build script in.  Or you can rename or replace this file and put its name in the config file.

### Config File Setup (`setup.cson`)

- **server**:
  - **location**: Server address such as `example.com` or `192.168.0.1`
  - **projectRoot**: Path on server to the project root such as `~/my-app`


- **options**:
  - **syncChangedFiles**: On every server-script run command and/or when saving, sync local project directory with remote.  Default is `no`
  - **scriptOnRun**:  A script to run on the server when `server-script:run` is executed. If this is blank then nothing is run.  Default is `build.sh`.
  - **scriptOnSave**:  A script to run on the server on every file save. If this is blank then nothing is run on save.  Default is blank.
  - **useGitignore**: Enable to avoid syncing files to the server that are ignored in the `.gitignore` file.  Default is `yes`.
  - **logToConsole**: When enabled, all commands are logged to the dev console in Atom. Also the stdout and stderr of the script run on the server is shown.  Default is `yes`.
   
### License - MIT
  Server-script is copyright by Mark Hahn using the MIT license.