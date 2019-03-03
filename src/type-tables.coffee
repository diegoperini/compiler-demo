(require 'ts-node').register()

types = (require './types').T

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
      parseTree.generatedPropertyTable = {}
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

generateTypeTable = (parseTree, parentName) ->
  flattenTypeTable extractTypes parseTree, parentName

module.exports =
  searchTypeToRoot: searchTypeToRoot
  matchTypes: matchTypes
  generateTypeTable: generateTypeTable
