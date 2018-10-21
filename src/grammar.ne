@{%
const moo = require("moo");

const lexer = moo.compile({
  nl: { match: /\n/, lineBreaks: true },
  ws: { match: /[ \t]+/, lineBreaks: false },
  string: /\"[^\n\r\t]+\"/,
  emptyString: /\"\"/,
  number: /-?(?:[0-9]|[1-9][0-9]+)(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?\b/,
  zero: /0/,
  openCurly: /\{/,
  closeCurly: /\}/,
  openBrace: /\[/,
  closeBrace: /\]/,
  openParan: /\(/,
  closeParan: /\)/,
  colon: /:/,
  comma: /,/,
  equals: /=/,
  doubleQuote: /"/,
  ualpha: /[A-Z_][a-zA-Z0-9_]*/,
  lalpha: /[a-z_][a-zA-Z0-9_]*/,
  alpha: /[a-zA-Z0-9_]+/,
  region: /#region/,
  horizontal: /#horizontal/,
  vertical: /#vertical/,
});

function deepExtractNumberValue(d) {
  if (d && Array.isArray(d)) {
    return deepExtractNumberValue(d[0]);
  } else if (d && d.value) {
    return parseFloat(d.value);
  } else if (typeof d === "number") {
    return d;
  } else {
    return 0;
  }
}

function locations(str, substr){
  var a=[],i=-1;
  while((i=str.indexOf(substr,i+1)) >= 0) a.push(i);
  return a;
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
nl -> ows newLine:+
onl -> ows newLine:*
newLine -> %nl ows

# Name helpers
name -> %lalpha {% (d) => d[0].value %}
typeName -> %ualpha {% (d) => d[0].value %}
word -> %alpha {% (d) => d[0].value %} | name | typeName
number -> %number | %zero

# Native types
nativeType -> nonArrayNativeType arraySpecifier:? {% (d, l, r) => {
              if (d[1] !== null && d[1] !== undefined ) {
                if ((d[1] > 0 && Number.isInteger(d[1])) || d[1] === "auto") {
                  return { name: d[0].value, tuple: d[0].tuple, array: true, size: null};
                } else {
                  console.error("Illegal array size.");
                  return r;
                }
              } else {
                return { name: d[0].value, tuple: d[0].tuple, array: false };
              }
            } %}
nonArrayNativeType -> tuple {% id %} | nonTupleNativeType {% id %}
arraySpecifier -> %openBrace onl %number:? onl %closeBrace {% (d) => {
  if (d[2] !== null && d[2] !== undefined) {
    return parseFloat(d[2].value)
  } else {
    return "auto";
  }
} %}

nonTupleNativeType -> %ualpha {% (d, l, r) => {
  d[0].tuple = null;
  switch (d[0].value) {
    case "Int":
      d[0].value = "Int32";
      return d[0];
    case "UInt":
      d[0].value = "UInt32";
      return d[0];
    case "Float":
      d[0].value = "Float32";
      return d[0];
    case "Int8":
    case "Int16":
    case "Int32":
    case "Int364":
    case "UInt8":
    case "UInt16":
    case "UInt32":
    case "UInt64":
    case "Float16":
    case "Float32":
    case "Float64":
    case "Bool":
    case "String":
    case "Void":
      return d[0];
    default:
      return r;
  }
} %}

tuple -> %openParan tuplePropertyList:? tupleProperty onl %closeParan {% (d, l , r) => {
  return { tuple: [...d[1], d[2]], value: null };
} %}
tuplePropertyList -> tupleProperty onl %comma tuplePropertyList:* {% (d, l, r) => {
  return [d[0], ...d[3]];
} %}
tupleProperty -> onl name onl %colon onl nativeType {% (d, l, r) => {
  return { declaration: "property", propertyName: d[1], type: d[5], assignment: null };
} %}

# Declarations
declaration -> declarationBody nl {% (d) => d[0] %}

declarationBody -> typeDeclaration {% id %}

typeDeclaration -> typeName onl %openCurly nl typeBody:* %closeCurly {% (d) => { return { declaration: "type", name:d[0], body:d[4] } } %}
typeBody -> typeBodyDeclaration nl {% (d) => d[0] %}
typeBodyDeclaration -> %region ws word {% (d) => { return { region: d[2][0][0] } } %}
                     | %horizontal {% () => { return { layout: "horizontal" } } %}
                     | %vertical {% () => { return { layout: "vertical" } } %}
                     | propertyDeclaration {% (d) => d[0] %}
                     | declarationBody {% id %}

propertyDeclaration -> name onl %colon onl nativeType propertyAssignment:? {% (d, l, r) => {
  if (d[5]) {
    if (d[4].name.indexOf(d[5].expression.nativeType) != -1 && d[4].size === undefined) {
      return { declaration: "property", propertyName: d[0], type: d[4], assignment: d[5].expression };
    } else {
      // Assignment literal type do not match with propery type
      console.error("Assignment literal type does not match with propery type: " + d[5].expression.nativeType + " != " + d[4].name);
      return r;
    }
  } else {
    return { declaration: "property", propertyName: d[0], type: d[4], assignment: null };
  }
} %}
propertyAssignment -> onl %equals onl literal {% (d) => { return { operation: d[1].value, expression: d[3][0] } } %}

# Literals
literal -> numberLiteral
         | stringLiteral
         | boolLiteral

numberLiteral -> %number {% (d, l, r) => {
  var value = deepExtractNumberValue(d[0])
  var dotExists = d[0].value.indexOf(".") !== -1;

  function isFloat(n){
    return Number(n) === n && n % 1 !== 0;
  }

  if (Number.isInteger(value) && !dotExists) {
    return { nativeType: "Int", literalValue: value };
  } else if ((isFloat(value) || Number.isInteger(value)) && dotExists) {
    return { nativeType: "Float", literalValue: value };
  } else {
    console.error("Literal is not Number: " + value)
    return r;
  }
} %}

# Copied and extended from https://github.com/kach/nearley/blob/master/examples/json.ne
stringLiteral -> %string {% (d) => { return { nativeType: "String", literalValue: JSON.parse(d[0].value) } } %}
               | %emptyString {% (d) => { return { nativeType: "String", literalValue: "" } } %}

boolLiteral -> %lalpha {% (d, l, r) => {
  switch (d[0].value) {
    case "true":
      return { nativeType: "Bool", literalValue: true };
    case "false":
      return { nativeType: "Bool", literalValue: false };
    default:
      return r;
  }
} %}
