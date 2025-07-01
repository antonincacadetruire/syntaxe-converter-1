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
let parse_tree_sitter_to_tree (tree_sitter_source : string) : grammarTS =
  let lexbuf = Lexing.from_string tree_sitter_source in
  try
    lexbuf.Lexing.lex_curr_p <- { 
      lexbuf.Lexing.lex_curr_p with 
      Lexing.pos_fname = "input";
      Lexing.pos_lnum = 1;
    };
    let (_stmts, grammar) = Tree_sitter_parser.main Tree_sitter_lexer.token lexbuf in
    grammar
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

let find_rule (g : grammarTS) (name : string) : rule option =
  List.find_opt (fun (r : rule) -> r.name = name) g.rules

let is_terminal (e : element) : bool = 
  match e with
  | Terminal _ -> true
  | _ -> false

let rec contains_terminal (symbol: symbol) : bool =
  match symbol with
  | Terminal _ -> true
  | NonTerminal _ -> false
  | Choice symbols | Sequence symbols -> List.exists contains_terminal symbols
  | Repeat symbol | Optional symbol | Field (_, symbol) | Alias (symbol, _) -> contains_terminal symbol
  | Rule rule -> contains_terminal (NonTerminal rule.name)
  | FunctionCall (_, args) -> List.exists contains_terminal args


let is_token_rule (r : rule) : bool =
  contains_terminal r.production

let collect_tokens (g : grammarTS) : string list =
  List.map (fun (t : tokens_spec) -> t.name) g.tokens @
  (g.rules
   |> List.filter is_token_rule
   |> List.map (fun (r : rule) -> r.name))