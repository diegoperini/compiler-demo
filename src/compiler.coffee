(require 'ts-node').register()
fs = require 'fs'
pathBasename = (require 'path').basename
colors = require 'colors'

parser = require './parser'
generator = require './generator'
errorStore = require "./error-store"

types = (require './types').T
constants = require './constants'
modules = require './modules'
functions = require './functions'
mainFunction = require './main-function'

# Dummy function to mark incomplete implementations
TODO = () -> return

# Utilities
getNativeTypeTable = () ->
  typeTable =
    "Int":
      IR: types.getInt32Type()
      properties: {}
    "UInt":
      IR: types.getUInt32Type()
      properties: {}
    "Float":
      IR: types.getFloat32Type()
      properties: {}
    "Int8":
      IR: types.getInt8Type()
      properties: {}
    "Int16":
      IR: types.getInt16Type()
      properties: {}
    "Int32":
      IR: types.getInt32Type()
      properties: {}
    "Int64":
      IR: types.getInt64Type()
      properties: {}
    "UInt8":
      IR: types.getUInt8Type()
      properties: {}
    "UInt16":
      IR: types.getUInt16Type()
      properties: {}
    "UInt32":
      IR: types.getUInt32Type()
      properties: {}
    "UInt64":
      IR: types.getUInt64Type()
      properties: {}
    "Float16":
      IR: types.getFloat16Type()
      properties: {}
    "Float32":
      IR: types.getFloat32Type()
      properties: {}
    "Float64":
      IR: types.getFloat64Type()
      properties: {}
    "Bool":
      IR: types.getBoolType()
      properties: {}
    "String":
      IR: types.getStringType()
      properties: {}
    "Void":
      IR: types.getVoidType()
      properties: {}
    "Unit":
      IR: types.getUnitType()
      properties: {}
  return typeTable

searchTypeToRoot = (extractedTypes, searchedTypeName, location) ->
  route = location.split '.'
  route.reverse()

  currentLocation = searchedTypeName
  found = null
  # console.log route
  route.forEach (r) ->
    # console.log "!!!!!!!!!!!!!!!!!!!!!  " + currentLocation
    if extractedTypes[currentLocation]? and !found?
      found = extractedTypes[currentLocation]
    else if !found?
      currentLocation = r + "." + currentLocation

  return found

matchTypes = (extractedTypes, t1, t2, scopeFullname) ->
  integers = [
    "Int"
    "UInt"
    "Int8"
    "Int16"
    "Int32"
    "Int64"
    "UInt8"
    "UInt16"
    "UInt32"
    "UInt64"
  ]
  floats = [
    "Float"
    "Float16"
    "Float32"
    "Float64"
  ]

  if t1 in integers and t2 in integers
    return true
  else if t1 in floats and t2 in floats
    return true
  else
    f1 = searchTypeToRoot extractedTypes, t1, scopeFullname
    f2 = searchTypeToRoot extractedTypes, t2, scopeFullname
    # console.log "¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬``"
    # console.plog f1
    # console.plog f1
    # console.log "¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬``"
    return f1? and f2? and f1 is f2

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
  # TODO : extract unnamed types from properties (i.e tuples, functions, arrays)
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

flattenTypeTable = (ts) ->
  typeTable = getNativeTypeTable()

  add = (t) ->
    if Array.isArray t
      t.forEach add
    else if t.fullname?
      typeTable[t.fullname] = t

  add ts

  return typeTable

missingIRExists = (extractedTypes, extractedFunctions) ->
  missingIRInTypes = !(Object.keys extractedTypes).every (k) ->
    type = extractedTypes[k]
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

  missingIRInFunctions = !(Object.keys extractedFunctions).every (k) ->
    func = extractedFunctions[k]
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

  return missingIRInTypes or missingIRInFunctions

