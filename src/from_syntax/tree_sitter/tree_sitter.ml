open Tree_sitter_types

(* Error handling *)
type parse_error = {
  message: string;
  location: location;
  input: string;
}

exception Parse_error of parse_error

let format_location loc =
  Printf.sprintf "line %d, column %d" loc.line loc.column

(* Main parsing function *)
let parse_tree_sitter_to_tree (tree_sitter_source : string) : grammar =
  let lexbuf = Lexing.from_string tree_sitter_source in
  try
    lexbuf.Lexing.lex_curr_p <- { 
      lexbuf.Lexing.lex_curr_p with 
      Lexing.pos_fname = "input";
      Lexing.pos_lnum = 1;
    };
    Tree_sitter_parser.main Tree_sitter_lexer.token lexbuf
  with
  | Parsing.Parse_error ->
      let loc = {
        line = lexbuf.Lexing.lex_curr_p.Lexing.pos_lnum;
        column = lexbuf.Lexing.lex_curr_p.Lexing.pos_cnum - 
                 lexbuf.Lexing.lex_curr_p.Lexing.pos_bol;
      } in
      let start_pos = max 0 (lexbuf.Lexing.lex_curr_pos - 20) in
      let end_pos = min (String.length tree_sitter_source) (lexbuf.Lexing.lex_curr_pos + 20) in
      let context = String.sub tree_sitter_source start_pos (end_pos - start_pos) in
      raise (Parse_error {
        message = "Syntax error";
        location = loc;
        input = context;
      })
  | Failure msg ->
      let loc = {
        line = lexbuf.Lexing.lex_curr_p.Lexing.pos_lnum;
        column = lexbuf.Lexing.lex_curr_p.Lexing.pos_cnum - 
                 lexbuf.Lexing.lex_curr_p.Lexing.pos_bol;
      } in
      raise (Parse_error {
        message = msg;
        location = loc;
        input = tree_sitter_source;
      })

(* Helper functions *)
let rec string_of_element (e : element) : string = 
  match e with
  | Terminal s -> Printf.sprintf "\"%s\"" s
  | NonTerminal s -> s
  | Action s -> Printf.sprintf "{%s}" s
  | SemanticPredicate s -> Printf.sprintf "{%s}?" s
  | Label (l, e) -> Printf.sprintf "%s=%s" l (string_of_element e)
  | Group elements -> 
      Printf.sprintf "(%s)" 
        (String.concat " " (List.map string_of_element elements))
  | Ebnf (e, suffix) ->
      Printf.sprintf "%s%s"
        (string_of_element e)
        (match suffix with
         | Optional -> "?"
         | ZeroOrMore -> "*"
         | OneOrMore -> "+"
         | ZeroOrMoreNonGreedy -> "*?"
         | OneOrMoreNonGreedy -> "+?"
         | OptionalNonGreedy -> "??" )
  | CharacterClass s -> Printf.sprintf "[%s]" s
  | Wildcard -> "." 

let find_rule (g : grammar) (name : string) : rule option =
  List.find_opt (fun (r : rule) -> r.name = name) g.rules

let is_terminal (e : element) : bool = 
  match e with
  | Terminal _ -> true
  | _ -> false

let is_token_rule (r : rule) : bool =
  List.exists ((=) Fragment) r.modifiers ||
  List.exists (fun (alt : alternative) -> List.exists is_terminal alt.elements) r.alternatives

let collect_tokens (g : grammar) : string list =
  List.map (fun (t : tokens_spec) -> t.name) g.tokens @
  (g.rules
   |> List.filter is_token_rule
   |> List.map (fun (r : rule) -> r.name))