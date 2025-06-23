%{
open Tree_sitter_types

(* Define a custom exception for syntax errors *)
exception SyntaxError of string

let mk_location startpos =
  {
    line = startpos.Lexing.pos_lnum;
    column = startpos.Lexing.pos_cnum - startpos.Lexing.pos_bol;
  }

let mk_rule ~name ~mods ~ret ~loc ~alts pos =
  {
    name;
    modifiers = mods;
    returns = ret;
    locals = loc;
    alternatives = alts;
    location = mk_location pos;
  }
%}

%token <string> IDENT
%token <string> STRING
%token <string> ACTION
%token <string> SEMPRED
%token <string> LABEL
%token <string> CHAR_CLASS
%token GRAMMAR LEXER PARSER
%token COLON SEMICOLON EQUALS
%token PIPE STAR PLUS QUESTION
%token LT GT LPAREN RPAREN LBRACE RBRACE COMMA LBRACKET RBRACKET
%token OPTIONS TOKENS CHANNELS IMPORT
%token FRAGMENT PUBLIC PRIVATE RETURNS LOCALS
%token MODE SKIP MORE TYPE CHANNEL
%token ARROW
%token DOT DOTSTAR
%token EOF

%start <grammar> main
%%

main:
  | decl = grammar_decl
    opts = option_section?
    imports = import_section?
    tokens = token_section?
    channels = channel_section?
    rules = rules
    EOF
    {
      let g = decl in
      { g with
        options = (match opts with Some o -> o | None -> []);
        imports = (match imports with Some i -> i | None -> []);
        tokens = (match tokens with Some t -> t | None -> []);
        channels = (match channels with Some c -> c | None -> []);
        rules = rules
      }
    }
  | error { raise (SyntaxError "Unexpected token in main rule") }

grammar_decl:
  | g = raw_grammar_decl SEMICOLON { g }
  | error { raise (SyntaxError "Unexpected token in grammar declaration") }

raw_grammar_decl:
  | GRAMMAR name = IDENT
    { { name; type_ = Combined;
        options = []; tokens = []; imports = [];
        channels = []; rules = [] } }
  | LEXER GRAMMAR name = IDENT
    { { name; type_ = Lexer;
        options = []; tokens = []; imports = [];
        channels = []; rules = [] } }
  | PARSER GRAMMAR name = IDENT
    { { name; type_ = Parser;
        options = []; tokens = []; imports = [];
        channels = []; rules = [] } }
  | error { raise (SyntaxError "Unexpected token in raw grammar declaration") }

option_section:
  | OPTIONS LBRACE opts = option_list RBRACE SEMICOLON? { opts }
  | error { raise (SyntaxError "Unexpected token in option section") }

option_list:
  | opts = separated_list(SEMICOLON, option_decl) { opts }
  | error { raise (SyntaxError "Unexpected token in option list") }

option_decl:
  | name = IDENT EQUALS value = option_value SEMICOLON? { {name; value} }
  | error { raise (SyntaxError "Unexpected token in option declaration") }

option_value:
  | id = IDENT { id }
  | s = STRING { s }
  | a = ACTION { a }
  | error { raise (SyntaxError "Unexpected token in option value") }

import_section:
  | IMPORT imports = separated_list(COMMA, STRING) SEMICOLON { imports }
  | error { raise (SyntaxError "Unexpected token in import section") }

channel_section:
  | CHANNELS LBRACE channels = separated_list(COMMA, channel_decl) RBRACE { channels }
  | error { raise (SyntaxError "Unexpected token in channel section") }

channel_decl:
  | name = IDENT { name }
  | error { raise (SyntaxError "Unexpected token in channel declaration") }

token_section:
  | TOKENS LBRACE tokens = separated_list(COMMA, token_spec) RBRACE { tokens }
  | error { raise (SyntaxError "Unexpected token in token section") }

token_spec:
  | name = IDENT LT t = IDENT GT { { name; type_ = Some t } }
  | name = IDENT { { name; type_ = None } }
  | error { raise (SyntaxError "Unexpected token in token specification") }

