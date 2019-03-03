(require 'ts-node').register()

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
      parseTree.generatedPropertyTable = {}
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

generateFunctionTable = (parseTree, parentName) ->
  flattenFuncTable extractFunctions parseTree, parentName

module.exports =
  generateFunctionTable: generateFunctionTable
