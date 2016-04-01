
# server-script.coffee

fs         = require 'fs-plus'
path       = require 'path'
filewalker = require 'filewalker'
gitIgParse = require 'gitignore-parser'
cson       = require 'season'
SubAtom    = require 'sub-atom'
{exec, spawn} = require 'child_process'

module.exports =
  activate: ->
    @subs = new SubAtom
    @subs.add atom.commands.add 'atom-workspace', 'server-script:run': => @run 'run'
    atom.workspace.observeTextEditors (editor) =>
      @subs.add editor.onDidSave => @run 'save'
    
  initSetupFolder: ->
    fs.copySync (path.join __dirname, '../init-setup-folder'), @serverScriptFolder
    ignorePath = @serverScriptFolder + '/.ignore'
    fs.writeFileSync ignorePath, 'secrets.cson\n'
    atom.notifications.addInfo \
        "The folder .server-script was created in the root folder. " +
        "Edit .server-script/setup.cson to start using server-script.", 
        dismissable: true
        
  loadCsonInitFile: (name) ->
    try
      return cson.readFileSync path.join @serverScriptFolder, name
    catch e
      atom.notifications.addError "Error processing #{name}: " + e.message,
                                   dismissable: true
  doExec: (cmd, cb) ->
    if @setup.options.logToConsole
      console.log 'server-script:', cmd
    exec cmd, {timeout:5e3, encoding:'utf8', maxBuffer:10e6}
    , (err, stdout, stderr) =>
      if (err or stderr)
        loc = @setup.server.location
        msg = (if err then err.message else stderr)
        atom.notifications.addError \
          "Error executing server-script command: " + msg,
           dismissable: true
      if @setup.options.logToConsole and stdout
        console.log 'server-script, cmd:', cmd, '\nstdout:', stdout
      cb()
      
  run: (action) ->
    @rootDirPath = atom.project.getDirectories()[0].getPath()
    @serverScriptFolder = path.join @rootDirPath, '.server-script'
    if not fs.existsSync @serverScriptFolder 
      if action is 'run' then @initSetupFolder()
      return
    if not (@setup = @loadCsonInitFile 'setup.cson') or
       not (secret = @loadCsonInitFile 'secrets.cson') then return
    if action is 'run' and 
       not @setup.options.syncChangedFiles and
       not @setup.options.scriptOnRun
      atom.notifications.addInfo \
          "Server-script has nothing to run. " +
          "Edit .server-script/setup.cson to start using server-script.", 
           dismissable: true
      return 
    pwdStr = (if secret.login.password then ':' + secret.login.password else '')
    usrStr = (if secret.login.user then secret.login.user + pwdStr + '@' else '')
    @server = usrStr + @setup.server.location
    root =  path.normalize @setup.server.projectRoot
    if root[-1..-1] is '/' then root = root[0..-2]
    remotePath = @server + ':' + root
    
    doScript = =>
      script = (if action is 'save' then @setup.options.scriptOnSave \
                                    else @setup.options.scriptOnRun)
      if script
        remoteScript = "#{remotePath}/#{script}"
        @doExec "rsync -a #{@serverScriptFolder}/#{script} #{remoteScript}", =>
          @doExec "ssh #{@server} chmod +x #{root}/#{script}", =>
            if @setup.options.logToConsole
              console.log 'server-script: starting', remoteScript
            child = spawn 'ssh', [@server, "#{root}/#{script}"]
            if @setup.options.logToConsole
              child.stdout.on 'data', (data) ->
                console.log 'server-script, stdout:', data.toString()
              child.stderr.on 'data', (data) ->
                console.log 'server-script, stderr:', data.toString()
            child.on 'error', (err) ->
              atom.notifications.addError \
                "Error executing script #{remoteScript}: " + err.message,
                 dismissable: true
            child.on 'close', (code) =>
              if code isnt 0
                atom.notifications.addWarning \
                  "#{remoteScript} returned code: " + code, dismissable: true
              if @setup.options.logToConsole
                console.log 'server-script: script', remoteScript, 'exited with code:', code
    if @setup.options.syncChangedFiles
      gitIgnoreStr = (if @setup.options.useGitignore  \
                       then "--exclude=.git --filter=':- .gitignore' " 
                       else '')
      @doExec "rsync -a #{gitIgnoreStr}#{@rootDirPath}/ #{remotePath}/", doScript
    else doScript()
        
  deactivate: ->
    @subs.dispose()

