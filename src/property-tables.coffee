(require 'ts-node').register()

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

generateTypePropertyTable = (parseTree) ->
  flattenPropertyTable extractTypeProperties parseTree

generateFunctionPropertyTable = (parseTree) ->
  flattenPropertyTable extractFunctionProperties parseTree

module.exports =
  generateTypePropertyTable: generateTypePropertyTable
  generateFunctionPropertyTable: generateFunctionPropertyTable
