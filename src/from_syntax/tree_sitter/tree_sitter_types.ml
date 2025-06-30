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

type symbol =
  | Terminal of string
  | NonTerminal of string
  (* | ExternalCall of string * symbol list *)
  | Choice of symbol list
  | Sequence of symbol list
  | Repeat of symbol
  | Optional of symbol
  | Field of string * symbol
  | Alias of symbol * string
  | Rule of rule (* Add this line to include nested rules *)
[@@deriving yojson]

and rule = {
  name : string;
  production : symbol;
} [@@deriving yojson]


type option_decl = {
  name: string;
  value: string;
} [@@deriving yojson]

type tokens_spec = {
  name: string;
  type_: string option;
} [@@deriving yojson]

type external_function = {
  name: string;
  params: string list;
  js_body: string option;  (* Optional JavaScript source *)
} [@@deriving yojson]

type grammarTS = {
  name: string;
  rules: rule list;
  tokens: tokens_spec list;
  extras: string list option;
  conflicts: string list list option;
  inline: string list option;
  externals: string list option;
  (* external_functions: external_function list option;*)
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

let string_of_js_property (prop: js_property) : string =
  match prop with
  | Property (name, value) -> Printf.sprintf "%s: %s" name (string_of_js_value value)

let rec parse_element (elem: js_property) : symbol =
  let elem_str = string_of_js_property elem in
  match elem with
  | Property(_, String s) -> Terminal s
  | Property(_, Identifier s) -> NonTerminal s
  | Property(_, Regex r) -> Terminal (Printf.sprintf "/%s/" r)
  | Property(_, Object nested) -> parse_element (Property("", Object nested))
  | Property(_, Array elements) -> 
      let elements_as_props = List.map (fun e -> Property("", e)) elements in
      Choice (List.map parse_element elements_as_props)
  | Property(_, FunctionCall("repeat", [arg])) -> Repeat (parse_element (Property("", arg)))
  | Property(_, FunctionCall("optional", [arg])) -> Optional (parse_element (Property("", arg)))
  | Property(_, FunctionCall("choice", args)) ->
      let elements_as_props = List.map (fun e -> Property("", e)) args in
      Choice (List.map parse_element elements_as_props)
  | Property(_, FunctionCall("seq", args)) ->
      let elements_as_props = List.map (fun e -> Property("", e)) args in
      Sequence (List.map parse_element elements_as_props)
  | Property(_, FunctionCall("alias", [arg; String alias])) -> 
      Alias (parse_element (Property("", arg)), alias)
  | Property(_, FunctionCall("field", [String name; arg])) -> 
      Field (name, parse_element (Property("", arg)))
  | Property(_, FunctionCall("token", [arg])) ->
      parse_element (Property("", arg))
  | Property(_, FunctionCall("prec", [_; arg])) ->
      parse_element (Property("", arg))
  | Property(_, FunctionCallExpr(MemberAccess(Identifier "token", "immediate"), [FunctionCall("prec", [_; Regex r])])) ->
      (* Handle token.immediate(prec(1, /.../)) pattern *)
      Terminal (Printf.sprintf "/%s/" r)
  | Property(_, FunctionCallExpr(MemberAccess(Identifier "prec", _), [prec; seq])) ->
      (* Handle prec.right(PREC.ASSIGN, seq(...)) pattern *)
      let prec_sym = parse_element (Property("", prec)) in
      let seq_sym = parse_element (Property("", seq)) in
      Sequence [prec_sym; seq_sym]
  | Property(_, Spread(FunctionCallExpr(MemberAccess(Array operators, "map"), 
      [ArrowFunction([ParamArray([ParamIdent _; ParamIdent _])], body)]))) ->
      (* Handle spread of mapped operators pattern *)
      Choice (List.map (fun op -> 
        match op with
        | Array [String _; MemberAccess(Identifier "PREC", prec_level)] ->
            let prec_sym = NonTerminal prec_level in
            let body_sym = parse_element (Property("", body)) in
            Sequence [prec_sym; body_sym]
        | _ -> failwith "Invalid operator mapping format"
      ) operators)
  | Property(_, ArrowFunction(_, body)) ->
      (* Handle arrow function patterns *)
      let body_sym = parse_element (Property("", body)) in
      Sequence [Terminal "=>"; body_sym]
  | Property(_, FunctionCallExpr(func, args)) ->
      (* Handle general function call expressions *)
      let func_sym = parse_element (Property("", func)) in
      let args_syms = List.map (fun arg -> parse_element (Property("", arg))) args in
      Sequence (func_sym :: args_syms)
  | Property(_, MemberAccess(Identifier _, prop)) ->
      (* Handle simple member access *)
      Terminal prop
  | Property(_, MemberAccess(obj, prop)) ->
      (* Handle complex member access *)
      let obj_sym = parse_element (Property("", obj)) in
      Sequence [obj_sym; Terminal prop]
  | Property(_, FunctionCall(_, args)) ->
      (* General function call fallback *)
      let args_as_props = List.map (fun arg -> Property("", arg)) args in
      Sequence (List.map parse_element args_as_props)
  | _ -> 
      failwith (Printf.sprintf "Failed to parse grammar element: %s" elem_str)

let parse_alternative (alt: js_property) : symbol =
  match alt with
  | Property(_, Object elements) ->
      let elements_as_props = List.map (fun (Property(name, value)) -> Property(name, value)) elements in
      Sequence (List.map parse_element elements_as_props)
  | Property(_, Array elements) ->
      let elements_as_props = List.map (fun e -> Property("", e)) elements in
      Choice (List.map parse_element elements_as_props)
  | Property(_, Identifier id) -> NonTerminal id
  | Property(_, String s) -> Terminal s
  | Property(_, FunctionCall(name, args)) ->
      parse_element (Property("", FunctionCall(name, args)))
  | _ -> failwith "Unsupported alternative type"

let parse_rules (properties: js_property list) : rule list =
  List.map (fun prop ->
    match prop with
    | Property(name, Object alternatives) ->
        let alternatives_as_props = List.map (fun (Property(name, value)) -> Property(name, value)) alternatives in
        { name; production = Choice (List.map parse_alternative alternatives_as_props) }
    | Property(name, Array alternatives) ->
        let alternatives_as_props = List.map (fun e -> Property("", e)) alternatives in
        { name; production = Choice (List.map parse_alternative alternatives_as_props) }
    | Property(name, FunctionCall("prec", [_; Object alternatives])) ->
        let alternatives_as_props = List.map (fun (Property(name, value)) -> Property(name, value)) alternatives in
        { name; production = Choice (List.map parse_alternative alternatives_as_props) }
    | Property(name, FunctionCall("prec", [_; Array alternatives])) ->
        let alternatives_as_props = List.map (fun e -> Property("", e)) alternatives in
        { name; production = Choice (List.map parse_alternative alternatives_as_props) }
    | Property(name, FunctionCall(name2, args)) ->
        (* Handle direct function calls as rules *)
        { name; production = parse_element (Property("", FunctionCall(name2, args))) }
    | Property(name, FunctionCallExpr(MemberAccess(Identifier "token", "immediate"), args)) ->
        (* Handle token.immediate(...) as a top-level rule *)
        { name; production = parse_element (Property("", FunctionCallExpr(MemberAccess(Identifier "token", "immediate"), args))) }
    | Property(name, Spread(value)) ->
        (* Handle spread operator patterns *)
        { name; production = parse_element (Property("", value)) }
    | Property(name, String s) ->  (* Handle direct string values *)
        { name; production = Terminal s }
    | Property(name, Boolean true) ->  (* Handle boolean true *)
        { name; production = Terminal "true" }
    | Property(name, Boolean false) ->  (* Handle boolean false *)
        { name; production = Terminal "false" }
    | Property(name, Null) ->  (* Handle null *)
        { name; production = Terminal "null" }
    | Property(name, Regex r) ->  (* Handle regex patterns *)
        { name; production = Terminal (Printf.sprintf "/%s/" r) }
    | Property(name, FunctionCallExpr(MemberAccess(Identifier "prec", assoc), args)) ->
        (* Handle prec.right(...) as a top-level rule *)
        { name; production = parse_element (Property("", FunctionCallExpr(MemberAccess(Identifier "prec", assoc), args)) )}
    | Property(name, value) ->
        failwith (Printf.sprintf "Unsupported property type '%s' in rule '%s'. Expected an object, array, or supported function call."
            (string_of_js_value value) name)
  ) properties


let parse_rule_ref = function
  | Identifier s -> NonTerminal s
  | String s -> Terminal s
  | Regex r -> Terminal ("/" ^ r ^ "/")
  | Boolean true -> Terminal "true"
  | Boolean false -> Terminal "false"
  | Null -> Terminal "null"
  | _ -> failwith "Unsupported rule reference"

let parse_rule_ref_to_string = function
  | Identifier s -> "$." ^ s
  | String s -> s
  | Regex r -> "/" ^ r ^ "/"
  | Boolean true -> "true"
  | Boolean false -> "false"
  | Null -> "null"
  | _ -> failwith "Unsupported rule reference in conflicts"

let parse_conflict (value: js_value) : string list =
  match value with
  | Array refs ->
      List.map (fun ref_value ->
        match ref_value with
        | Object [Property (_, inner_value)] -> parse_rule_ref_to_string inner_value
        | Identifier s -> parse_rule_ref_to_string (Identifier s)
        | _ ->
            let ref_str = string_of_js_value ref_value in
            failwith (Printf.sprintf "Expected an object or identifier for rule reference, got: %s" ref_str)
      ) refs
  | _ ->
      let value_str = string_of_js_value value in
      failwith (Printf.sprintf "Expected an array of rule references, got: %s" value_str)

(* let extract_js_body (body: js_statement list) : string option =
  (* Implement this based on how you want to store JS source *)
  Some (String.concat "\n" (List.map string_of_js_statement body)) *)

(* let parse_external_function (stmt: js_statement) : external_function option =
  match stmt with
  | FunctionDecl(name, params, body) ->
      let param_names = List.filter_map (function
        | ParamIdent s -> Some s
        | _ -> None
      ) params in
      Some {
        name;
        params = param_names;
        js_body = extract_js_body body
      }
  | _ -> None *)

let parse_precedence (_ : js_value) = []
let parse_string (_ : js_value) = ""