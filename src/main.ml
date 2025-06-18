open Cmdliner
open From_syntax_antlr
open Antlr_types

let from =
  let doc = "Source grammar format (e.g., ebnf, antlr, bison, etc.). If not provided, will be detected from file extension." in
  Arg.(value & opt (some string) None & info ["from"] ~docv:"FORMAT" ~doc)

let to_ =
  let doc = "Target grammar format (e.g., ebnf, antlr, bison, etc.). If not provided, will be detected from file extension." in
  Arg.(value & opt (some string) None & info ["to"] ~docv:"FORMAT" ~doc)

let input =
  let doc = "Input grammar file." in
  Arg.(required & pos 0 (some string) None & info [] ~docv:"INPUT" ~doc)

let output =
  let doc = "Output grammar file." in
  Arg.(required & pos 1 (some string) None & info [] ~docv:"OUTPUT" ~doc)

let detect_format filename =
  match Filename.extension filename with
  | ".g4" -> Some "antlr"
  | _ -> None

let string_of_modifiers = function
  | Fragment -> "fragment"
  | Public -> "public"
  | Private -> "private"

let rec string_of_element = function
  | Terminal s -> "'" ^ String.escaped s ^ "'"
  | NonTerminal s -> s
  | Action s -> s
  | SemanticPredicate s -> s
  | Label (_, e) -> string_of_element e
  | Ebnf (e, Optional) -> string_of_element e ^ "?"
  | Ebnf (e, ZeroOrMore) -> string_of_element e ^ "*"
  | Ebnf (e, OneOrMore) -> string_of_element e ^ "+"
  | Ebnf (e, ZeroOrMoreNonGreedy) -> string_of_element e ^ "*?"
  | Ebnf (e, OneOrMoreNonGreedy) -> string_of_element e ^ "+?"
  | Ebnf (e, OptionalNonGreedy) -> string_of_element e ^ "??"
  | Group es -> "(" ^ String.concat " " (List.map string_of_element es) ^ ")"
  | CharacterClass s -> "[" ^ s ^ "]"
  | Wildcard -> "."

let string_of_alternative alt =
  let predicate_str = match alt.predicate with
    | Some p -> p ^ " : "
    | None -> ""
  in
  let elements_str = String.concat " " (List.map string_of_element alt.elements) in
  let command_str = match alt.command with
    | Some cmd -> " -> " ^ cmd
    | None -> ""
  in
  predicate_str ^ elements_str ^ command_str

let string_of_rule rule =
  let modifiers_str = String.concat " " (List.map string_of_modifiers rule.modifiers) in
  let returns_str = if rule.returns <> [] then " returns [" ^ String.concat ", " rule.returns ^ "]" else "" in
  let locals_str = match rule.locals with
    | Some l -> " locals [" ^ l ^ "]"
    | None -> ""
  in
  let alternatives_str = String.concat "\n  | " (List.map string_of_alternative rule.alternatives) in
  Printf.sprintf "%s%s%s%s :\n  %s;"
    (if modifiers_str <> "" then modifiers_str ^ " " else "")
    rule.name
    returns_str
    locals_str
    alternatives_str


let string_of_option_decl (opt : option_decl) =
  Printf.sprintf "options {%s = %s;}\n" opt.name opt.value

let string_of_tokens_spec (tokens : tokens_spec) =
  Printf.sprintf "tokens {%s%s;}\n" tokens.name
    (match tokens.type_ with
     | Some t -> ":" ^ t
     | None -> ": No type specified")

(* let string_of_grammar_type = function
  | Parser -> "parser"
  | Lexer -> "lexer"
  | Combined -> "combined" *)

let convert_grammar_to_string grammar =
  let options_str = String.concat "\n" (List.map string_of_option_decl grammar.options) in
  let tokens_str = String.concat "\n" (List.map string_of_tokens_spec grammar.tokens) in
  let imports_str = String.concat "\n" (List.map (fun i -> "import " ^ i ^ ";") grammar.imports) in
  let channels_str = String.concat "\n" (List.map (fun c -> "channels " ^ c ^ ";") grammar.channels) in
  let rules_str = String.concat "\n" (List.map string_of_rule grammar.rules) in

  Printf.sprintf "grammar %s;\n%s\n%s\n%s\n%s\n%s"
    grammar.name
    options_str
    tokens_str
    imports_str
    channels_str
    rules_str



let run from_opt to_opt input output =
  let from = match from_opt with
    | Some f -> Some f
    | None -> detect_format input
  in
  let result = match from with
  | Some "antlr" ->
      (match From_syntax.parse_file input with
      | Ok grammar ->
          (* Convert the grammar to a string format *)
          let grammar_string = convert_grammar_to_string grammar in
          let oc = open_out output in
          output_string oc grammar_string;
          close_out oc;
          Printf.printf "Output written to %s\n" output;
          Ok ()
      | Error msg ->
          Error (`Msg msg))
  | Some fmt ->
      Error (`Msg (Printf.sprintf "Unsupported input format: %s" fmt))
  | None ->
      Error (`Msg (Printf.sprintf "Could not detect format for file: %s" input))
  in
  match result, to_opt with
  | Ok _, Some fmt ->
      Printf.printf "Target format will be: %s\n" fmt;
      result
  | _ -> result


let cmd =
  let doc = "Convert grammars between different formats" in
  let info = Cmd.info "syntaxe_converter" ~version:"0.1" ~doc in
  Cmd.v info Term.(term_result (const run $ from $ to_ $ input $ output))

let () = exit (Cmd.eval cmd)
