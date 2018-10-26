(require 'ts-node').register()
fs = require 'fs'
pathBasename = (require 'path').basename
parser = require './parser'
generator = require './generator'

console.log generator

ast2ir = (moduleName, parseTree) ->
  m = generator.createModule(moduleName)

  # TODO : extract types
  # TODO : extract functions

  return m: m, error: null

compile = (filePath) ->
  try
    parseTree = parser.parse fs.readFileSync filePath, 'utf8'

    if parseTree?
      console.plog parseTree
      ir = ast2ir (pathBasename filePath), parseTree

      if !ir.error? then console.log "\nCompiled!" else console.error "Compile error, " + error

      result =
        success: !ir.error?,
        parseTree: parseTree
        ir: ir

      return result
    else
      console.error "Parse error due to incomplete source file!"

      result =
        success: false,
        parseTree: parseTree
      return result
  catch error
    console.error error

    result =
      success: false,
      parseTree: null
    return result

uncompile = (filePath) -> console.log "Uncompiled!"
run = (d2module) -> console.log "Running d2 module!"

module.exports =
  compile: compile
  uncompile: uncompile
  run: run
