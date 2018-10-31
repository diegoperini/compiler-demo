(require 'ts-node').register()
fs = require 'fs'
pathBasename = (require 'path').basename
parser = require './parser'
generator = require './generator'

# Utilities
searchTypeToRoot = (types, searchedTypeName, location) ->
  route = location.split '.'
  route.reverse()

  currentLocation = searchedTypeName
  found = null
  # console.log route
  route.forEach (r) ->
    # console.log "!!!!!!!!!!!!!!!!!!!!!  " + currentLocation
    if types[currentLocation]? and !found?
      found = types[currentLocation]
    else if !found?
      currentLocation = r + "." + currentLocation

  return found

extractTypeProperties = (parseTree) ->
  if !parseTree?
    return []

  switch parseTree.declaration
    when "type"
      return extractTypeProperties parseTree.body
    when "property"
      return [parseTree]
    when "func"
      return []
    else
      if Array.isArray parseTree
        return parseTree.map extractTypeProperties
      else
        return []

extractFunctionProperties = (parseTree) ->
  if !parseTree?
    return []

  switch parseTree.declaration
    when "func"
      return parseTree.body.filter (d) -> d.declaration is 'property'
    else
      return []

flattenPropertyTable = (props) ->
  propertyTable = {}

  add = (t) ->
    if Array.isArray t
      t.forEach add
    else if t.propertyName?
      propertyTable[t.propertyName] = t

  add props

  return propertyTable

extractFunctions = (parseTree, parentName) ->
  # TODO : extract unnamed functions
  switch parseTree.declaration
    when "func"
      if parentName isnt ""
        parseTree.fullname = parentName + "." + parseTree.name
      else
        parseTree.fullname = parseTree.name
      return [parseTree, (extractFunctions parseTree.body, parseTree.fullname)...]
    when "type"
      if parentName isnt ""
        parseTree.fullname = parentName + "." + parseTree.name
      else
        parseTree.fullname = parseTree.name
      parseTree.properties = {}
      return extractFunctions parseTree.body, parseTree.fullname
    else
      if Array.isArray parseTree
        return (parseTree.map (t) -> extractFunctions t, parentName)
      else
        return []

flattenFuncTable = (funcs) ->
  funcTable = {}

  add = (t) ->
    if Array.isArray t
      t.forEach add
    else if t.fullname?
      funcTable[t.fullname] = t

  add funcs

  return funcTable

extractTypes = (parseTree, parentName) ->
  # TODO : extract unnamed types
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
      parseTree.properties = {}
      return [parseTree, (extractTypes parseTree.body, parseTree.fullname)...]
    else
      if Array.isArray parseTree
        return (parseTree.map (t) -> extractTypes t, parentName)
      else
        return []

flattenTypeTable = (types) ->
  typeTable =
    "Int":
      IR: generator.getInt32Type()
      properties: {}
    "UInt":
      IR: generator.getUInt32Type()
      properties: {}
    "Float":
      IR: generator.getFloat32Type()
      properties: {}
    "Int8":
      IR: generator.getInt8Type()
      properties: {}
    "Int16":
      IR: generator.getInt16Type()
      properties: {}
    "Int32":
      IR: generator.getInt32Type()
      properties: {}
    "Int64":
      IR: generator.getInt64Type()
      properties: {}
    "UInt8":
      IR: generator.getUInt8Type()
      properties: {}
    "UInt16":
      IR: generator.getUInt16Type()
      properties: {}
    "UInt32":
      IR: generator.getUInt32Type()
      properties: {}
    "UInt64":
      IR: generator.getUInt64Type()
      properties: {}
    "Float16":
      IR: generator.getFloat16Type()
      properties: {}
    "Float32":
      IR: generator.getFloat32Type()
      properties: {}
    "Float64":
      IR: generator.getFloat64Type()
      properties: {}
    "Bool":
      IR: generator.getBoolType()
      properties: {}
    "String":
      IR: generator.getStringType()
      properties: {}
    "Void":
      IR: generator.getVoidType()
      properties: {}
    "Unit":
      IR: generator.getUnitType()
      properties: {}

  add = (t) ->
    if Array.isArray t
      t.forEach add
    else if t.fullname?
      typeTable[t.fullname] = t

  add types

  return typeTable

