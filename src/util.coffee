fs = require 'fs'
util = require 'util'

Array::last = () -> @[@length - 1]
Array::diff = (a) -> @filter (i) -> (a.indexOf i) < 0
Array::flatMap = (f) -> @.reduce ((acc, cur) -> [acc..., f(cur)]), []

String::isAccessibleFile = () ->
  accessible = true
  isFile = true
  try
    fs.accessSync @toString(), fs.constants.R_OK
    isFile = (fs.lstatSync @toString()).isFile()
  catch error
    accessible = false

  return accessible and isFile

console.plog = (l) ->
  opt =
    showHidden: false
    depth: null
    colors: true
    compact: false
  obj = util.inspect l, opt
  console.log obj
