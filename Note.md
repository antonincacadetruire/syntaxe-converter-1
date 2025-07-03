## Working's notes

### Options
```antlr4
options {
    tokenVocab = Lexer;
}
```
Can be replaced by the whole file directly in it, however, I need to change both
```antlr4
parser grammar Parser;
// ...
lexer grammar Lexer;
// ...
```
by something like that
```antlr4
grammar MyGrammar;
```
### Keywords

- **fragments** : it's a way to Variablize a definition of a part of a Token to make it clearer / prevent redunduncy  
ex :
```antlr4
INTEGER
    : DIGIT+
    | '0' [Xx] HEX_DIGIT+
    ;

fragment DIGIT: [0-9];
fragment HEX_DIGIT: [0-9A-Fa-f];
```
instead of 
```antlr4
INTEGER
    : [0-9]+
    | '0' [Xx] [0-9A-Fa-f]+
    ;
```
That means I'll have to be carreful when parsing a file to understand this clearly, and to link those rules and fragments together.

### Javascript
In `Tree-sitter`some rules are being written in `javascript`. For simplification purpose, those rules are being stored as strings in the grammar, and will be executed during runtime with `node`. 

