open From_syntax_antlr
open Antlr_types

let string_of_modifiers = function
  | Fragment -> "fragment"
  | Public -> "public"
  | Private -> "private"

let antlr_escape s =
  let buf = Buffer.create (String.length s) in
  String.iter (function
    | '\'' -> Buffer.add_string buf "\\'"
    | '\"' -> Buffer.add_string buf "\""
    | '\\' -> Buffer.add_string buf "\\\\"
    | c -> Buffer.add_char buf c
  ) s;
  Buffer.contents buf

let rec string_of_element = function
  | Terminal s -> "'" ^ antlr_escape s ^ "'"
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

let convert_grammar_to_string_antlr (grammar:grammar) =
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

let log_json_antlr grammar =
  let log_dir = "logs" in
  let date = Unix.localtime (Unix.time ()) in
  let log_path = Printf.sprintf "%s/%04d-%02d-%02d-%02d-%02d.json"
    log_dir
    (date.Unix.tm_year + 1900)
    (date.Unix.tm_mon + 1)
    date.Unix.tm_mday
    date.Unix.tm_hour
    date.Unix.tm_min
  in
  try
    let oc = open_out log_path in
    let json = Yojson.Safe.to_string (grammar_to_yojson grammar) in
    output_string oc json;
    close_out oc;
    Printf.printf "Log written to %s\n" log_path;
    Ok (log_path)
  with e ->
    Error (`Msg (Printf.sprintf "Failed to write log: %s" (Printexc.to_string e)))