rules:
  | r = rule rs = rules { r :: rs }
  | { [] }
  | error { raise (SyntaxError "Unexpected token in rules") }

rule:
  | mods = modifier* name = IDENT ret = returns loc = locals? COLON alts = alternatives SEMICOLON
    { mk_rule ~name ~mods ~ret ~loc ~alts $startpos }
  | mods = modifier* name = IDENT loc = locals? COLON alts = alternatives SEMICOLON
    { mk_rule ~name ~mods ~ret:[] ~loc ~alts $startpos }
  | error { raise (SyntaxError "Unexpected token in rule") }

modifier:
  | FRAGMENT { Fragment }
  | PUBLIC { Public }
  | PRIVATE { Private }
  | error { raise (SyntaxError "Unexpected token in modifier") }

command:
  | ARROW s = ACTION { Some s }
  | ARROW SKIP { Some "skip" }
  | ARROW MORE { Some "more" }
  | ARROW TYPE { Some "type" }
  | ARROW CHANNEL { Some "channel" }
  | ARROW s = IDENT { Some s }
  | { None }
  | error { raise (SyntaxError "Unexpected token in command") }

returns:
  | RETURNS LT id = IDENT GT { [id] }
  | error { raise (SyntaxError "Unexpected token in returns") }

locals:
  | LOCALS LT IDENT GT { "local" }
  | error { raise (SyntaxError "Unexpected token in locals") }

alternatives:
  | alts = separated_nonempty_list(PIPE, alternative) { alts }
  | { [] } (* Allow for empty alternatives *)
  | error { raise (SyntaxError "Unexpected token in alternatives") }

alternative:
  | pred = predicate? elems = element+ cmd = command {
      { predicate = pred; elements = elems; command = cmd }
    }
  | pred = predicate? elems = element+ {
      { predicate = pred; elements = elems; command = None }
    }
  | error { raise (SyntaxError "Unexpected token in alternative") }

predicate:
  | LBRACE pred = ACTION RBRACE QUESTION { pred }
  | error { raise (SyntaxError "Unexpected token in predicate") }

element:
  | label = IDENT ARROW e = element_base s = suffix? { let e = match s with None -> e | Some s -> Ebnf(e, s) in Label(label, e) }
  | label = IDENT EQUALS e = element_base s = suffix? { let e = match s with None -> e | Some s -> Ebnf(e, s) in Label(label, e) }
  | label = LABEL e = element_base s = suffix? { let e = match s with None -> e | Some s -> Ebnf(e, s) in Label(label, e) }
  | label = LABEL { Label("", NonTerminal label) }
  | chars = CHAR_CLASS s = suffix?
      {
        match s with
        | None -> CharacterClass(chars)  (* No suffix, just a character class *)
        | Some suffix -> Ebnf(CharacterClass(chars), suffix)  (* Apply the suffix to the character class *)
      }  
  // | chars = CHAR_CLASS { CharacterClass(chars) }
  | e = element_base s = suffix? { match s with None -> e | Some s -> Ebnf(e, s) }
  | error { raise (SyntaxError "Unexpected token in element ") }


element_base:
  | id = IDENT { NonTerminal id }
  | s = STRING { Terminal s }
  | a = ACTION { Action a }
  | s = SEMPRED { SemanticPredicate s }
  | LPAREN alts = alternatives RPAREN { let alt = List.hd alts in Group alt.elements }
  | LBRACKET content = CHAR_CLASS RBRACKET { CharacterClass content }
  | DOT { Wildcard } 
  | error { raise (SyntaxError "Unexpected token in element base") }

suffix:
  | QUESTION            { Optional }
  | STAR                { ZeroOrMore }
  | PLUS                { OneOrMore }
  | STAR QUESTION       { ZeroOrMoreNonGreedy }
  | PLUS QUESTION       { OneOrMoreNonGreedy }
  | QUESTION QUESTION   { OptionalNonGreedy }
  | error { raise (SyntaxError "Unexpected token in suffix") }
