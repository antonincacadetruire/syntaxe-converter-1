%{
  open Tree_sitter_types

  exception SyntaxError of string

  let mk_grammar ~name ~rules ~extras ~conflicts ~inline ~externals ~precedences ~word ~supertypes ~scope ~file_types ~injection_regex ~comments ~auto_alias =
    {
      name;
      rules;
      tokens = [];
      extras;
      conflicts;
      inline;
      externals;
      precedences;
      word;
      supertypes;
      scope;
      file_types;
      injection_regex;
      comments;
      auto_alias;
    }
%}

%token <string> IDENT
%token <string> STRING
%token <int> NUMBER
%token <string> REGEX
%token TRUE FALSE NULL
%token COLON SEMICOLON EQUALS ELLIPSIS DOLLAR
%token LPAREN RPAREN LBRACE RBRACE COMMA LBRACKET RBRACKET
%token MODULE EXPORTS GRAMMAR UNDERSCORE
%token DOT FUNCTION CONST LET VAR ARROW
%token EOF

%start <(js_statement list * grammar)> main
%%

main:
  | preamble=js_statements grammar_export EOF { (preamble, $2) }
  | error { raise (SyntaxError "Unexpected token in main rule") }

js_statements:
  | /* empty */ { [] }
  | js_statement js_statements { $1 :: $2 }

js_statement:
  | CONST IDENT EQUALS js_value SEMICOLON { ConstDecl($2, $4) }
  | LET IDENT EQUALS js_value SEMICOLON { LetDecl($2, $4) }
  | VAR IDENT EQUALS js_value SEMICOLON { VarDecl($2, $4) }

grammar_export:
  | MODULE DOT EXPORTS EQUALS GRAMMAR LPAREN grammar_object RPAREN { $7 }
  | error { raise (SyntaxError "Unexpected token in grammar export") }

grammar_object:
  | LBRACE updaters=grammar_fields RBRACE {
    
      List.fold_left (fun g f -> f g)
        (mk_grammar ~name:"" ~rules:[] ~extras:None ~conflicts:None ~inline:None ~externals:None ~precedences:None ~word:None ~supertypes:None ~scope:None ~file_types:None ~injection_regex:None ~comments:None ~auto_alias:None)
        updaters
    }
  | error { raise (SyntaxError "Unexpected token in grammar object") }

rule_ref:
  | DOLLAR DOT IDENT { Identifier $3 }
  | DOLLAR DOT TRUE { Identifier "true" }
  | DOLLAR DOT FALSE { Identifier "false" }

regex:
  | REGEX { Regex $1 }

array_elements:
  | /* empty */ { [] }
  | rule_ref { [$1] }
  | regex { [$1] }
  | rule_ref COMMA array_elements { $1 :: $3 }
  | regex COMMA array_elements { $1 :: $3 }

grammar_fields:
  | /* empty */ { [] }
  | f=grammar_field rest=grammar_fields_tail { f :: rest }

grammar_fields_tail:
  | COMMA f=grammar_field rest=grammar_fields_tail { f :: rest }
  | { [] }

