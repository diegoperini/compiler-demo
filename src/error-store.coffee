colors = require 'colors'

createParseError = (reason, exception, token) ->
  error =
    reason: reason
    exception: exception
    token: token
    type: "parse"

  return error

createSemanticError = (reason, exception, token) ->
  error =
    reason: reason
    exception: exception
    token: token
    type: "semantic"

  return error

createErrorStore = () ->
  store =
    errors: []
    sourceFileContents: ""
    sourceFileLineContents: []
    clearStore: () ->
      @errors = []
      @sourceFileContents = ""
      @sourceFileLineContents = []
    storeSourceFileContents: (sourceFileContents) ->
      @sourceFileContents = sourceFileContents
      @sourceFileLineContents = sourceFileContents.split "\n"
    storeParseError: (reason, token, exception) ->
      @errors.push createParseError reason, exception, token
    storeSemanticError: (reason, token, exception) ->
      @errors.push createSemanticError reason, exception, token
    success: () -> @errors.length is 0
    printErrors: () ->
      console.error ""
      intro = "Found " + @errors.length.toString() + " error" + if @errors.length > 1 then "s." else "."
      console.error intro
      console.error "-".repeat intro.length
      @errors.forEach (error) =>
        switch error.type
          when "parse"
            # console.error "Parse Error"
            console.error ""
            console.error error.reason
            console.error ""
            if error.token?
              console.error "Line: " + error.token.line + " - Column: " + error.token.col
              if error.token.line - 3 >= 0
                console.error (error.token.line - 3).toString().gray + "\t" + @sourceFileLineContents[error.token.line - 3].green
              if error.token.line - 2 >= 0
                console.error (error.token.line - 2).toString().gray + "\t" + @sourceFileLineContents[error.token.line - 2].green
              if error.token.line - 1 >= 0
                console.error (error.token.line - 1).toString().gray + "\t" + @sourceFileLineContents[error.token.line - 1].red
                console.error (" ".repeat (error.token.line - 1).toString().length) + "\t" + (" ".repeat error.token.col) + "^"
                if error.token.line >= 0
                  console.error (error.token.line).toString().gray + "\t" + @sourceFileLineContents[error.token.line].green
            console.error "---"
          when "semantic"
            # console.error "Parse Error"
            console.error ""
            console.error error.reason
            console.error ""
            if error.token?
              console.error "Line: " + error.token.line + " - Column: " + error.token.col
              if error.token.line - 3 >= 0
                console.error (error.token.line - 3).toString().gray + "\t" + @sourceFileLineContents[error.token.line - 3].green
              if error.token.line - 2 >= 0
                console.error (error.token.line - 2).toString().gray + "\t" + @sourceFileLineContents[error.token.line - 2].green
              if error.token.line - 1 >= 0
                console.error (error.token.line - 1).toString().gray + "\t" + @sourceFileLineContents[error.token.line - 1].red
                console.error (" ".repeat (error.token.line - 1).toString().length) + "\t" + (" ".repeat error.token.col) + "^"
                if error.token.line >= 0
                  console.error (error.token.line).toString().gray + "\t" + @sourceFileLineContents[error.token.line].green
            console.error "---"
  return store


module.exports =
  createErrorStore: createErrorStore
