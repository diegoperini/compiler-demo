@{%
const moo = require("moo");

const lexer = moo.compile({
  ws: { match: /[ \t\n]+/, lineBreaks: true },
  number: /[0-9]+/,
});
%}

@lexer lexer

main -> %ws numbers %ws {% (d) => d[1] %}

numbers -> %number:+ {% (d) => d[0] %}
        | %number:+ %ws numbers {% (d) => [d[0][0], d[2][0]] %}
