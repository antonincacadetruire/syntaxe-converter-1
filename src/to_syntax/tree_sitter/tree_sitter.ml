open From_syntax_tree_sitter
open Tree_sitter_types

let rec string_of_js_value = function
  | String s -> Printf.sprintf "\"%s\"" s
  | Number n -> string_of_int n
  | Boolean true -> "true"
  | Boolean false -> "false"
  | Null -> "null"
  | Object props ->
      let props_str =
        props
        |> List.map (function Property (k, a, v) -> Printf.sprintf "%s: %s %s" (Printf.sprintf "\"%s\"" k) (Printf.sprintf "\"%s\"" a) (string_of_js_value v))
        |> String.concat ", "
      in
      Printf.sprintf "{ %s }" props_str
  | Array vs ->
      Printf.sprintf "[ %s ]" (String.concat ", " (List.map string_of_js_value vs))
  | Identifier s -> Printf.sprintf "$.%s" s
  | Function s -> Printf.sprintf "%s" s
  | Regex r -> Printf.sprintf "/%s/" r
  | FunctionCall (name, args) -> Printf.sprintf "%s(%s)" name (String.concat ", " (List.map string_of_js_value args))
  | MemberAccess (obj, prop) -> Printf.sprintf "%s.%s" (string_of_js_value obj) prop
  | FunctionCallExpr (fn, args) -> Printf.sprintf "%s(%s)" (string_of_js_value fn) (String.concat ", " (List.map string_of_js_value args))
  | Spread v -> Printf.sprintf "...%s" (string_of_js_value v)
  | ArrowFunction (params, body) ->
      let params_str = String.concat ", " (List.map string_of_js_param params) in
      Printf.sprintf "(%s) => %s" params_str (string_of_js_value body)
  | ArrowFunctionBlock (params, block) ->
      let params_str = String.concat ", " (List.map string_of_js_param params) in
      Printf.sprintf "(%s) => { %s }" params_str (string_of_js_block block)
  | Ternary (a, b, c) -> Printf.sprintf "%s ? %s : %s" (string_of_js_value a) (string_of_js_value b) (string_of_js_value c)
  | Block b -> string_of_js_block b
and string_of_js_param = function
  | ParamIdent s -> s
  | ParamArray ps -> Printf.sprintf "[ %s ]" (String.concat ", " (List.map string_of_js_param ps))
  | ParamObject kvs ->
      let kvs_str =
        kvs |> List.map (fun (k, v) -> match v with Some v -> Printf.sprintf "%s: %s" k (string_of_js_param v) | None -> k)
        |> String.concat ", "
      in Printf.sprintf "{ %s }" kvs_str
  | ParamDefault (p, v) -> Printf.sprintf "%s = %s" (string_of_js_param p) (string_of_js_value v)
  | ParamRest p -> Printf.sprintf "...%s" (string_of_js_param p)
and string_of_js_block stmts =
  String.concat "; " (List.map string_of_js_statement stmts)
and string_of_js_statement = function
  | Comment s -> Printf.sprintf "// %s" s
  | ConstDecl (n, v) -> Printf.sprintf "const %s = %s;" n (string_of_js_value v)
  | LetDecl (n, v) -> Printf.sprintf "let %s = %s;" n (string_of_js_value v)
  | VarDecl (n, v) -> Printf.sprintf "var %s = %s;" n (string_of_js_value v)
  | FunctionDecl (n, params, body) ->
      let params_str = String.concat ", " (List.map string_of_js_param params) in
      let body_str = String.concat "; " (List.map string_of_js_statement body) in
      Printf.sprintf "function %s(%s) { %s }" n params_str body_str
  | Return v -> Printf.sprintf "return %s;" (string_of_js_value v)
  | ExprStmt v -> Printf.sprintf "%s;" (string_of_js_value v)

let string_of_rule (r : rule) =
  Printf.sprintf "    %s: ..., // rule omitted for brevity\n" r.name

let convert_grammar_to_string_tree_sitter (grammar : grammarTS) =
  let opt_field_list name = function
    | Some vs when vs <> [] ->
        Printf.sprintf "  %s: [%s],\n" name (String.concat ", " (List.map (fun s -> Printf.sprintf "\"%s\"" s) vs))
    | _ -> ""
  in
  let opt_field_listlist name = function
    | Some vss when vss <> [] ->
        let inner = List.map (fun vs -> "[" ^ String.concat ", " (List.map (fun s -> Printf.sprintf "\"%s\"" s) vs) ^ "]") vss in
        Printf.sprintf "  %s: [%s],\n" name (String.concat ", " inner)
    | _ -> ""
  in
  let opt_field_assoc name = function
    | Some vs when vs <> [] ->
        Printf.sprintf "  %s: [%s],\n" name (String.concat ", " (List.map (fun (s, i) -> Printf.sprintf "[\"%s\", %d]" s i) vs))
    | _ -> ""
  in
  let opt_field_bool name = function
    | Some true -> Printf.sprintf "  %s: true,\n" name
    | Some false -> Printf.sprintf "  %s: false,\n" name
    | None -> ""
  in
  let opt_field_str name = function
    | Some s -> Printf.sprintf "  %s: \"%s\",\n" name s
    | None -> ""
  in
  let rules_str =
    Printf.sprintf "  rules: {\n%s  },\n"
      (String.concat ""
         (List.map string_of_rule grammar.rules))
  in
Printf.sprintf "module.exports = grammar({\n  name: \"%s\",\n%s%s%s%s%s%s%s%s%s%s%s%s%s})"
    grammar.name
    rules_str
    (opt_field_list "extras" grammar.extras)
    (opt_field_listlist "conflicts" grammar.conflicts)
    (opt_field_list "inline" grammar.inline)
    (opt_field_list "externals" grammar.externals)
    (opt_field_assoc "precedences" grammar.precedences)
    (opt_field_str "word" grammar.word)
    (opt_field_list "supertypes" grammar.supertypes)
    (opt_field_str "scope" grammar.scope)
    (opt_field_list "fileTypes" grammar.file_types)
    (opt_field_str "injectionRegex" grammar.injection_regex)
    (opt_field_list "comments" grammar.comments)
    (opt_field_bool "autoAlias" grammar.auto_alias)


let log_json_tree_sitter grammar =
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
    let json = Yojson.Safe.to_string (grammarTS_to_yojson grammar) in
    output_string oc json;
    close_out oc;
    Printf.printf "Log written to %s\n" log_path;
    Ok (log_path)
  with e ->
    Error (`Msg (Printf.sprintf "Failed to write log: %s" (Printexc.to_string e)))