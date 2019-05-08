(require 'ts-node').register()
fs = require 'fs'
pathBasename = (require 'path').basename
pathDirname = (require 'path').dirname
colors = require 'colors'

parser = require './parser'
generator = require './generator'
errorStore = require "./error-store"

types = (require './types').T
constants = require './constants'
modules = require './modules'
functions = require './functions'
mainFunction = require './main-function'
{
  searchTypeToRoot
  matchTypes
  generateTypeTable
  generateTypePropertyTable
  generateFunctionPropertyTable
  generateFunctionTable
} = require './tables'


# Dummy function to mark incomplete implementations
TODO = () -> return

# Utilities

missingIRExists = (generatedTypeTable, generatedFunctionTable) ->
  missingIRInTypes = !(Object.keys generatedTypeTable).every (k) ->
    type = generatedTypeTable[k]
    # console.log "in: " + k
    propIRExists = (Object.keys type.generatedPropertyTable).every (pk) ->
      # console.log "  in: " + pk
      prop = type.generatedPropertyTable[pk]
      # console.log prop
      if prop?
        return prop.IR?
      else
        return true
    return propIRExists and type.IR

  missingIRInFunctions = !(Object.keys generatedFunctionTable).every (k) ->
    func = generatedFunctionTable[k]
    # console.log "in: " + k
    propIRExists = (Object.keys func.generatedPropertyTable).every (pk) ->
      # console.log "  in: " + pk
      prop = func.generatedPropertyTable[pk]
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
    generatedTypeTable = generateTypeTable parseTree.declarations, "main"
    generatedFunctionTable = generateFunctionTable parseTree.declarations, "main"

    # Extract properties
    (Object.keys generatedTypeTable).forEach (k) ->
      type = generatedTypeTable[k]
      type.generatedPropertyTable = generateTypePropertyTable type
    (Object.keys generatedFunctionTable).forEach (k) ->
      func = generatedFunctionTable[k]
      func.generatedPropertyTable = generateFunctionPropertyTable func

    # Try to generate IR for everything
    tryCount = 0
    while missingIRExists generatedTypeTable, generatedFunctionTable
      tryCount += 1
      # console.log "Trying to generate missing IR for everything, try count: " + tryCount.toString()

      # Generate IR for types
      (Object.keys generatedTypeTable).forEach (k) ->
        type = generatedTypeTable[k]
        if type.IR? then return

        # Generate IR for type properties
        (Object.keys type.generatedPropertyTable).forEach (pk) ->
          prop = type.generatedPropertyTable[pk]
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
      (Object.keys generatedFunctionTable).forEach (k) ->
        func = generatedFunctionTable[k]
        if func.IR? then return

        # Check if arg and return types exist in type table
        foundArg = searchTypeToRoot generatedTypeTable, func.func.arg.name, func.fullname
        foundRet = searchTypeToRoot generatedTypeTable, func.func.ret.name, func.fullname
        if !foundArg?
          errors.storeSemanticError func.func.arg.name.red + " is not a valid argument type. Found in function " + ((func.fullname.split(".").slice 1).join ".").cyan + " in module " + moduleName.yellow, func.func.arg.token
        if !foundRet?
          errors.storeSemanticError func.func.ret.name.red + " is not a valid return type. Found in function " + ((func.fullname.split(".").slice 1).join ".").cyan + " in module " + moduleName.yellow, func.func.ret.token

        # Check if property types exist in type table
        (Object.keys func.generatedPropertyTable).forEach (pk) ->
          prop = func.generatedPropertyTable[pk]

          prop.found = searchTypeToRoot generatedTypeTable, prop.type.name, func.fullname
          if !prop.found?
            errors.storeSemanticError prop.type.name.red + " is not a proper type. Found in function " + (((func.fullname.split(".").slice 1).join ".") + "." + prop.propertyName).cyan + " in module " + moduleName.yellow, prop.token.token

        # Do not generate IR if the function is malformed
        if !foundRet? or !foundArg?
          func.IR = TODO
          return

        # Generate IR for function body
        func.IR = functions.createFunction m, foundRet.IR.t, foundArg.IR, func.fullname, (f) ->
          # Generate IR for func properties
          (Object.keys func.generatedPropertyTable).forEach (pk) ->
            prop = func.generatedPropertyTable[pk]
            if prop.IR? then return

            # Generate property IR
            if prop.found?
              prop.IR = f.builder.createAlloca(prop.found.IR.t, constants.createConstant(1), prop.propertyName)

              # Generate initial value assignment IR
              if prop.expression?
                initialValue = generateExpressionIR prop.expression, main, f
                # console.log "¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬¬dakdaskldjaslkjdsalkdjlkajdaklsj"
                # console.plog initialValue
                if matchTypes generatedTypeTable, initialValue.type, prop.type.name, func.fullname

                  f.builder.createStore initialValue.IR, prop.IR
                else
                  message = "Type of " + prop.propertyName.yellow + " (" + prop.type.name.red + ")" +
                    " do not match with the assignment (" + (if initialValue? then initialValue.type.red else "?") +
                    "). Found in function " + (((func.fullname.split(".").slice 1).join ".") +
                    "." + prop.propertyName).cyan + " in module " + moduleName.yellow
                  errors.storeSemanticError message, if initialValue? then initialValue.token else null

          # TODO : Generate IR for func expressions

    console.log "\n==================="
    console.log "Type Table"
    console.log ""
    console.plog Object.keys generatedTypeTable
    console.plog generatedTypeTable
    console.log "===================\n"

    console.log "\n==================="
    console.log "Function Table"
    console.log ""
    console.plog Object.keys generatedFunctionTable
    console.plog generatedFunctionTable
    console.log "===================\n"

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
      # generator.logIR ir.m
      console.log "===================\n"

      # Report the result to frontend
      result =
        success: true,
        parseTree: parseTree
        ir: ir
      return result
    else # if parsed file is has ambiguous or incomplete grammar
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

run = (d2module, moduleName, moduleDirectory) ->
  if d2module.parseTree?
    generator.writeBitcodeToFile d2module.ir.m, moduleDirectory + "/" + moduleName + ".bit"
    console.flog (generator.getIR d2module.ir.m), moduleDirectory + "/" + moduleName + ".ir.ll", false
    console.flogJson d2module.parseTree, moduleDirectory + "/" + moduleName + ".ast.txt", false
    console.flogJson d2module.parseTree, moduleDirectory + "/" + moduleName + ".ast.json", true
    console.log "Running d2 module!"

module.exports =
  compile: compile
  uncompile: uncompile
  run: run
