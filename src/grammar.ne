@{%
const moo = require("moo");

const lexer = moo.compile({
  nl: { match: /[ \t]*\n/, lineBreaks: true },
  ws: { match: /[ \t]+/, lineBreaks: false },
  string: /\"[^\n\r]+\"/,
  number: /[1-9][0-9]*/,
  zero: /0/,
  openCurly: /\{/,
  closeCurly: /\}/,
  openBrace: /\[/,
  closeBrace: /\]/,
  colon: /:/,
  equals: /=/,
  doubleQuote: /"/,
  int8t: /Int8/,
  int16t: /Int16/,
  int32t: /Int32/,
  int32t: /Int364/,
  uint8t: /UInt8/,
  uint16t: /UInt16/,
  uint32t: /UInt32/,
  uint64t: /UInt64/,
  float16t: /Float16/,
  float32t: /Float32/,
  float64t: /Float64/,
  intt: /Int/,
  floatt: /Float/,
  boolt: /Bool/,
  stringt: /String/,
  unitt: /Unit/,
  voidt: /Void/,
  ualpha: /[A-Z_][a-zA-Z0-9_]+/,
  lalpha: /[a-z_][a-zA-Z0-9_]+/,
  alpha: /[a-zA-Z0-9_]+/,
  region: /#region/,
  horizontal: /#horizontal/,
  vertical: /#vertical/,
});

function deepConcatValues(d) {
  if (d && Array.isArray(d)) {
    return d.map((i) => deepConcatValues(i)).join("");
  } else if (d && d.value) {
    return d.value;
  } else if (typeof d === "string") {
    return d;
  } else {
    return "";
  }
}

function deepExtractIntValue(d) {
  if (d && Array.isArray(d)) {
    return deepExtractIntValue(d[0]);
  } else if (d && d.value) {
    return parseInt(d.value);
  } else if (typeof d === "number") {
    return d;
  } else {
    return 0;
  }
}

function stripQuotes(str) {
  if (str[0] === '"') {
    return stripQuotes(str.substr(1));
  } else if (str[0] === '\'') {
    return stripQuotes(str.substr(1));
  } else if (str[str.length - 1] === '"') {
    return stripQuotes(str.substr(0, str.length - 1));
  } else if (str[str.length - 1] === '\'') {
    return stripQuotes(str.substr(0, str.length - 1));
  } else {
    return str;
  }
}
%}

@lexer lexer

# Main
main -> onl declarations onl {%
  (d) => { return { declarations: d[1]} }
%}

# White space Helpers
ws -> %ws
ows -> ws:?

# Newline helpers
nl -> %nl:+
onl -> ws:? | nl:?

# Name helpers
name -> %lalpha
typename -> %ualpha
word -> %alpha | name | typename
number -> %number | %zero

# Native types
nativeType -> nativeType %openBrace number:? %closeBrace {% (d) => { return { typename: d[0].typename.value, array: true, size: d[2] ? parseInt(d[2][0].value) : null } } %}
            | %unitt {% (d) => { return { typename: d[0], array: false } } %}
            | %voidt {% (d) => { return { typename: d[0], array: false } } %}
            | %int8t {% (d) => { return { typename: d[0], array: false } } %}
            | %int16t {% (d) => { return { typename: d[0], array: false } } %}
            | %int32t {% (d) => { return { typename: d[0], array: false } } %}
            | %int32t {% (d) => { return { typename: d[0], array: false } } %}
            | %uint8t {% (d) => { return { typename: d[0], array: false } } %}
            | %uint16t {% (d) => { return { typename: d[0], array: false } } %}
            | %uint32t {% (d) => { return { typename: d[0], array: false } } %}
            | %uint64t {% (d) => { return { typename: d[0], array: false } } %}
            | %float16t {% (d) => { return { typename: d[0], array: false } } %}
            | %float32t {% (d) => { return { typename: d[0], array: false } } %}
            | %float64t {% (d) => { return { typename: d[0], array: false } } %}
            | %intt {% (d) => { return { typename: d[0], array: false } } %}
            | %floatt {% (d) => { return { typename: d[0], array: false } } %}
            | %boolt {% (d) => { return { typename: d[0], array: false } } %}
            | %stringt {% (d) => { return { typename: d[0], array: false } } %}

# Declarations
declarations -> ows declaration nl {% (d) => [d[1]] %}
             | ows declaration nl declarations {% (d) => [d[1], ...d[4]] %}

declaration -> typeDeclaration {% id %}

typeDeclaration -> ows typename onl %openCurly nl typeBody:? %closeCurly {% (d) => { return { typename:d[1], body:d[5] } } %}
typeBody -> ows typeBodyDeclaration nl {% (d) => [d[1]] %}
          | ows typeBodyDeclaration nl typeBody {% (d) => [d[1], ...d[3]] %}
typeBodyDeclaration -> %region ws word {% (d) => { return { region: d[2] } } %}
                     | %horizontal {% () => { return { layout: "horizontal" } } %}
                     | %vertical {% () => { return { layout: "vertical" } } %}
                     | propertyDeclaration

propertyDeclaration -> name onl %colon onl nativeType {% (d) => { return { propertyName: d[0].value, typename: d[4].typename, assignment: null } } %}
                     | name onl %colon onl nativeType onl %equals onl literal {% (d) => { return { propertyName: d[0].value, typename: d[4].typename, assignment: d[8][0] } } %}

# Literals
literal -> intLiteral
         | stringLiteral
intLiteral -> number {% (d) => { return { nativeType: "Int", value: deepExtractIntValue(d[0]) } } %}
stringLiteral -> %string {% (d) => { return { nativeType: "String", value: stripQuotes(deepConcatValues(d)) } } %}
# TODO : implement float literals
# TODO : implement bool literals
# TODO : implement array literals
# TODO : implement unit literal
