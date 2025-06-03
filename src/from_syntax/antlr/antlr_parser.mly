%{
open Antlr_types
%}

%token <string> IDENT
%token COLON
%token SEMICOLON
%token EOF

%start <grammar> main
%%

main:
  rules EOF { $1 }

rules:
  | rule rules { $1 :: $2 }
  |           { [] }

rule:
  | IDENT COLON IDENT SEMICOLON { { name = $1; definition = $3 } }