grammar_field:
  | IDENT COLON js_value {
      fun g -> match $1, $3 with
        | "name", String s -> { g with name = s }
        | "rules", Object rules -> { g with rules = Tree_sitter_types.parse_rules rules }
        | "extras", Array extras -> { g with extras = Some (List.map Tree_sitter_types.parse_rule_ref extras) }
        | "conflicts", Array conflicts -> { g with conflicts = Some (List.map Tree_sitter_types.parse_conflict conflicts) }
        | "inline", Array inlines -> { g with inline = Some (List.map Tree_sitter_types.parse_rule_ref inlines) }
        | "externals", Array externals -> { g with externals = Some (List.map Tree_sitter_types.parse_rule_ref externals) }
        | "precedences", Array precedences -> { g with precedences = Some (List.flatten (List.map Tree_sitter_types.parse_precedence precedences)) }
        | "word", String w -> { g with word = Some w }
        | "supertypes", Array sups -> { g with supertypes = Some (List.map Tree_sitter_types.parse_rule_ref sups) }
        | "scope", Array (v :: _) -> { g with scope = Some (Tree_sitter_types.parse_rule_ref v) }
        | "scope", Array [] -> g
        | "fileTypes", Array fts -> { g with file_types = Some (List.map Tree_sitter_types.parse_string fts) }
        | "injectionRegex", String s -> { g with injection_regex = Some s }
        | "comments", Array comments -> { g with comments = Some (List.map Tree_sitter_types.parse_string comments) }
        | "autoAlias", Boolean true -> { g with auto_alias = Some true }
        | "autoAlias", Boolean false -> { g with auto_alias = Some false }
        | _ -> g
    }
   | IDENT COLON DOLLAR ARROW js_value {
      fun g -> match $1, $5 with
        | "extras", Array extras -> { g with extras = Some (List.map Tree_sitter_types.parse_rule_ref extras) }
        | "inline", Array inlines -> { g with inline = Some (List.map Tree_sitter_types.parse_rule_ref inlines) }
        | "externals", Array externals -> { g with externals = Some (List.map Tree_sitter_types.parse_rule_ref externals) }
        | "supertypes", Array sups -> { g with supertypes = Some (List.map Tree_sitter_types.parse_rule_ref sups) }
        | "conflicts", Array conflicts -> { g with conflicts = Some (List.map Tree_sitter_types.parse_conflict conflicts) }
        | _ -> g
    }
    | IDENT COLON DOLLAR ARROW rule_ref {
      fun g -> match $1, $5 with
        | "word", Identifier s -> { g with word = Some s }
        | _ -> g
    }

js_value:
  | STRING { String $1 }
  | NUMBER { Number $1 }
  | rule_ref { $1 }
  | TRUE { Boolean true }
  | FALSE { Boolean false }
  | NULL { Null }
  | LBRACE js_properties RBRACE { Object $2 }
  | LBRACKET js_elements RBRACKET { Array $2 }
  | LBRACKET array_elements RBRACKET { Array $2 }
  | IDENT { Identifier $1 }
  | function_call { $1 }
  | FUNCTION LPAREN RPAREN LBRACE RBRACE { Function "function(){}" }
  | REGEX { Regex $1 }
  | LPAREN js_value RPAREN { $2 }
  | member_expr { $1 }

member_expr:
  | IDENT { Identifier $1 }
  | member_expr DOT IDENT { MemberAccess($1, $3) }
  | member_expr function_call_args { FunctionCallExpr($1, $2) }

function_call_args:
  | LPAREN js_arguments RPAREN { $2 }

function_call:
  | IDENT LPAREN js_arguments RPAREN { FunctionCall($1, $3) }

js_arguments:
  | /* empty */ { [] }
  | js_value js_arguments_tail { $1 :: $2 }
  | ELLIPSIS js_value js_arguments_tail { Spread($2) :: $3 }

js_arguments_tail:
  | COMMA js_value js_arguments_tail { $2 :: $3 }
  | { [] }
  | COMMA { [] }

js_properties:
  | js_property COMMA js_properties { $1 :: $3 }
  | js_property { [$1] }
  | { [] }

js_property:
  | IDENT COLON js_value { Property($1, $3) }
  | STRING COLON js_value { Property($1, $3) }
  | TRUE COLON js_value { Property("true", $3) }
  | FALSE COLON js_value { Property("false", $3) }
  | IDENT COLON DOLLAR ARROW js_value { Property($1, $5) }
  | TRUE COLON DOLLAR ARROW js_value { Property("true", $5) }
  | FALSE COLON DOLLAR ARROW js_value { Property("false", $5) }
  | IDENT COLON UNDERSCORE ARROW js_value { Property($1, $5) }
  | TRUE COLON UNDERSCORE ARROW js_value { Property("true", $5) }
  | FALSE COLON UNDERSCORE ARROW js_value { Property("false", $5) }

js_elements:
  | js_value COMMA js_elements { $1 :: $3 }
  | js_value { [$1] }
  | ELLIPSIS js_value COMMA js_elements { Spread($2) :: $4 }
  | ELLIPSIS js_value { [Spread($2)] }
  | { [] }

