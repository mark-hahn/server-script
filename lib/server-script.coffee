
# server-script.coffee

fs         = require 'fs-plus'
path       = require 'path'
filewalker = require 'filewalker'
parser     = require 'gitignore-parser'
SubAtom    = require 'sub-atom'

module.exports =
  activate: ->
    @subs = new SubAtom
    try
      @gitignore = parser.compile fs.readFileSync ".gitignore", "utf8"
    catch e
      @gitignore = null
    @subs.add atom.commands.add 'atom-workspace', 'server-script:save': => @save()
    @rootDirPath = atom.project.getDirectories()[0].getPath()
    @serverScriptFolder = path.join @rootDirPath, '.server-script'
    
  initSetupFolder: ->
    fs.copySync 'init-setup-folder', @serverScriptFolder
    ignorePath = path.join @serverScriptFolder, '.gitignore'
    fs.writeFileSync ignorePath, 'secrets.cson\n.run-server-script.sh\n'
    atom.notifications.addInfo \
        "A new .server-script folder was created in the root folder. " +
        "Edit .server-script/server-setup.cson to start using server-script.", 
        dismissable: true
    
  save: ->
    if not fs.existsSync @serverScriptFolder then @initSetupFolder(); return
    
  #     
  #   
  #   
  # 
  # save: ->
  # 
  #   atom.workspace.open('line-count.txt').then (editor) =>
  # 
  #     filewalker(rootDirPath, maxPending: 4).on("file", (path, stats, absPath) =>
  #         sfxMatch = /\.([^\.]+)$/.exec path
  #         if sfxMatch and
  #             (sfx = sfxMatch[1]) in suffixes and
  #             path.indexOf('node_modules') is -1 and
  #             path.indexOf('bower_components') is -1 and
  #             (not @gitignore or @gitignore.accepts path)
  # 
  #           code = fs.readFileSync absPath, 'utf8'
  #           code = code.replace /\r/g, ''
  #           try
  #             counts = sloc code, sfx
  #           catch e
  #             add 'Warning: ' + e.message
  #             return
  # 
  #           dirParts = path.split '/'
  #           dir = ''
  #           for dirPart, idx in dirParts
  #             if idx is dirParts.length-1 then break
  #             dir += dirPart
  #             addAttrs dir, dirs, counts
  #             dir += '/'
  #           files[path] = counts
  #           addAttrs sfx, typeData, counts
  #           addAttrs  '', total,    counts
  # 
  #       ).on("error", (err) ->
  #         add err.message
  # 
  #       ).on("done", ->
  #         add '\nLine counts for project ' + rootDirPath + '.'
  #         add 'Generated by the Atom editor package Line-Count on ' +
  #             moment().format 'MMMM D YYYY H:mm.'
  #         add 'Counts are in order of source, comments, and total.'
  # 
  #         printSection 'Files',       files
  #         printSection 'Directories', dirs
  #         printSection 'Types',       typeData
  #         printSection 'Total',       total
  # 
  #         editor.setText text
  # 
  #       ).walk()

  deactivate: ->
    @subs.dispose()

