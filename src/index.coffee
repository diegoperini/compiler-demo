#!/usr/bin/env coffee
util = require './util'
compiler = require './compiler'
execSync = (require 'child_process').execSync
fs = require 'fs'
resolvePath = require('path').resolve

# Watcher Context
context = {
  watchedFiles: {}
}

# Argument parsing
if process.argv.length is 3
  dirToWatch = resolvePath process.argv.last()

  try
    # Check if given path is a directory, otherwise error
    if (fs.lstatSync dirToWatch).isDirectory()
      # Check for files with matching extension
      check = () ->
        execOpts =
          cwd: dirToWatch
          encoding: "utf8"
        try
          execResult = execSync "find . -type f -name \"*.d2\" | grep .d2", execOpts
          d2Files = execResult.split '\n'
          if d2Files?
            d2Files = d2Files.filter (f) -> f isnt ''
            d2Files = d2Files.map (f) -> resolvePath f
            return d2Files
          else
            return []
        catch error
          return []

      # Compare a given list of files with already watched files
      compare = (newFileList) ->
        oldFileList = Object.keys context.watchedFiles

        result =
          filesToUnwatch: oldFileList.diff newFileList
          filesToWatch: newFileList.diff oldFileList

        return result

      # Compile new files, uncompile deleted files, keep watchers in sync
      recompile = (comparison) ->
        # console.log context

        # Compile a single file with a given path
        compileSingleFile = (f) ->
          console.log "Recompiling " + f
          return compiler.compile f

        # Uncompile a single file with a given path
        uncompileSingleFile = (f) ->
          context.watchedFiles[f].watcher.close()
          console.log "Uncompiling " + f
          compiler.uncompile f
          delete context.watchedFiles[f]

        # Run a d2module
        runModule = (d2module) -> compiler.run d2module

        # Unwatch all old files
        comparison.filesToUnwatch.forEach (f) ->
          console.log f + " - Unwatched"

          if context.watchedFiles[f]?
            uncompileSingleFile f

        # Compile and watch all new files
        comparison.filesToWatch.forEach (f) ->
          console.log f + " - Watched"

          if !context.watchedFiles[f]? and f.isAccessibleFile()
            context.watchedFiles[f] =
              d2module: compileSingleFile f
              watcher: fs.watch f, persistent: true, () ->
                if f.isAccessibleFile()
                  context.watchedFiles[f].d2module = compileSingleFile f
                  runModule context.watchedFiles[f].d2module
                else
                  uncompileSingleFile f
            runModule context.watchedFiles[f].d2module

      # Periodically keep context up to date
      watchEveryting = () -> recompile compare check()
      setInterval watchEveryting, 1000
    else
      console.error "Error: Given path is not a directory!"
      process.exit 1
  catch error
    console.error "Error: Given path format is invalid!"
    process.exit 1
else
  console.error "Error: No path specified to watch!"
  process.exit 1