missingIRExists = (types, functions) ->
  missingIrInTypes = !(Object.keys types).every (k) ->
    type = types[k]
    # console.log "in: " + k
    propIRExists = (Object.keys type.properties).every (pk) ->
      # console.log "  in: " + pk
      prop = type.properties[pk]
      # console.log prop
      if prop?
        return prop.IR?
      else
        return true
    return propIRExists and type.IR

  missingIrInFunctions = !(Object.keys functions).every (k) ->
    func = functions[k]
    # console.log "in: " + k
    propIRExists = (Object.keys func.properties).every (pk) ->
      # console.log "  in: " + pk
      prop = func.properties[pk]
      # console.log prop
      if prop?
        return prop.IR?
      else
        return true
    return propIRExists and func.IR

  return missingIrInTypes or missingIrInFunctions

# Main IR generation
ast2ir = (moduleName, parseTree) ->
  m = generator.createModule(moduleName)

  # Generate IR for main function
  generator.createMain m, (main) ->
    # Extract types and functions
    types = flattenTypeTable extractTypes parseTree.declarations, "main."
    functions = flattenFuncTable extractFunctions parseTree.declarations, "main"

    # Extract properties
    (Object.keys types).forEach (k) ->
      type = types[k]
      type.properties = flattenPropertyTable extractTypeProperties type
    (Object.keys functions).forEach (k) ->
      func = functions[k]
      func.properties = flattenPropertyTable extractFunctionProperties func

    # Try to generate IR for everything
    tryCount = 0
    while missingIRExists types, functions
      tryCount += 1
      console.log "Trying to generate missing IR for everything, try count: " + tryCount.toString()

      # Generate IR for types
      (Object.keys types).forEach (k) ->
        type = types[k]

        # Generate IR for type properties
        (Object.keys type.properties).forEach (pk) ->
          prop = type.properties[pk]
          # TODO : generate property IR
            # TODO : native type
            # TODO : tuple type
            # TODO : function type
            # TODO : tuple type
            # TODO : array type
          if prop.IR? then return
          prop.IR = "TODO"

        # TODO : generate type IR
        if type.IR? then return
        type.IR = "TODO"

        # type.IR = generator.createType [], type.fullname
        # alloca = main.mainBuilder.createAlloca type.IR.t
        # main.mainBuilder.createStore alloca, generator.createConstant 123

      # Generate IR for functions
      (Object.keys functions).forEach (k) ->
        func = functions[k]

        if func.IR? then return

        foundArg = searchTypeToRoot types, func.func.arg.name, func.fullname
        foundRet = searchTypeToRoot types, func.func.ret.name, func.fullname
        console.plog func
        if !foundRet? or !foundArg?
          console.log func.fullname + " function argument or return type is invalid."
          console.log foundArg
          console.log foundRet
          func.IR = "TODO"
          (Object.keys func.properties).forEach (pk) ->
            prop = func.properties[pk]
            prop.IR = "TODO"
          return

        func.IR = generator.createFunction m, foundRet.IR.t, foundArg.IR, func.fullname, (f) ->
          # Generate IR for func properties
          (Object.keys func.properties).forEach (pk) ->
            prop = func.properties[pk]

            # Gnerate property IR
            if prop.IR? then return

            console.log "Searching... " + prop.type.name + " in " + func.fullname
            found = searchTypeToRoot types, prop.type.name, func.fullname
            if (found)
              console.plog found
              prop.IR = f.builder.createAlloca(found.IR.t, generator.createConstant(2), prop.propertyName)
            else
              console.log func.fullname + "." + prop.propertyName + " function property type is invalid."
              prop.IR = "TODO"

    # console.log "\n==================="
    # console.log "Type Table"
    # console.plog types
    # console.log "===================\n"

    # console.log "\n==================="
    # console.log "Function Table"
    # console.log "==================="
    # console.plog functions
    # console.log "===================\n"

  console.log "\n==================="
  console.log "Bitcode"
  console.log "==================="
  generator.logIR m
  console.log "===================\n"

  return m: m, error: null

compile = (filePath) ->
  try
    parseTree = parser.parse fs.readFileSync filePath, "utf8"

    if parseTree?
      # console.log "\n==================="
      # console.log "AST"
      # console.log "==================="
      # console.plog parseTree
      # console.log "===================\n"

      t = (new Date).getTime()
      ir = ast2ir (pathBasename filePath), parseTree.tree
      t = (new Date).getTime() - t
      console.log "\n==================="
      console.log "ast2ir Result"
      if !ir.error?
        console.log "Success!"
        console.log "Success! IR generation time in ms: " + t.toString()
      else
        console.error "Compile error, " + error
      console.log "===================\n"

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
