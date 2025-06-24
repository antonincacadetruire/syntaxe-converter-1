%{
  open Tree_sitter_types

  exception SyntaxError of string

  let mk_grammar ~name ~rules ~extras ~conflicts ~inline ~externals ~precedences ~word ~supertypes ~scope ~file_types ~injection_regex ~comments ~auto_alias =
    {
      name;
      rules;
      tokens = []; (* Not used in tree-sitter grammar.js *)
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
%token TRUE FALSE NULL
%token COLON SEMICOLON EQUALS ELLIPSIS
%token LPAREN RPAREN LBRACE RBRACE COMMA LBRACKET RBRACKET
%token MODULE EXPORTS GRAMMAR
%token DOT FUNCTION CONST LET VAR
%token EOF

%start <grammar> main
%%

main:
  | js_statements grammar_export EOF { $2 }
  | error { raise (SyntaxError "Unexpected token in main rule") }

js_statements:
  | /* empty */ { () }
  | js_statement js_statements { () }

js_statement:
  | CONST IDENT EQUALS js_value SEMICOLON { () }
  | LET IDENT EQUALS js_value SEMICOLON { () }
  | VAR IDENT EQUALS js_value SEMICOLON { () }

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

grammar_fields:
  | /* empty */ { [] }
  | f=grammar_field rest=grammar_fields_tail { f :: rest }

grammar_fields_tail:
  | COMMA f=grammar_field rest=grammar_fields_tail { f :: rest }
  | { [] }

// Each field updates the grammar record
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

// JS value parsing
js_value:
  | STRING { String $1 }
  | NUMBER { Number $1 }
  | TRUE { Boolean true }
  | FALSE { Boolean false }
  | NULL { Null }
  | LBRACE js_properties RBRACE { Object $2 }
  | LBRACKET js_elements RBRACKET { Array $2 }
  | IDENT { Identifier $1 }
  | FUNCTION LPAREN RPAREN LBRACE RBRACE { Function "function(){}" }

js_properties:
  | js_property COMMA js_properties { $1 :: $3 }
  | js_property { [$1] }
  | { [] }

js_property:
  | IDENT COLON js_value { Property($1, $3) }
  | STRING COLON js_value { Property($1, $3) }

js_elements:
  | js_value COMMA js_elements { $1 :: $3 }
  | js_value { [$1] }
  | { [] }
