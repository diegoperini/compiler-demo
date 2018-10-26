// Generated automatically by nearley, version 2.15.1
// http://github.com/Hardmath123/nearley
(function () {
function id(x) { return x[0]; }

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
  asterix: /\*/,
  backslash: /\\/,
  slash: /\//,
  plus: /\+/,
  minus: /-/,
  lessThan: /</,
  greaterThan: />/,
  percent: /%/,
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
var grammar = {
    Lexer: lexer,
    ParserRules: [
    {"name": "main$ebnf$1", "symbols": []},
    {"name": "main$ebnf$1", "symbols": ["main$ebnf$1", "declaration"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "main", "symbols": ["onl", "main$ebnf$1"], "postprocess": (d) => { return { declarations: d[1] }; }},
    {"name": "ws", "symbols": [(lexer.has("ws") ? {type: "ws"} : ws)]},
    {"name": "ows$ebnf$1", "symbols": ["ws"], "postprocess": id},
    {"name": "ows$ebnf$1", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "ows", "symbols": ["ows$ebnf$1"]},
    {"name": "nl$ebnf$1", "symbols": ["newLine"]},
    {"name": "nl$ebnf$1", "symbols": ["nl$ebnf$1", "newLine"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "nl", "symbols": ["ows", "nl$ebnf$1"]},
    {"name": "onl$ebnf$1", "symbols": []},
    {"name": "onl$ebnf$1", "symbols": ["onl$ebnf$1", "newLine"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "onl", "symbols": ["ows", "onl$ebnf$1"]},
    {"name": "newLine", "symbols": [(lexer.has("nl") ? {type: "nl"} : nl), "ows"]},
    {"name": "name", "symbols": [(lexer.has("lalpha") ? {type: "lalpha"} : lalpha)], "postprocess": (d) => d[0].value},
    {"name": "typeName", "symbols": [(lexer.has("ualpha") ? {type: "ualpha"} : ualpha)], "postprocess": (d) => d[0].value},
    {"name": "word", "symbols": [(lexer.has("alpha") ? {type: "alpha"} : alpha)], "postprocess": (d) => d[0].value},
    {"name": "word", "symbols": ["name"], "postprocess": id},
    {"name": "word", "symbols": ["typeName"], "postprocess": id},
    {"name": "number", "symbols": [(lexer.has("number") ? {type: "number"} : number)], "postprocess": id},
    {"name": "number", "symbols": [(lexer.has("hex") ? {type: "hex"} : hex)], "postprocess": id},
    {"name": "number", "symbols": [(lexer.has("binary") ? {type: "binary"} : binary)], "postprocess": id},
    {"name": "nativeType$ebnf$1", "symbols": ["arraySpecifier"], "postprocess": id},
    {"name": "nativeType$ebnf$1", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "nativeType", "symbols": ["nonArrayNativeType", "nativeType$ebnf$1"], "postprocess":  (d, l, r) => {
          if (exists(d[1])) {
            if ((d[1] > 0 && Number.isInteger(d[1])) || d[1] === "auto") {
              return { name: d[0].value, tuple: d[0].tuple, func: null, array: true, count: d[1]};
            } else {
              console.error("Illegal array size.");
              return r;
            }
          } else {
            return { name: d[0].value, tuple: d[0].tuple, func: d[0].func, array: false, count: null };
          }
        } },
    {"name": "nonArrayNativeType", "symbols": ["tuple"], "postprocess": id},
    {"name": "nonArrayNativeType", "symbols": ["nonTupleNativeType"], "postprocess": id},
    {"name": "nonArrayNativeType", "symbols": ["functionNativeType"], "postprocess": id},
    {"name": "nonFunctionNativeType", "symbols": ["tuple"], "postprocess": id},
    {"name": "nonFunctionNativeType", "symbols": ["nonTupleNativeType"], "postprocess": id},
    {"name": "functionNativeType", "symbols": ["nonFunctionNativeType", "onl", (lexer.has("minus") ? {type: "minus"} : minus), (lexer.has("greaterThan") ? {type: "greaterThan"} : greaterThan), "onl", "nativeType"], "postprocess":  (d) => {
          let arg = { name: d[0].value, tuple: d[0].tuple, func: null, array: false, count: null }
          let ret = d[5]
          return { func: { arg, ret }, value: null, tuple: null };
        } },
    {"name": "arraySpecifier$ebnf$1", "symbols": ["numberLiteral"], "postprocess": id},
    {"name": "arraySpecifier$ebnf$1", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "arraySpecifier", "symbols": [(lexer.has("openBrace") ? {type: "openBrace"} : openBrace), "onl", "arraySpecifier$ebnf$1", "onl", (lexer.has("closeBrace") ? {type: "closeBrace"} : closeBrace)], "postprocess":  (d) => {
          if (exists(d[2])) {
            return d[2].literalValue;
          } else {
            return "auto";
          }
        } },
    {"name": "nonTupleNativeType", "symbols": [(lexer.has("ualpha") ? {type: "ualpha"} : ualpha)], "postprocess":  (d, l, r) => {
          d[0].tuple = null;
          d[0].func = null;
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
            case "Unit":
              return { tuple: [], func: null, value: null };
            default:
              return d[0];
          }
        } },
    {"name": "tuple$ebnf$1", "symbols": ["tuplePropertyList"], "postprocess": id},
    {"name": "tuple$ebnf$1", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "tuple", "symbols": [(lexer.has("openParan") ? {type: "openParan"} : openParan), "tuple$ebnf$1", "tupleProperty", "onl", (lexer.has("closeParan") ? {type: "closeParan"} : closeParan)], "postprocess": (d) => { return { tuple: [...(exists(d[1]) ? d[1] : []), d[2]], value: null }; }},
    {"name": "tuple", "symbols": [(lexer.has("openParan") ? {type: "openParan"} : openParan), "onl", (lexer.has("closeParan") ? {type: "closeParan"} : closeParan)], "postprocess": () => { return { tuple: [], value: null }; }},
    {"name": "tuplePropertyList$ebnf$1", "symbols": []},
    {"name": "tuplePropertyList$ebnf$1", "symbols": ["tuplePropertyList$ebnf$1", "tuplePropertyList"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "tuplePropertyList", "symbols": ["tupleProperty", "onl", (lexer.has("comma") ? {type: "comma"} : comma), "tuplePropertyList$ebnf$1"], "postprocess": (d) => { return [d[0], ...(exists(d[3]) ? d[3] : [])]; }},
    {"name": "tupleProperty", "symbols": ["onl", "name", "onl", (lexer.has("colon") ? {type: "colon"} : colon), "onl", "nativeType"], "postprocess": (d) => { return { declaration: "property", propertyName: d[1], type: d[5], assignment: null }; }},
    {"name": "declaration", "symbols": ["declarationBody", "nl"], "postprocess": id},
    {"name": "declarationBody", "symbols": ["typeDeclaration"], "postprocess": id},
    {"name": "declarationBody", "symbols": ["functionDeclaration"], "postprocess": id},
    {"name": "declarationBody", "symbols": [(lexer.has("region") ? {type: "region"} : region), "ws", "word"], "postprocess": (d) => { return { region: d[2] }; }},
    {"name": "functionDeclaration$ebnf$1", "symbols": []},
    {"name": "functionDeclaration$ebnf$1", "symbols": ["functionDeclaration$ebnf$1", "functionBody"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "functionDeclaration", "symbols": ["name", "onl", "functionNativeType", "onl", (lexer.has("openCurly") ? {type: "openCurly"} : openCurly), "onl", "functionDeclaration$ebnf$1", (lexer.has("closeCurly") ? {type: "closeCurly"} : closeCurly)], "postprocess": (d) => { return { declaration: "func", func: d[2].func, name:d[0], body:d[6] } }},
    {"name": "functionDeclaration", "symbols": ["name", "onl", "functionNativeType", "onl", (lexer.has("openCurly") ? {type: "openCurly"} : openCurly), "onl", "typeBodyDeclaration", "ows", (lexer.has("closeCurly") ? {type: "closeCurly"} : closeCurly)], "postprocess": (d) => { return { declaration: "func", func: d[2].func, name:d[0], body:[d[6]] } }},
    {"name": "functionDeclaration", "symbols": ["name", "onl", "functionNativeType", "onl", (lexer.has("openCurly") ? {type: "openCurly"} : openCurly), "onl", "functionBodyDeclaration", "ows", (lexer.has("closeCurly") ? {type: "closeCurly"} : closeCurly)], "postprocess": (d) => { return { declaration: "func", func: d[2].func, name:d[0], body:[d[6]] } }},
    {"name": "functionBody", "symbols": ["typeBodyDeclaration", "nl"], "postprocess": id},
    {"name": "functionBody", "symbols": ["functionBodyDeclaration", "nl"], "postprocess": id},
    {"name": "functionBodyDeclaration", "symbols": ["expression"], "postprocess": id},
    {"name": "typeDeclaration$ebnf$1", "symbols": []},
    {"name": "typeDeclaration$ebnf$1", "symbols": ["typeDeclaration$ebnf$1", "typeBody"], "postprocess": function arrpush(d) {return d[0].concat([d[1]]);}},
    {"name": "typeDeclaration", "symbols": ["typeName", "onl", (lexer.has("openCurly") ? {type: "openCurly"} : openCurly), "onl", "typeDeclaration$ebnf$1", (lexer.has("closeCurly") ? {type: "closeCurly"} : closeCurly)], "postprocess": (d) => { return { declaration: "type", name:d[0], body:d[4] } }},
    {"name": "typeDeclaration", "symbols": ["typeName", "onl", (lexer.has("openCurly") ? {type: "openCurly"} : openCurly), "onl", "typeBodyDeclaration", "ows", (lexer.has("closeCurly") ? {type: "closeCurly"} : closeCurly)], "postprocess": (d) => { return { declaration: "type", name:d[0], body:[d[4]] } }},
    {"name": "typeBody", "symbols": ["typeBodyDeclaration", "nl"], "postprocess": id},
    {"name": "typeBodyDeclaration", "symbols": [(lexer.has("horizontal") ? {type: "horizontal"} : horizontal)], "postprocess": () => { return { layout: "horizontal" }; }},
    {"name": "typeBodyDeclaration", "symbols": [(lexer.has("vertical") ? {type: "vertical"} : vertical)], "postprocess": () => { return { layout: "vertical" }; }},
    {"name": "typeBodyDeclaration", "symbols": ["propertyDeclaration"], "postprocess": id},
    {"name": "typeBodyDeclaration", "symbols": ["declarationBody"], "postprocess": id},
    {"name": "propertyDeclaration$ebnf$1", "symbols": ["propertyAssignment"], "postprocess": id},
    {"name": "propertyDeclaration$ebnf$1", "symbols": [], "postprocess": function(d) {return null;}},
    {"name": "propertyDeclaration", "symbols": ["name", "onl", (lexer.has("colon") ? {type: "colon"} : colon), "onl", "nativeType", "propertyDeclaration$ebnf$1"], "postprocess":  (d, l, r) => {
          if (exists(d[5])) {
            return { declaration: "property", propertyName: d[0], type: d[4], assignment: d[5].expression };
          } else {
            return { declaration: "property", propertyName: d[0], type: d[4], assignment: null };
          }
        } },
    {"name": "propertyAssignment", "symbols": ["onl", (lexer.has("equals") ? {type: "equals"} : equals), "onl", "expression"], "postprocess": (d) => { return { operation: d[1].value, expression: d[3] } }},
    {"name": "expression", "symbols": ["literal"], "postprocess": id},
    {"name": "expression", "symbols": ["identifierOrReservedStatement"], "postprocess": id},
    {"name": "expression", "symbols": ["funcCall"], "postprocess": id},
    {"name": "funcCall", "symbols": [(lexer.has("lalpha") ? {type: "lalpha"} : lalpha), "ws", "expression"], "postprocess":  (d, l, r) => {
          if (d[0].value === 'return' ) {
            return "return statement with result";
          } else {
            return "func call";
          }
        } },
    {"name": "identifierOrReservedStatement", "symbols": [(lexer.has("lalpha") ? {type: "lalpha"} : lalpha)], "postprocess":  (d, l, r) => {
          switch (d[0].value) {
            case "return":
              return "return statement without result";
            default:
              return "identifier expression";
          }
        } },
    {"name": "literal", "symbols": ["numberLiteral"], "postprocess": id},
    {"name": "literal", "symbols": ["stringLiteral"], "postprocess": id},
    {"name": "literal", "symbols": ["boolLiteral"], "postprocess": id},
    {"name": "numberLiteral", "symbols": ["number"], "postprocess":  (d, l, r) => {
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
        } },
    {"name": "stringLiteral", "symbols": [(lexer.has("string") ? {type: "string"} : string)], "postprocess": (d) => { return { nativeType: "String", literalValue: JSON.parse(d[0].value) } }},
    {"name": "stringLiteral", "symbols": [(lexer.has("emptyString") ? {type: "emptyString"} : emptyString)], "postprocess": (d) => { return { nativeType: "String", literalValue: "" } }},
    {"name": "boolLiteral", "symbols": [(lexer.has("lalpha") ? {type: "lalpha"} : lalpha)], "postprocess":  (d, l, r) => {
          switch (d[0].value) {
            case "true":
              return { nativeType: "Bool", literalValue: true };
            case "false":
              return { nativeType: "Bool", literalValue: false };
            default:
              return r;
          }
        } }
]
  , ParserStart: "main"
}
if (typeof module !== 'undefined'&& typeof module.exports !== 'undefined') {
   module.exports = grammar;
} else {
   window.grammar = grammar;
}
})();
