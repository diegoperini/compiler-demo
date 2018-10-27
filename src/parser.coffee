util = require './util'
nearley = require 'nearley'
comments = require './comments'
execSync = (require 'child_process').execSync

parse = (str) ->
  # Hot reload grammar
  delete require.cache[require.resolve "./grammar"]
  execSync "npm run buildGrammar"
  grammar = require "./grammar"

  t = (new Date).getTime()

  parser = new nearley.Parser nearley.Grammar.fromCompiled grammar
  str = str.replace comments.lineComment, (m) -> "\n".repeat (m.match(/\n/g) || []).length
  str = str.replace comments.blockComment, (m) -> "\n".repeat (m.match(/\n/g) || []).length
  # console.log "================================================================="
  # console.log str
  # console.log "================================================================="
  parser.feed str

  t = (new Date).getTime() - t
  console.log "Parse Result\n=============="
  console.log "Success! Parse time in ms: " + t.toString()
  console.log "=============="

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
