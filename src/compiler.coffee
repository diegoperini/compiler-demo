(require 'ts-node').register()
fs = require 'fs'
pathBasename = (require 'path').basename
parser = require './parser'
generator = require './generator'

# TODO : remove this
console.log generator

extractTypes = (parseTree, parentName) ->
  switch parseTree.declaration
    when "func"
      if parentName isnt ""
        parseTree.fullname = parentName + "." + parseTree.name
      else
        parseTree.fullname = parseTree.name
      return extractTypes parseTree.body, parseTree.fullname
    when "type"
      if parentName isnt ""
        parseTree.fullname = parentName + "." + parseTree.name
      else
        parseTree.fullname = parseTree.name
      return [parseTree, (extractTypes parseTree.body, parseTree.fullname)...]
    else
      if Array.isArray parseTree
        return (parseTree.map (t) -> extractTypes t, parentName)
      else
        return []

flattenTypeTable = (types) ->
  typeTable = []

  add = (t) ->
    if Array.isArray t
      t.forEach add
    else if t.fullname?
      typeTable[t.fullname] = t

  add types

  return typeTable

ast2ir = (moduleName, parseTree) ->
  m = generator.createModule(moduleName)

  generator.createMain m, (main) ->
    types = flattenTypeTable extractTypes parseTree.declarations, ""

    # TODO : check type properties and make sure property types exist

    # TODO : extract functions
    # TODO : extract symbols

    # TODO : generate IR code for types
    (Object.keys types).forEach (k) ->
      type = types[k]

      # TODO : extract properties
        # TODO : native type
        # TODO : tuple type
        # TODO : function type
        # TODO : tuple type
        # TODO : array type
      console.log type
      properties = []

      type.IR = generator.createType properties, type.fullname
      # alloca = main.mainBuilder.createAlloca type.IR.t
      # main.mainBuilder.createStore alloca, generator.createConstant 123

    # TODO : generate IR code for functions

  generator.logIR m

  return m: m, error: null

compile = (filePath) ->
  try
    parseTree = parser.parse fs.readFileSync filePath, 'utf8'

    if parseTree?
      console.plog parseTree
      ir = ast2ir (pathBasename filePath), parseTree.tree

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
