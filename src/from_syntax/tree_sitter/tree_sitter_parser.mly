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
%token EOF RETURN EQUALS_EQUALS STRICT_EQUALS QUESTION

%start <(js_statement list * grammarTS)> main
%%

main:
  | preamble=js_statements grammar_export opt_semicolon js_statements EOF { (preamble, $2) }
  | preamble=js_statements EOF { (preamble, mk_grammar ~name:"" ~rules:[] ~extras:None ~conflicts:None ~inline:None ~externals:None ~precedences:None ~word:None ~supertypes:None ~scope:None ~file_types:None ~injection_regex:None ~comments:None ~auto_alias:None) }
  | error { raise (SyntaxError "Unexpected token in main rule") }

opt_semicolon:
  | SEMICOLON { () }
  | { () }

js_statements:
  | /* empty */ { [] }
  | js_statement js_statements { $1 :: $2 }

js_statement:
  | CONST IDENT EQUALS js_value SEMICOLON { ConstDecl($2, $4) }
  | LET IDENT EQUALS js_value SEMICOLON { LetDecl($2, $4) }
  | VAR IDENT EQUALS js_value SEMICOLON { VarDecl($2, $4) }
  | FUNCTION IDENT LPAREN parameter_list RPAREN LBRACE js_statements RBRACE { FunctionDecl($2, $4, $7) }
  | RETURN js_value SEMICOLON { Return $2 }

grammar_export:
  | MODULE DOT EXPORTS EQUALS GRAMMAR LPAREN grammar_object opt_trailing_comma RPAREN { $7 }
  | error { raise (SyntaxError "Unexpected token in grammar export") }

opt_trailing_comma:
  | COMMA { () }
  | { () }

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
  | DOLLAR DOT NULL { Identifier "null" }

regex:
  | REGEX { Regex $1 }

array_elements:
  | /* empty */ { [] }
  | rule_ref { [$1] }
  | regex { [$1] }
  | rule_ref COMMA array_elements { $1 :: $3 }
  | regex COMMA array_elements { $1 :: $3 }

grammar_fields:
  | grammar_field_list opt_comma { $1 }
  | { [] }

grammar_field_list:
  | grammar_field COMMA grammar_field_list { $1 :: $3 }
  | grammar_field COMMA { [$1] }      /* allow trailing comma */
  | grammar_field { [$1] }

grammar_fields_tail:
  | COMMA f=grammar_field rest=grammar_fields_tail { f :: rest }
  | { [] }

grammar_field:
  | IDENT COLON js_value {
      fun g -> match $1, $3 with
      | "name", String s -> { g with name = s }
      | "rules", Object rules -> { g with rules = parse_rules rules }
      | "extras", Array extras -> { g with extras = Some (List.map parse_rule_ref_to_string extras) }
      | "conflicts", Array conflicts -> { g with conflicts = Some (List.map parse_conflict conflicts) }
      | "inline", Array inlines -> { g with inline = Some (List.map parse_rule_ref_to_string inlines) }
      | "externals", Array externals -> { g with externals = Some (List.map parse_rule_ref_to_string externals) }
      | "precedences", Array precedences -> { g with precedences = Some (List.flatten (List.map parse_precedence precedences)) }
      | "word", String w -> { g with word = Some w }
      | "supertypes", Array sups -> { g with supertypes = Some (List.map parse_rule_ref_to_string sups) }
      | "scope", Array (v :: _) -> { g with scope = Some (parse_rule_ref_to_string v) }
      | "scope", Array [] -> g
      | "fileTypes", Array fts -> { g with file_types = Some (List.map parse_string fts) }
      | "injectionRegex", String s -> { g with injection_regex = Some s }
      | "comments", Array comments -> { g with comments = Some (List.map parse_string comments) }
      | "autoAlias", Boolean true -> { g with auto_alias = Some true }
      | "autoAlias", Boolean false -> { g with auto_alias = Some false }
      | _ -> g
  }
  | IDENT COLON DOLLAR ARROW js_value {
      fun g -> match $1, $5 with
      | "extras", Array extras -> { g with extras = Some (List.map parse_rule_ref_to_string extras) }
      | "inline", Array inlines -> { g with inline = Some (List.map parse_rule_ref_to_string inlines) }
      | "externals", Array externals -> { g with externals = Some (List.map parse_rule_ref_to_string externals) }
      | "supertypes", Array sups -> { g with supertypes = Some (List.map parse_rule_ref_to_string sups) }
      | "conflicts", Array conflicts -> { g with conflicts = Some (List.map parse_conflict conflicts) }
      | _ -> g
  }
  | IDENT COLON DOLLAR ARROW rule_ref {
      fun g -> match $1, $5 with
      | "word", Identifier s -> { g with word = Some s }
      | _ -> g
  }

