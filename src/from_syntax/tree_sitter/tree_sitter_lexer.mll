{
  open Tree_sitter_parser
  open Lexing

  let in_comment = ref false
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

  let in_char_class = ref false

  let js_keywords = Hashtbl.create 32
  let () = List.iter (fun (k, v) -> Hashtbl.add js_keywords k v) [
    "function", FUNCTION;
    "true", TRUE;
    "false", FALSE;
    "null", NULL;
    "module", MODULE;
    "exports", EXPORTS;
    "const", CONST;
    "let", LET;
    "var", VAR;
    "grammar", GRAMMAR;
  ]

  let handle_js_identifier id =
    try Hashtbl.find js_keywords id
    with Not_found -> IDENT id

  let string_of_token = function
  | IDENT a -> Printf.sprintf "IDENT (%s)" a
  | STRING s -> Printf.sprintf "STRING (\"%s\")" s
  | NUMBER a -> Printf.sprintf "NUMBER %d" a
  | REGEX s -> Printf.sprintf "REGEX (\"%s\")" s
  | TRUE -> "TRUE"
  | FALSE -> "FALSE"
  | NULL -> "NULL"
  | COLON -> "COLON"
  | SEMICOLON -> "SEMICOLON"
  | EQUALS -> "EQUALS"
  | LPAREN -> "LPAREN"
  | RPAREN -> "RPAREN"
  | LBRACE -> "LBRACE"
  | RBRACE -> "RBRACE"
  | COMMA -> "COMMA"
  | LBRACKET -> "LBRACKET"
  | RBRACKET -> "RBRACKET"
  | MODULE -> "MODULE\n"
  | EXPORTS -> "EXPORTS"
  | GRAMMAR -> "GRAMMAR"
  | DOT -> "DOT"
  | FUNCTION -> "FUNCTION"
  | CONST -> "CONST"
  | LET -> "LET"
  | VAR -> "VAR"
  | ELLIPSIS -> "..."
  | ARROW -> "ARROW"
  | DOLLAR -> "$"
  | UNDERSCORE -> "UNDERSCORE"
  | RETURN -> "RETURN"
  | EQUALS_EQUALS -> "EQUALS_EQUALS"
  | STRICT_EQUALS -> "STRICT_EQUALS"
  | QUESTION -> "QUESTION"
  | EOF -> "EOF"

  let debug_token token =
    Printf.printf "Token : %s\n" (string_of_token token);
    token
}

