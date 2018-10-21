@{%
const moo = require("moo");

const lexer = moo.compile({
  nl: { match: /\n/, lineBreaks: true },
  ws: { match: /[ \t]+/, lineBreaks: false },
  string: /\"[^\n\r\t]+\"/,
  emptyString: /\"\"/,
  number: /-?(?:[0-9]|[1-9][0-9]+)(?:\.[0-9]+)?(?:[eE][-+]?[0-9]+)?\b/,
  hex: /0[xX][0-9a-fA-F]+/,
  binary: /0[bB][01]*/,
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
  if (exists(d) && Array.isArray(d)) {
    return deepExtractNumberValue(d[0]);
  } else if (exists(d) && d.value) {
    return parseFloat(d.value);
  } else if (typeof d === "number") {
    return d;
  } else {
    return 0;
  }
}

function deepExtractString(d) {
  if (exists(d) && Array.isArray(d)) {
    return deepExtractString(d[0]);
  } else if (exists(d) && exists(d.value)) {
    return deepExtractString(d.value);
  } else if (typeof d === "string") {
    return d;
  } else {
    return null;
  }
}

function exists(o) {
  return o !== undefined && o !== null;
}

function notNull(o) {
  return o !== null;
}
%}

@lexer lexer

# Main
main -> onl declaration:* {% (d) => { return { declarations: d[1] }; } %}

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
word -> %alpha {% (d) => d[0].value %} | name {% id %} | typeName {% id %}
number -> %number {% id %} | %hex {% id %} | %binary {% id %}

# Native types
nativeType -> nonArrayNativeType arraySpecifier:? {% (d, l, r) => {
  if (exists(d[1])) {
    if ((d[1] > 0 && Number.isInteger(d[1])) || d[1] === "auto") {
      return { name: d[0].value, tuple: d[0].tuple, array: true, count: d[1]};
    } else {
      console.error("Illegal array size.");
      return r;
    }
  } else {
    return { name: d[0].value, tuple: d[0].tuple, array: false, count: null };
  }
} %}
nonArrayNativeType -> tuple {% id %} | nonTupleNativeType {% id %}
arraySpecifier -> %openBrace onl numberLiteral:? onl %closeBrace {% (d) => {
  if (exists(d[2])) {
    return d[2].literalValue;
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

tuple -> %openParan tuplePropertyList:? tupleProperty onl %closeParan {% (d) => { return { tuple: [...d[1], d[2]], value: null }; } %}
       | %openParan onl %closeParan {% () => { return { tuple: [], value: null }; } %}
tuplePropertyList -> tupleProperty onl %comma tuplePropertyList:* {% (d) => { return [d[0], ...d[3]]; } %}
tupleProperty -> onl name onl %colon onl nativeType {% (d) => { return { declaration: "property", propertyName: d[1], type: d[5], assignment: null }; } %}

# Declarations
declaration -> declarationBody nl {% id %}

declarationBody -> typeDeclaration {% id %}
                 | %region ws word {% (d) => { return { region: d[2] }; } %}

typeDeclaration -> typeName onl %openCurly nl typeBody:* %closeCurly {% (d) => { return { declaration: "type", name:d[0], body:d[4] } } %}
typeBody -> typeBodyDeclaration nl {% id %}
typeBodyDeclaration -> %horizontal {% () => { return { layout: "horizontal" }; } %}
                     | %vertical {% () => { return { layout: "vertical" }; } %}
                     | propertyDeclaration {% id %}
                     | declarationBody {% id %}

propertyDeclaration -> name onl %colon onl nativeType propertyAssignment:? {% (d, l, r) => {
  if (exists(d[5])) {
    return { declaration: "property", propertyName: d[0], type: d[4], assignment: d[5].expression };
  } else {
    return { declaration: "property", propertyName: d[0], type: d[4], assignment: null };
  }
} %}
propertyAssignment -> onl %equals onl expression {% (d) => { return { operation: d[1].value, expression: d[3] } } %}

# Expression
expression -> literal {% id %}

# Literals
literal -> numberLiteral {% id %}
         | stringLiteral {% id %}
         | boolLiteral {% id %}

numberLiteral -> number {% (d, l, r) => {
  function binaryToInt(v) {
    let b = parseInt(v.slice(2), 2);
    return b;
  }

  function hexToInt(v) {
    let b = parseInt(v.slice(2), 16);
    return b;
  }

  function isFloat(n){
    return Number(n) === n && n % 1 !== 0;
  }

  let lowercase = deepExtractString(d[0]).toLowerCase();

  if (exists(lowercase) && lowercase.indexOf("0b") != -1) {
    d[0] = binaryToInt(lowercase);
  } else if (exists(lowercase) && lowercase.indexOf("0x") != -1) {
    d[0] = hexToInt(lowercase);
  }

  let value = deepExtractNumberValue(d[0]);
  let dotExists = lowercase.indexOf(".") !== -1;

  if (Number.isInteger(value) && !dotExists) {
    return { nativeType: "Int", literalValue: value };
  } else if ((isFloat(value) || Number.isInteger(value)) && dotExists) {
    return { nativeType: "Float", literalValue: value };
  } else {
    console.error("Literal is not a number: " + value);
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