js_value:
  | arrow_function { $1 }
  | STRING { String $1 }
  | NUMBER { Number $1 }
  | rule_ref { $1 }
  | TRUE { Boolean true }
  | FALSE { Boolean false }
  | NULL { Null }
  | LBRACE js_properties RBRACE { Object $2 }
  | LBRACKET js_elements RBRACKET { Array $2 }
  | function_call { $1 }
  | FUNCTION LPAREN RPAREN LBRACE RBRACE { Function "function(){}" }
  | REGEX { Regex $1 }
  | LPAREN js_value RPAREN { $2 }
  | member_expr { $1 }
  | js_value QUESTION js_value COLON js_value { Ternary($1, $3, $5) }
  | js_value STRICT_EQUALS js_value { FunctionCall("===", [$1; $3]) }
  | js_value EQUALS_EQUALS js_value { FunctionCall("==", [$1; $3]) }


arrow_function:
  | parameter_list ARROW js_block { ArrowFunctionBlock($1, $3) }
  | parameter_list ARROW js_value { ArrowFunction($1, $3) }

js_block:
  | LBRACE js_block_statements RBRACE { $2 }

js_block_statements:
  | /* empty */ { [] }
  | js_block_statement js_block_statements { $1 :: $2 }

js_block_statement:
  | js_statement { $1 }
  | js_expression SEMICOLON { ExprStmt($1) }

js_expression:
  | js_value { $1 }

parameter_list:
  | IDENT { [ParamIdent $1] }
  | LBRACKET destructuring_elements RBRACKET { [ParamArray $2] }
  | LPAREN parameter_list_inner RPAREN { $2 }
  | UNDERSCORE { [ParamIdent "_"] }


parameter_list_inner:
  | /* empty */ { [] }
  | parameter { [$1] }
  | parameter COMMA parameter_list_inner { $1 :: $3 }

parameter:
  | IDENT { ParamIdent $1 }
  | LBRACKET destructuring_elements RBRACKET { ParamArray $2 }
  | UNDERSCORE { ParamIdent "_" }

// Destructuring for array patterns
// Only basic support for [a, b] style

destructuring_elements:
  | IDENT { [ParamIdent $1] }
  | IDENT COMMA destructuring_elements { ParamIdent $1 :: $3 }
  | { [] }

member_expr:
  | IDENT { Identifier $1 }
  | LBRACKET js_elements RBRACKET { Array $2 }
  | LBRACE js_properties RBRACE { Object $2 }
  | LPAREN js_value RPAREN { $2 }
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
  | nonempty_js_properties opt_comma { $1 }
  | { [] }

nonempty_js_properties:
  | js_property COMMA nonempty_js_properties { $1 :: $3 }
  | js_property COMMA { [$1] }      /* allow trailing comma */
  | js_property { [$1] }

opt_comma:
  | COMMA { () }
  | { () }

js_property:
  | IDENT COLON js_value { Property($1, $3) }
  | STRING COLON js_value { Property($1, $3) }
  | TRUE COLON js_value { Property("true", $3) }
  | FALSE COLON js_value { Property("false", $3) }
  | NULL COLON js_value { Property("null", $3) }
  | IDENT COLON DOLLAR ARROW js_value { Property($1, $5) }
  | TRUE COLON DOLLAR ARROW js_value { Property("true", $5) }
  | FALSE COLON DOLLAR ARROW js_value { Property("false", $5) }
  | NULL COLON DOLLAR ARROW js_value { Property("null", $5) }
  | IDENT COLON UNDERSCORE ARROW js_value { Property($1, $5) }
  | TRUE COLON UNDERSCORE ARROW js_value { Property("true", $5) }
  | FALSE COLON UNDERSCORE ARROW js_value { Property("false", $5) }
  | NULL COLON UNDERSCORE ARROW js_value { Property("null", $5) }
  | IDENT COLON UNDERSCORE ARROW js_block { Property($1, ArrowFunctionBlock([ParamIdent "_"], $5)) }
  | TRUE COLON UNDERSCORE ARROW js_block { Property("true", ArrowFunctionBlock([ParamIdent "_"], $5)) }
  | FALSE COLON UNDERSCORE ARROW js_block { Property("false", ArrowFunctionBlock([ParamIdent "_"], $5)) }
  | NULL COLON UNDERSCORE ARROW js_block { Property("null", ArrowFunctionBlock([ParamIdent "_"], $5)) }

js_elements:
  | js_value COMMA js_elements opt_comma { $1 :: $3 }
  | js_value opt_comma { [$1] }
  | ELLIPSIS js_value COMMA js_elements opt_comma { Spread($2) :: $4 }
  | ELLIPSIS js_value COMMA opt_comma { [Spread($2)] } /* allow trailing comma after spread */
  | ELLIPSIS js_value opt_comma { [Spread($2)] }
  | { [] }