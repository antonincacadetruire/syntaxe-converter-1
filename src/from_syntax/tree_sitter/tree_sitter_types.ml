type js_value =
  | String of string
  | Number of int
  | Boolean of bool
  | Null
  | Object of js_property list
  | Array of js_value list
  | Identifier of string
  | Function of string
  | Regex of string
  | FunctionCall of string * js_value list
  | MemberAccess of js_value * string
  | FunctionCallExpr of js_value * js_value list
  | Spread of js_value
  | ArrowFunction of js_param list * js_value
  | ArrowFunctionBlock of js_param list * js_block
  | Ternary of js_value * js_value * js_value
  | Block of js_block
[@@deriving yojson]

and js_block = js_statement list
[@@deriving yojson]
and js_param =
  | ParamIdent of string
  | ParamArray of js_param list
  | ParamObject of (string * js_param option) list
  | ParamDefault of js_param * js_value
  | ParamRest of js_param
[@@deriving yojson]
and js_property =
  | Property of string * js_value
[@@deriving yojson]
and js_statement =
  | Comment of string
  | ConstDecl of string * js_value
  | LetDecl of string * js_value
  | VarDecl of string * js_value
  | FunctionDecl of string * js_param list * js_statement list
  | Return of js_value
  | ExprStmt of js_value
[@@deriving yojson]
type location = {
  line: int;
  column: int;
} [@@deriving yojson]

type modifier =
  | Fragment
  | Public
  | Private
[@@deriving yojson]

type element =
  | Terminal of string
  | NonTerminal of string
  | Action of string
  | SemanticPredicate of string
  | Label of string * element
  | Ebnf of element * suffix
  | Group of element list
  | CharacterClass of string
  | Wildcard
[@@deriving yojson]

and suffix =
  | Optional
  | ZeroOrMore
  | OneOrMore
  | ZeroOrMoreNonGreedy
  | OneOrMoreNonGreedy
  | OptionalNonGreedy
[@@deriving yojson]

type alternative = {
  predicate: string option;
  elements: element list;
  command: string option;
} [@@deriving yojson]

type rule = {
  name: string;
  modifiers: modifier list;
  returns: string list;
  locals: string option;
  alternatives: alternative list;
  location: location;
} [@@deriving yojson]

type option_decl = {
  name: string;
  value: string;
} [@@deriving yojson]

type tokens_spec = {
  name: string;
  type_: string option;
} [@@deriving yojson]

type grammarTS = {
  name: string;
  rules: rule list;
  tokens: tokens_spec list;
  extras: string list option;
  conflicts: string list list option;
  inline: string list option;
  externals: string list option;
  precedences: (string * int) list option;
  word: string option;
  supertypes: string list option;
  scope: string option;
  file_types: string list option;
  injection_regex: string option;
  comments: string list option;
  auto_alias: bool option;
} [@@deriving yojson]


let rec string_of_js_value (value: js_value) : string =
  match value with
  | String s -> Printf.sprintf "\"%s\"" s
  | Number n -> Printf.sprintf "%d" n
  | Boolean b -> Printf.sprintf "%b" b
  | Null -> "null"
  | Object props ->
      let props_str = String.concat ", " (List.map string_of_js_property props) in
      Printf.sprintf "{%s}" props_str
  | Array values ->
      let values_str = String.concat "; " (List.map string_of_js_value values) in
      Printf.sprintf "[%s]" values_str
  | Identifier s -> Printf.sprintf "Identifier(\"%s\")" s
  | Function s -> Printf.sprintf "Function(\"%s\")" s
  | Regex r -> Printf.sprintf "Regex(\"%s\")" r
  | FunctionCall (name, args) ->
      let args_str = String.concat ", " (List.map string_of_js_value args) in
      Printf.sprintf "FunctionCall(%s, [%s])" name args_str
  | MemberAccess (obj, prop) ->
      Printf.sprintf "MemberAccess(%s, \"%s\")" (string_of_js_value obj) prop
  | FunctionCallExpr (func, args) ->
      let args_str = String.concat ", " (List.map string_of_js_value args) in
      Printf.sprintf "FunctionCallExpr(%s, [%s])" (string_of_js_value func) args_str
  | Spread value -> Printf.sprintf "Spread(%s)" (string_of_js_value value)
  | ArrowFunction (params, body) ->
      let params_str = String.concat ", " (List.map string_of_js_param params) in
      Printf.sprintf "ArrowFunction([%s], %s)" params_str (string_of_js_value body)
  | ArrowFunctionBlock (params, block) ->
      let params_str = String.concat ", " (List.map string_of_js_param params) in
      let block_str = String.concat "; " (List.map string_of_js_statement block) in
      Printf.sprintf "ArrowFunctionBlock([%s], {%s})" params_str block_str
  | Ternary (cond, true_expr, false_expr) ->
      Printf.sprintf "Ternary(%s, %s, %s)" (string_of_js_value cond) (string_of_js_value true_expr) (string_of_js_value false_expr)
  | Block statements ->
      let statements_str = String.concat "; " (List.map string_of_js_statement statements) in
      Printf.sprintf "Block({%s})" statements_str

