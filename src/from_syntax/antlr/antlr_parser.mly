%{
open Antlr_types

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

grammar_decl:
  | g = raw_grammar_decl SEMICOLON { g }

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

option_section:
  | OPTIONS LBRACE opts = option_list RBRACE SEMICOLON?
    { opts }

option_list:
  | opts = separated_list(SEMICOLON, option_decl)  { opts }

option_decl:
  | name = IDENT EQUALS value = option_value SEMICOLON?
    { {name; value} }

option_value:
  | id = IDENT   { id }
  | s = STRING   { s }
  | a = ACTION   { a }


import_section:
  | IMPORT imports = separated_list(COMMA, STRING) SEMICOLON
    { imports }

channel_section:
  | CHANNELS LBRACE channels = separated_list(COMMA, channel_decl) RBRACE
    { channels }

channel_decl:
  | name = IDENT
    { name }

token_section:
  | TOKENS LBRACE tokens = separated_list(COMMA, token_spec) RBRACE
    { tokens }

token_spec:
  | name = IDENT LT t = IDENT GT
    { { name; type_ = Some t } }
  | name = IDENT
    { { name; type_ = None } }

mode_section:
  | MODE id = IDENT SEMICOLON rules = rules
    { {mode_name = id; mode_rules = rules} }

rules:
  | r = rule rs = rules { r :: rs }
  | { [] }

rule:
  | mods = modifier*
    name = IDENT
    ret = returns
    loc = locals?
    COLON
    alts = alternatives
    SEMICOLON
    { mk_rule ~name ~mods ~ret ~loc ~alts $startpos }
  | mods = modifier*
    name = IDENT
    loc = locals?
    COLON
    alts = alternatives
    SEMICOLON
    { mk_rule ~name ~mods ~ret:[] ~loc ~alts $startpos }


modifier:
  | FRAGMENT { Fragment }
  | PUBLIC { Public }
  | PRIVATE { Private }

command:
  | ARROW s = ACTION { s }
  | ARROW SKIP { "skip" }
  | ARROW MORE { "more" }
  | ARROW TYPE { "type" }
  | ARROW CHANNEL { "channel" }
  | ARROW s = IDENT { s }

returns:
  | RETURNS LT id = IDENT GT { [id] }

locals:
  | LOCALS LT IDENT GT { "local" } (* Single string for the local variable *)

alternatives:
  | alts = separated_nonempty_list(PIPE, alternative) { alts }


alternative:
  | pred = predicate? elems = element+ _cmd = command?
    {
      {
        predicate = pred;
        elements = elems;
      }
    }

predicate:
  | LBRACE pred = ACTION RBRACE QUESTION { pred }

element:
  | label = IDENT ARROW e = element_base s = suffix?
    {
      Printf.eprintf "Parser: Processing Label with ARROW: %s\n" label;
      let e = match s with
        | None -> e
        | Some s -> Ebnf(e, s)
      in
      Label(label, e)
    }
  | label = IDENT EQUALS e = element_base s = suffix?
    {
      Printf.eprintf "Parser: Processing Label with EQUALS: %s\n" label;
      let e = match s with
        | None -> e
        | Some s -> Ebnf(e, s)
      in
      Label(label, e)
    }
   | label = LABEL e = element_base s = suffix?
    {
      Printf.eprintf "Parser: Processing Label: %s\n" label;
      let e = match s with
        | None -> e
        | Some s -> Ebnf(e, s)
      in
      Label(label, e)
    }
    | label = LABEL
    {
      Printf.eprintf "Parser: Processing Label: %s\n" label;
      Label("", NonTerminal label)
    }
  | e = element_base s = suffix?
    {
      match s with
      | None -> e
      | Some s -> Ebnf(e, s)
    }

element_base:
  | id = IDENT { NonTerminal id }
  | s = STRING { Terminal s }
  | a = ACTION { Action a }
  | s = SEMPRED { SemanticPredicate s }
  | LPAREN alts = alternatives RPAREN
    {
      let alt = List.hd alts in
      (* Create a group containing all elements within the parentheses *)
      Group alt.elements
    }
  | LBRACKET alts = alternatives RBRACKET
    {
      let alt = List.hd alts in
      (* Create a group containing all elements within the bracket *)
      Group alt.elements
    }

suffix:
  | QUESTION { Optional }
  | STAR { ZeroOrMore }
  | PLUS { OneOrMore }