# Complex generators
generateLiteralIR = (literal, main, scope) ->
  switch literal.nativeType
    when "Int"
      return constants.createConstant literal.literalValue, 32, true
    when "UInt"
      return constants.createConstant literal.literalValue, 32, false
    when "Float"
      return constants.createConstantFloat literal.literalValue
    when "Int8"
      return constants.createConstant literal.literalValue, 8, true
    when "Int16"
      return constants.createConstant literal.literalValue, 16, true
    when "Int32"
      return constants.createConstant literal.literalValue, 32, true
    when "Int64"
      return constants.createConstant literal.literalValue, 64, true
    when "UInt8"
      return constants.createConstant literal.literalValue, 8, false
    when "UInt16"
      return constants.createConstant literal.literalValue, 16, false
    when "UInt32"
      return constants.createConstant literal.literalValue, 32, false
    when "UInt64"
      return constants.createConstant literal.literalValue, 64, false
    when "Float16"
      return constants.createConstantFloat literal.literalValue
    when "Float32"
      return constants.createConstantFloat literal.literalValue
    when "Float64"
      return constants.createConstantFloat literal.literalValue
    when "Bool"
      if literal.literalValue
        return constants.createConstant 1, 8, false
      else
        return constants.createConstant 0, 8, false
    when "String"
      console.log "??????????????????"
      return scope.builder.createGlobalStringPtr literal.literalValue
    # when "Void"
    when "Unit"
      return mainBuilder.createLoad main.unitAlloca

generateExpressionIR = (expression, main, scope) ->
  switch expression.expression
    when "literal"
      result =
        type: expression.literalExpression.nativeType
        token: expression.token
        IR: generateLiteralIR expression.literalExpression, main, scope
      return result

# Main IR generation
ast2ir = (moduleName, parseTree, errors) ->
  m = modules.createModule(moduleName)

  # Generate IR for main function
  mainFunction.createMain m, (main) ->
    # Extract types and functions
    extractedTypes = flattenTypeTable extractTypes parseTree.declarations, "main."
    extractedFunctions = flattenFuncTable extractFunctions parseTree.declarations, "main"

    # Extract properties
    (Object.keys extractedTypes).forEach (k) ->
      type = extractedTypes[k]
      type.properties = flattenPropertyTable extractTypeProperties type
    (Object.keys extractedFunctions).forEach (k) ->
      func = extractedFunctions[k]
      func.properties = flattenPropertyTable extractFunctionProperties func

    # Try to generate IR for everything
    tryCount = 0
    while missingIRExists extractedTypes, extractedFunctions
      tryCount += 1
      # console.log "Trying to generate missing IR for everything, try count: " + tryCount.toString()

      # Generate IR for types
      (Object.keys extractedTypes).forEach (k) ->
        type = extractedTypes[k]
        if type.IR? then return

        # Generate IR for type properties
        (Object.keys type.properties).forEach (pk) ->
          prop = type.properties[pk]
          if prop.IR? then return

          # TODO : generate property IR
            # TODO : native type
            # TODO : tuple type
            # TODO : function type
            # TODO : tuple type
            # TODO : array type
          prop.IR = TODO

        # TODO : generate type IR
        type.IR = TODO

        # type.IR = types.createType [], type.fullname
        # alloca = main.mainBuilder.createAlloca type.IR.t
        # main.mainBuilder.createStore alloca, constants.createConstant 123

      # Generate IR for functions
      (Object.keys extractedFunctions).forEach (k) ->
        func = extractedFunctions[k]
        if func.IR? then return

        # Check if arg and return types exist in type table
        foundArg = searchTypeToRoot extractedTypes, func.func.arg.name, func.fullname
        foundRet = searchTypeToRoot extractedTypes, func.func.ret.name, func.fullname
        if !foundArg?
          errors.storeSemanticError func.func.arg.name.red + " is not a valid argument type. Found in function " + ((func.fullname.split(".").slice 1).join ".").cyan + " in module " + moduleName.yellow, func.func.arg.token
        if !foundRet?
          errors.storeSemanticError func.func.ret.name.red + " is not a valid return type. Found in function " + ((func.fullname.split(".").slice 1).join ".").cyan + " in module " + moduleName.yellow, func.func.ret.token

        # Check if property types exist in type table
        (Object.keys func.properties).forEach (pk) ->
          prop = func.properties[pk]

          prop.found = searchTypeToRoot extractedTypes, prop.type.name, func.fullname
          if !prop.found?
            errors.storeSemanticError prop.type.name.red + " is not a proper type. Found in function " + (((func.fullname.split(".").slice 1).join ".") + "." + prop.propertyName).cyan + " in module " + moduleName.yellow, prop.token.token

        # Do not generate IR if the function is malformed
        if !foundRet? or !foundArg?
          func.IR = TODO
          return

        # Generate IR for function body
        func.IR = functions.createFunction m, foundRet.IR.t, foundArg.IR, func.fullname, (f) ->
          # Generate IR for func properties
          (Object.keys func.properties).forEach (pk) ->
            prop = func.properties[pk]
            if prop.IR? then return

            # Generate property IR
            if prop.found?
              prop.IR = f.builder.createAlloca(prop.found.IR.t, constants.createConstant(1), prop.propertyName)

              # Generate initial value assignment IR
              if prop.expression?
                initialValue = generateExpressionIR prop.expression, main, f
                # console.log "¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬dakdaskldjaslkjdsalkdjlkajdaklsj"
                # console.plog initialValue
                if matchTypes extractedTypes, initialValue.type, prop.type.name, func.fullname

                  f.builder.createStore initialValue.IR, prop.IR
                else
                  message = "Type of " + prop.propertyName.yellow + " (" + prop.type.name.red + ")" +
                    " do not match with the assignment (" + (if initialValue? then initialValue.type.red else "?") +
                    "). Found in function " + (((func.fullname.split(".").slice 1).join ".") +
                    "." + prop.propertyName).cyan + " in module " + moduleName.yellow
                  errors.storeSemanticError message, if initialValue? then initialValue.token else null

          # TODO : Generate IR for func expressions

  # console.log "\n==================="
  # console.log "Type Table"
  # console.log ""
  # console.plog extractedTypes
  # console.log "===================\n"

  # console.log "\n==================="
  # console.log "Function Table"
  # console.log ""
  # console.plog functions
  # console.log "===================\n"
  generator.writeBitcodeToFile(m, "./lol.bit")

  return m: m

