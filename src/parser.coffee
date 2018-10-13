util = require './util'
nearley = require "nearley"
execSync = (require 'child_process').execSync

parse = (str) ->
  # Hot reload grammar
  delete require.cache[require.resolve "./grammar.js"]
  execSync "npm run buildGrammar"
  grammar = require "./grammar.js"

  parser = new nearley.Parser nearley.Grammar.fromCompiled grammar
  parser.feed str

  if parser.results.length > 0
    result =
      tree: parser.results[0]
      ambigious: parser.results.length isnt 1
      parseCount: parser.results.length
    return result
  else
    return null

module.exports =
  parse: parse
