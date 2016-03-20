# server-script

*Atom editor package to update files and run a local script on the server on every save*

Write and edit a script on the local machine with Atom and then run the script on a server using an Atom command or run on every save. You will be able to move existing server scripts to local and then run them on any server without putting the script on the server.

Optionally server-script can move the changed files before running the script.

Typically the script would be a build script. Files would be updated and built on every local save.

The scripts are stored in a .server-script folder in the root of the project.  Metadata stored in the script gives the connection information for the server.  By default a .gitignore file in the folder protects the folder from being commited so sensitive information like a password can be stored in the metadata.