# Interface
compile = (filePath) ->
  # Initialize
  errors = errorStore.createErrorStore()
  parseAttempted = false

  try
    # Try parsing
    sourceFileContents = fs.readFileSync filePath, "utf8"
    errors.storeSourceFileContents sourceFileContents
    parseTree = parser.parse sourceFileContents
    parseAttempted = true

    # if parsed
    if parseTree?
      console.log "\n==================="
      console.log "AST"
      console.log ""
      console.plog parseTree
      console.log "===================\n"

      # Try generating IR
      t = (new Date).getTime()
      ir = ast2ir (pathBasename filePath), parseTree.tree, errors
      t = (new Date).getTime() - t
      console.log "\n==================="
      console.log "ast2ir Result"

      # if IR is generated
      if errors.success()
        console.log "Success!"
        console.log "Compiled in " + t.toString() + " miliseconds."
      else
        errors.printErrors()
      console.log "===================\n"

      console.log "\n==================="
      console.log "IR"
      console.log ""
      generator.logIR ir.m
      console.log "===================\n"

      # Report the result to frontend
      result =
        success: true,
        parseTree: parseTree
        ir: ir
      return result
    else # if parsed file is has ambigious or incomplete grammar
      errors.storeParseError ("Incomplete module file " + (pathBasename filePath))
      errors.printErrors()

      # Report the result to frontend
      result =
        success: false,
        parseTree: parseTree
      return result
  catch error
    # if there is a syntax or punctation error in the source file
    if error.message.indexOf "invalid syntax at line" > -1
      errors.storeParseError ("Invalid character in module " + (pathBasename filePath)), error.token, error
      errors.printErrors()

    console.error error

    # report the result to frontend
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
