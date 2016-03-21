
# server-script.coffee

fs         = require 'fs-plus'
path       = require 'path'
filewalker = require 'filewalker'
gitIgParse = require 'gitignore-parser'
cson       = require 'season'
SubAtom    = require 'sub-atom'
{execSync} = require 'child_process'

module.exports =
  activate: ->
    @subs = new SubAtom
    @subs.add atom.commands.add 'atom-workspace', 'server-script:save': => @save()
    @rootDirPath = atom.project.getDirectories()[0].getPath()
    @serverScriptFolder = path.join @rootDirPath, '.server-script'
    
  initSetupFolder: ->
    fs.copySync 'init-setup-folder', @serverScriptFolder
    fs.writeFileSync ignorePath, 'secrets.cson\n.run-server-script.sh\n'
    atom.notifications.addInfo \
        "A new .server-script folder was created in the root folder. " +
        "Edit .server-script/server-setup.cson to start using server-script.", 
        dismissable: true
        
  loadCsonInitFile: (name) ->
    try
      return cson.readFileSync path.join @serverScriptFolder, name
    catch e
      atom.notifications.addError "Error processing #{name}: " + e.message,
                                   dismissable: true
  doRsync: (cmd) ->
    cmdStr = 'rsync -a ' + cmd
    console.log cmdStr
    try
      return execSync cmdStr, timeout:5e3, encoding:'utf8', maxBuffer:10e6
    catch e
      loc = @setup.server.location
      atom.notifications.addError "Error executing rsync #{cmdStr} on #{loc}: " + e.message,
                                   dismissable: true
  doSSH: (cmd) ->
    cmdStr = 'ssh ' + @server + ' ' + cmd
    console.log cmdStr
    try
      return execSync cmdStr, timeout:5e3, encoding:'utf8', maxBuffer:10e6
    catch e
      loc = @setup.server.location
      atom.notifications.addError "Error executing command #{cmdStr} on #{loc}: " + e.message,
                                   dismissable: true
  save: (action) ->
    if not fs.existsSync @serverScriptFolder then @initSetupFolder(); return
    if not (@setup = @loadCsonInitFile 'server-setup.cson') or
       not (secret = @loadCsonInitFile 'secrets.cson') then return
    pwdStr = (if secret.login.password then ':' + secret.login.password else '')
    usrStr = (if secret.login.user then secret.login.user + pwdStr + '@' else '')
    @server = usrStr + @setup.server.location
    root =  path.normalize @setup.server.projectRoot
    remotePath = @server + ':' + root
    # console.log @server, '\n', @doSSH 'ls -al'
    
    if @setup.options.syncChangedFiles
      gitIgnStr = (if @setup.options.useGitignore \
                   then " --exclude=.git --filter=':- .gitignore' " else ' ')
      @doRsync gitIgnStr + "#{@rootDirPath}/ #{remotePath}/"
      
    scripts = (if action is 'save' then @setup.options.scriptsRunOnSave \
                                   else @setup.options.scriptsRunOnCommand)
    if scripts.length > 0
      for script in scripts
        remoteScript = "#{remotePath}/#{script}"
        @doRsync "#{@serverScriptFolder}/#{script} #{remoteScript}"
        @doSSH "chmod +x #{root}/#{script}"
        @doSSH "#{root}/#{script}"

  deactivate: ->
    @subs.dispose()

