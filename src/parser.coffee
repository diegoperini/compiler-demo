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
    return parser.results
  else
    return null

module.exports =
  parse: parse