rule token = parse
  | [' ' '\t'] { token lexbuf }
  | '\r' { token lexbuf }
  | '\n' { update_loc lexbuf; token lexbuf }
  | "//" [^'\n']* '\n' { update_loc lexbuf; token lexbuf }
  | "/*" { in_comment := true; block_comment lexbuf }
  | "return" { debug_token RETURN }
  | '{' { debug_token LBRACE }
  | '}' { debug_token RBRACE }
  | '[' { debug_token LBRACKET }
  | ']' { debug_token RBRACKET }
  | '(' { debug_token LPAREN }
  | ')' { debug_token RPAREN }
  | ':' { debug_token COLON }
  | ';' { debug_token SEMICOLON }
  | ',' { debug_token COMMA }
  | '.' { debug_token DOT }
  | '_' { debug_token UNDERSCORE }
  | '?' { debug_token QUESTION }
  | "..." { debug_token ELLIPSIS }
  | '=' { debug_token EQUALS }
  | "==" { debug_token EQUALS_EQUALS }
  | "===" { debug_token STRICT_EQUALS }
  | '$' { debug_token DOLLAR }
  | "=>" { debug_token ARROW}
  | "null" { debug_token NULL }
  | "true" { debug_token TRUE }
  | '`' { Buffer.clear string_buffer; template_literal lexbuf }
  | '"' { Buffer.clear string_buffer; string_literal '"' lexbuf }
  | '\'' { Buffer.clear string_buffer; string_literal '\'' lexbuf }
  | "-" ['0'-'9']+ as num { debug_token (NUMBER (int_of_string num)) }
  | ['0'-'9']+ as num { debug_token (NUMBER (int_of_string num)) }
  (* | ['0'-'9']+ '.' ['0'-'9']* ([eE]['+'-']?['0'-'9']+)? as num { debug_token (FLOAT (float_of_string num)) }
  | ['0'-'9']+ [eE] ['+' '-']? ['0'-'9']+ as num { debug_token (FLOAT (float_of_string num)) } *)
  | ['A'-'Z''a'-'z''_''$']['A'-'Z''a'-'z''0'-'9''_''$']* as id { debug_token (handle_js_identifier id) }
  (* | "'" [^'\\'] "'" as s { debug_token (STRING s) } *)
  (* | ['A'-'Z''a'-'z''_''$']['A'-'Z''a'-'z''0'-'9''_''$']* as id { 
  debug_token (handle_js_identifier id);
  IDENT (id, Lexing.lexeme_start_p lexbuf)
} *)
  | "false" { debug_token FALSE }
  | "//" [^'\n']* { token lexbuf }
  | eof { EOF }
  | '/' { Buffer.clear string_buffer; regex_handler lexbuf} 
  | _ as c { lexing_error lexbuf c }

and block_comment = parse
  | "*/" { in_comment := false; token lexbuf }
  | '\n' { update_loc lexbuf; block_comment lexbuf }
  | _ { block_comment lexbuf }
  | eof { failwith "Unterminated block comment" }

and string_literal delim = parse
  | '\\' { escape_char delim lexbuf }
  | '\n' { update_loc lexbuf; Buffer.add_char string_buffer '\n'; string_literal delim lexbuf }
  | eof { failwith "Unterminated string literal" }
  | _ as c {
      if c = delim then
        debug_token (STRING (Buffer.contents string_buffer))
      else (
        Buffer.add_char string_buffer c;
        string_literal delim lexbuf
      )
    }

and template_literal = parse
  | '`' { STRING (Buffer.contents string_buffer) }
  | '\\' { escape_char '`' lexbuf }
  | '\n' { update_loc lexbuf; Buffer.add_char string_buffer '\n'; template_literal lexbuf }
  | eof { failwith "Unterminated template literal" }
  | _ as c {
      Buffer.add_char string_buffer c;
      template_literal lexbuf
    }

and escape_char delim = parse
  | ['\\' '\'' '"' 'n' 't' 'r' 'b' 'f' 'v' '0'] as c { Buffer.add_char string_buffer c; string_literal delim lexbuf }
  | _ { lexing_error lexbuf (Lexing.lexeme_char lexbuf 0) }
  | eof { failwith "Unterminated string literal" }

and regex_handler = parse
  | '[' {
      in_char_class := true;
      Buffer.add_char string_buffer '[';
      regex_handler lexbuf
    }
  | ']' {
      in_char_class := false;
      Buffer.add_char string_buffer ']';
      regex_handler lexbuf
    }
  | '/' {
      if not !in_char_class then (
        let regex = Buffer.contents string_buffer in
        Buffer.clear string_buffer;
        (* Read flags: zero or more [a-z] *)
        let flags_buf = Buffer.create 8 in
        let rec read_flags () =
          let buf_len = Bytes.length lexbuf.Lexing.lex_buffer in
          if lexbuf.Lexing.lex_curr_pos < buf_len then
            let c = Bytes.get lexbuf.Lexing.lex_buffer lexbuf.Lexing.lex_curr_pos in
            if 'a' <= c && c <= 'z' then (
              Buffer.add_char flags_buf c;
              lexbuf.Lexing.lex_curr_pos <- lexbuf.Lexing.lex_curr_pos + 1;
              read_flags ()
            )
        in
        read_flags ();
        (* let flags = Buffer.contents flags_buf in *)
        debug_token (REGEX regex)
      ) else (
        Buffer.add_char string_buffer '/';
        regex_handler lexbuf
      )
    }
  | [^'/''['']']+ as chunk {
      Buffer.add_string string_buffer chunk;
      regex_handler lexbuf
    }
  | eof { failwith "Unterminated regex literal" }
