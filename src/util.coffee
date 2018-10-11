fs = require 'fs'

Array::last = () -> @[@length - 1]
Array::diff = (a) -> @filter (i) -> (a.indexOf i) < 0

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
  console.log JSON.stringify l, null, 4