and string_of_js_property (prop: js_property) : string =
  match prop with
  | Property (name, value) -> Printf.sprintf "%s: %s" name (string_of_js_value value)

and string_of_js_param (param: js_param) : string =
  match param with
  | ParamIdent s -> Printf.sprintf "ParamIdent(\"%s\")" s
  | ParamArray params ->
      let params_str = String.concat ", " (List.map string_of_js_param params) in
      Printf.sprintf "ParamArray([%s])" params_str
  | ParamObject fields ->
      let fields_str = String.concat ", " (List.map (fun (name, param) ->
        match param with
        | Some p -> Printf.sprintf "%s: %s" name (string_of_js_param p)
        | None -> Printf.sprintf "%s: null" name) fields) in
      Printf.sprintf "ParamObject({%s})" fields_str
  | ParamDefault (param, value) ->
      Printf.sprintf "ParamDefault(%s, %s)" (string_of_js_param param) (string_of_js_value value)
  | ParamRest param -> Printf.sprintf "ParamRest(%s)" (string_of_js_param param)

and string_of_js_statement (stmt: js_statement) : string =
  match stmt with
  | Comment c -> Printf.sprintf "Comment(\"%s\")" c
  | ConstDecl (name, value) -> Printf.sprintf "ConstDecl(%s, %s)" name (string_of_js_value value)
  | LetDecl (name, value) -> Printf.sprintf "LetDecl(%s, %s)" name (string_of_js_value value)
  | VarDecl (name, value) -> Printf.sprintf "VarDecl(%s, %s)" name (string_of_js_value value)
  | FunctionDecl (name, params, body) ->
      let params_str = String.concat ", " (List.map string_of_js_param params) in
      let body_str = String.concat "; " (List.map string_of_js_statement body) in
      Printf.sprintf "FunctionDecl(%s, [%s], {%s})" name params_str body_str
  | Return value -> Printf.sprintf "Return(%s)" (string_of_js_value value)
  | ExprStmt expr -> Printf.sprintf "ExprStmt(%s)" (string_of_js_value expr)

  let parse_rules (properties: js_property list) : rule list =
  List.map (fun prop ->
    match prop with
    | Property(name, _) ->
        Printf.printf "Warning: Unsupported property %s in rules\n" name;
        { name = name; modifiers = []; returns = []; locals = None; alternatives = []; location = { line = 0; column = 0 } }
  ) properties

let parse_rule_ref = function
  | Identifier s -> "$."^s
  | String s -> s
  | Regex r -> "/" ^ r ^ "/"
  | Boolean true -> "true"
  | Boolean false -> "false"
  | Null -> "null"
  | _ -> failwith "Unsupported rule reference in extras"

let parse_conflict (value: js_value) : string list =
  match value with
  | Array refs ->
      List.map (fun ref_value ->
        match ref_value with
        | Object [Property (_, inner_value)] ->
            parse_rule_ref inner_value
        | Identifier s ->
            parse_rule_ref (Identifier s)
        | _ ->
            let ref_str = string_of_js_value ref_value in
            failwith (Printf.sprintf "Expected an object or identifier for rule reference, got: %s" ref_str)
      ) refs
  | _ ->
      let value_str = string_of_js_value value in
      failwith (Printf.sprintf "Expected an array of rule references, got: %s" value_str)


  
let parse_precedence (_ : js_value) = []
let parse_string (_ : js_value) = ""