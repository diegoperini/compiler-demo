@{%
const moo = require("moo");

const lexer = moo.compile({
  nl: { match: /[ \t]*\n/, lineBreaks: true },
  ws: { match: /[ \t]+/, lineBreaks: false },
  string: /\"[^\n\r\t]+\"/,
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

function locations(str, substr){
  var a=[],i=-1;
  while((i=str.indexOf(substr,i+1)) >= 0) a.push(i);
  return a;
}

function validString(str) {
  try {
    doubleQuoteLocations = locations(str, "\"");
    backslashLocations = locations(str, "\\");

    // TODO : check if escaped characters are legit
    return true;
  } catch (e) {
    return null
  }
}
%}

@lexer lexer
@builtin "string.ne"

# Main
main -> declaration:* {%
  (d) => { return { declarations: d[0]} }
%}

# White space Helpers
ws -> %ws
ows -> ws:?

# Newline helpers
nl -> ows %nl:+
onl -> ows nl:?

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
declaration -> onl ows declarationBody nl {% (d) => d[2] %}
             # | declarations declarations {% (d) => [d[0], ...d[4]] %}

declarationBody -> typeDeclaration {% id %}

typeDeclaration -> typename onl %openCurly nl typeBody:* onl %closeCurly {% (d) => { return { typename:d[0][0], body:d[4] } } %}
typeBody -> ows typeBodyDeclaration nl {% (d) => d[1] %}
typeBodyDeclaration -> %region ws word {% (d) => { return { region: d[2][0][0] } } %}
                     | %horizontal {% () => { return { layout: "horizontal" } } %}
                     | %vertical {% () => { return { layout: "vertical" } } %}
                     | propertyDeclaration {% (d) => d[0] %}

propertyDeclaration -> name onl %colon onl nativeType propertyAssignment:? {% (d) => { return { propertyName: d[0].value, typename: d[4].typename, assignment: d[5] } } %}
propertyAssignment -> onl %equals onl literal {% (d) => { return { operation: d[1], expression: d[3][0] } } %}

# Literals
literal -> intLiteral
         | stringLiteral
intLiteral -> number {% (d) => { return { nativeType: "Int", literalValue: deepExtractIntValue(d[0]) } } %}
stringLiteral -> %string {% (d, l, reject) => {
  if (true || validString(d[0].value)) {
    // TODO : Maybe return buffer or byte array, dunno
    return { nativeType: "String", literalValue: stripQuotes(deepConcatValues(d)) }
  } else {
    return reject;
  }
} %}
# TODO : implement float literals
# TODO : implement bool literals
# TODO : implement array literals
# TODO : implement unit literal
