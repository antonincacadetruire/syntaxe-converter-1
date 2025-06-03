{
open Antlr_parser
}

rule token = parse
  | [' ' '\t' '\r' '\n'] { token lexbuf }
  | ':'                  { COLON }
  | ';'                  { SEMICOLON }
  | ['A'-'Z''a'-'z''_']['A'-'Z''a'-'z''0'-'9''_']* as id { IDENT id }
  | eof                  { EOF }
