{
open Antlr_parser
open Lexing

let in_comment = ref false
let brace_count = ref 0
let string_buffer = Buffer.create 256

let pos lexbuf =
  let p = lexbuf.lex_curr_p in
  Printf.sprintf "line %d, character %d" p.pos_lnum (p.pos_cnum - p.pos_bol)

let lexing_error lexbuf c =
  let msg = Printf.sprintf "Unexpected character '%c' at %s" c (pos lexbuf) in
  failwith msg

let update_loc lexbuf =
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <- { pos with
    pos_lnum = pos.pos_lnum + 1;
    pos_bol = pos.pos_cnum;
  }

let keywords = Hashtbl.create 32
let () = List.iter (fun (k, v) -> Hashtbl.add keywords k v) [
  "grammar", GRAMMAR;
  "lexer", LEXER;
  "parser", PARSER;
  "options", OPTIONS;
  "tokens", TOKENS;
  "channels", CHANNELS;
  "import", IMPORT;
  "fragment", FRAGMENT;
  "public", PUBLIC;
  "private", PRIVATE;
  "returns", RETURNS;
  "locals", LOCALS;
  "mode", MODE;
  "skip", SKIP;
  "more", MORE;
  "type", TYPE;
  "channel", CHANNEL;
]

let handle_identifier id =
  try Hashtbl.find keywords id
  with Not_found -> IDENT id

let debug_token token =
  Printf.eprintf "Token: %s\n" (match token with
    | IDENT s -> "IDENT(" ^ s ^ ")"
    | STRING s -> "STRING(" ^ s ^ ")"
    | ACTION s -> "ACTION(" ^ s ^ ")"
    | SEMPRED s -> "SEMPRED(" ^ s ^ ")"
    | GRAMMAR -> "GRAMMAR"
    | LEXER -> "LEXER"
    | PARSER -> "PARSER"
    | COLON -> "COLON"
    | EQUALS -> "EQUALS"
    | SEMICOLON -> "SEMICOLON"
    | PIPE -> "PIPE"
    | STAR -> "STAR"
    | PLUS -> "PLUS"
    | QUESTION -> "QUESTION"
    | LT -> "LT"
    | GT -> "GT"
    | LPAREN -> "LPAREN"
    | RPAREN -> "RPAREN"
    | LBRACE -> "LBRACE"
    | RBRACE -> "RBRACE"
    | COMMA -> "COMMA"
    | ARROW -> "ARROW"
    | OPTIONS -> "OPTIONS"
    | TOKENS -> "TOKENS"
    | CHANNELS -> "CHANNELS"
    | IMPORT -> "IMPORT"
    | FRAGMENT -> "FRAGMENT"
    | PUBLIC -> "PUBLIC"
    | PRIVATE -> "PRIVATE"
    | RETURNS -> "RETURNS"
    | LOCALS -> "LOCALS"
    | MODE -> "MODE"
    | SKIP -> "SKIP"
    | MORE -> "MORE"
    | TYPE -> "TYPE"
    | CHANNEL -> "CHANNEL"
    | EOF -> "EOF"
  );
  token
}

rule token = parse
  | [' ' '\t']          { token lexbuf }
  | '\r'                { token lexbuf }
  | '\n'                { update_loc lexbuf; token lexbuf }
  | "//" [^'\n']* '\n' { update_loc lexbuf; token lexbuf }
  | "/*"                { in_comment := true; block_comment lexbuf }
  | ':'                 { debug_token COLON }
  | '='                 { debug_token EQUALS }
  | ';'                 { debug_token SEMICOLON }
  | '|'                 { debug_token PIPE }
  | '*'                 { debug_token STAR }
  | '+'                 { debug_token PLUS }
  | '?'                 { debug_token QUESTION }
  | '<'                 { debug_token LT }
  | '>'                 { debug_token GT }
  | '('                 { debug_token LPAREN }
  | ')'                 { debug_token RPAREN }
  | '{'                 { Buffer.clear string_buffer; brace_count := 1; action lexbuf }
  | '}'                 { debug_token RBRACE }
  | ','                 { debug_token COMMA }
  | "->"                { debug_token ARROW }
  | '\''               { Buffer.clear string_buffer; string_literal '\'' lexbuf }
  | '"'                { Buffer.clear string_buffer; string_literal '"' lexbuf }
  | ['A'-'Z''a'-'z''_']['A'-'Z''a'-'z''0'-'9''_']* as id 
    { debug_token (handle_identifier id) }
  | eof                 { debug_token EOF }
  | _ as c             { lexing_error lexbuf c }

and block_comment = parse
  | "*/"                { in_comment := false; token lexbuf }
  | '\n'                { update_loc lexbuf; block_comment lexbuf }
  | _                   { block_comment lexbuf }
  | eof                 { failwith "Unterminated block comment" }

and action = parse
  | '{'                 { 
      incr brace_count;
      Buffer.add_char string_buffer '{';
      action lexbuf 
    }
  | '}'                 { 
      decr brace_count;
      if !brace_count = 0 then
        debug_token (ACTION (Buffer.contents string_buffer))
      else (
        Buffer.add_char string_buffer '}';
        action lexbuf
      )
    }
  | "?=>" | "=>" | "?" as pred { 
      Buffer.add_string string_buffer pred;
      debug_token (SEMPRED (Buffer.contents string_buffer))
    }
  | '\n'                { 
      update_loc lexbuf;
      Buffer.add_char string_buffer '\n';
      action lexbuf 
    }
  | [^'{''}''\n']+ as s { 
      Buffer.add_string string_buffer s;
      action lexbuf 
    }
  | eof                 { failwith "Unterminated action" }

and string_literal delim = parse
  | '\\'               { escape_char delim lexbuf }
  | '\n'               { update_loc lexbuf; Buffer.add_char string_buffer '\n'; string_literal delim lexbuf }
  | eof                { failwith "Unterminated string literal" }
  | _ as c             {
      if c = delim then
        debug_token (STRING (Buffer.contents string_buffer))
      else (
        Buffer.add_char string_buffer c; 
        string_literal delim lexbuf 
      )
    }

and escape_char delim = parse
  | ['\\' '''] as c    { Buffer.add_char string_buffer c; string_literal delim lexbuf }
  | _                  { lexing_error lexbuf (Lexing.lexeme_char lexbuf 0) }
  | eof                { failwith "Unterminated string literal" }