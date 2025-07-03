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
  | Property of string * string * js_value
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
  | Choice of symbol list
  | Sequence of symbol list
  | Repeat of symbol
  | Optional of symbol
  | Field of string * symbol
  | Alias of symbol * string
  | Rule of rule
  | FunctionCall  of string * symbol list
[@@deriving yojson]

and rule = {
  name : string;
  args : string;
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
  javascript: string list option;
} [@@deriving yojson]


let rec string_of_js_value (value: js_value) : string =
  match value with
  | String s -> Printf.sprintf "%c%s%c" '"' s '"'
  | Number n -> Printf.sprintf "%d" n
  | Boolean b -> Printf.sprintf "%b" b
  | Null -> "null"
  | Object props ->
      let props_str = String.concat ", " (List.map string_of_js_property props) in
      Printf.sprintf "{%s}" props_str
  | Array values ->
      let values_str = String.concat "; " (List.map string_of_js_value values) in
      Printf.sprintf "[%s]" values_str
  | Identifier s -> Printf.sprintf "Identifier(%c%s%c)" '"' s '"'
  | Function s -> Printf.sprintf "Function(%c%s%c)" '"' s '"'
  | Regex r -> Printf.sprintf "Regex(%c%s%c)" '"' r '"'
  | FunctionCall (name, args) ->
      let args_str = String.concat ", " (List.map string_of_js_value args) in
      Printf.sprintf "FunctionCall(%s, [%s])" name args_str
  | MemberAccess (obj, prop) ->
      Printf.sprintf "MemberAccess(%s, %c%s%c)"  (string_of_js_value obj) '"' prop '"'
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
  | Property (name, args, value) -> Printf.sprintf "%s: %s %s" name args (string_of_js_value value)

and string_of_js_param (param: js_param) : string =
  match param with
  | ParamIdent s -> Printf.sprintf "ParamIdent(%c%s%c)" '"' s '"'
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
  | Comment c -> Printf.sprintf "Comment(%c%s%c)" '"' c '"'
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
  | Property (name, args, value) -> Printf.sprintf "%s: %s %s" name args (string_of_js_value value)

let rec js_value_to_js (value: js_value) : string =
  match value with
  | String s -> Printf.sprintf "%c%s%c" '"' s '"'
  | Number n -> Printf.sprintf "%d" n
  | Boolean b -> Printf.sprintf "%b" b
  | Null -> "null"
  | Object props ->
      let props_js = String.concat ", " (List.map js_property_to_js props) in
      Printf.sprintf "{%s}" props_js
  | Array values ->
      let values_js = String.concat ", " (List.map js_value_to_js values) in
      Printf.sprintf "[%s]" values_js
  | Identifier s -> s
  | Function s -> s
  | Regex r -> Printf.sprintf "/%s/" r
  | FunctionCall (name, args) ->
      let args_js = String.concat ", " (List.map js_value_to_js args) in
      Printf.sprintf "%s(%s)" name args_js
  | MemberAccess (obj, prop) ->
      Printf.sprintf "%s.%s" (js_value_to_js obj) prop
  | FunctionCallExpr (func, args) ->
      let args_js = String.concat ", " (List.map js_value_to_js args) in
      Printf.sprintf "%s(%s)" (js_value_to_js func) args_js
  | Spread value -> Printf.sprintf "...%s" (js_value_to_js value)
  | ArrowFunction (params, body) ->
      let params_js = String.concat ", " (List.map js_param_to_js params) in
      Printf.sprintf "(%s) => %s" params_js (js_value_to_js body)
  | ArrowFunctionBlock (params, block) ->
      let params_js = String.concat ", " (List.map js_param_to_js params) in
      let block_js = String.concat " " (List.map js_statement_to_js block) in
      Printf.sprintf "(%s) => {%s}" params_js block_js
  | Ternary (cond, true_expr, false_expr) ->
      Printf.sprintf "%s ? %s : %s" (js_value_to_js cond) (js_value_to_js true_expr) (js_value_to_js false_expr)
  | Block statements ->
      let statements_js = String.concat " " (List.map js_statement_to_js statements) in
      Printf.sprintf "{%s}" statements_js

and js_property_to_js (prop: js_property) : string =
  match prop with
  | Property (name, args, value) -> Printf.sprintf "%s: %s %s" name args (js_value_to_js value)

and js_param_to_js (param: js_param) : string =
  match param with
  | ParamIdent s -> s
  | ParamArray params ->
      let params_js = String.concat ", " (List.map js_param_to_js params) in
      Printf.sprintf "[%s]" params_js
  | ParamObject fields ->
      let fields_js = String.concat ", " (List.map (fun (name, param) ->
        match param with
        | Some p -> Printf.sprintf "%s: %s" name (js_param_to_js p)
        | None -> Printf.sprintf "%s" name) fields) in
      Printf.sprintf "{%s}" fields_js
  | ParamDefault (param, value) ->
      Printf.sprintf "%s = %s" (js_param_to_js param) (js_value_to_js value)
  | ParamRest param -> Printf.sprintf "...%s" (js_param_to_js param)

and js_statement_to_js (stmt: js_statement) : string =
  match stmt with
  | Comment c -> Printf.sprintf "// %s" c
  | ConstDecl (name, value) -> Printf.sprintf "const %s = %s;" name (js_value_to_js value)
  | LetDecl (name, value) -> Printf.sprintf "let %s = %s;" name (js_value_to_js value)
  | VarDecl (name, value) -> Printf.sprintf "var %s = %s;" name (js_value_to_js value)
  | FunctionDecl (name, params, body) ->
      let params_js = String.concat ", " (List.map js_param_to_js params) in
      let body_js = String.concat " " (List.map js_statement_to_js body) in
      Printf.sprintf "function %s(%s) {%s}" name params_js body_js
  | Return value -> Printf.sprintf "return %s;" (js_value_to_js value)
  | ExprStmt expr -> Printf.sprintf "%s;" (js_value_to_js expr)

let rec parse_element (elem: js_property) : symbol =
  (* Printf.printf "Parsing element: %s\n" (string_of_js_property elem); *)
  let elem_str = string_of_js_property elem in
  match elem with
  | Property(_, _, String s) -> Terminal s
  | Property(_, _, Identifier s) -> NonTerminal s
  | Property(_, _, Regex r) -> Terminal (Printf.sprintf "/%s/" r)
  | Property(_, _, Object nested) -> parse_element (Property("", "", Object nested))
  | Property(_, _, Array elements) ->
      let elements_as_props = List.map (fun e -> Property("", "", e)) elements in
      Choice (List.map parse_element elements_as_props)
  | Property(_, _, FunctionCall("repeat", [arg])) -> Repeat (parse_element (Property("", "", arg)))
  | Property(_, _, FunctionCall("optional", [arg])) -> Optional (parse_element (Property("", "", arg)))
  | Property(_, _, FunctionCall("choice", args)) ->
      let elements_as_props = List.map (fun e -> Property("", "", e)) args in
      Choice (List.map parse_element elements_as_props)
  | Property(_, _, FunctionCall("seq", args)) ->
      let elements_as_props = List.map (fun e -> Property("", "", e)) args in
      Sequence (List.map parse_element elements_as_props)
  | Property(_, _, FunctionCall("alias", [arg; String alias])) ->
      Alias (parse_element (Property("", "", arg)), alias)
  | Property(_, _, FunctionCall("field", [String name; arg])) ->
      Field (name, parse_element (Property("", "", arg)))
  | Property(_, _, FunctionCall("token", [arg])) ->
      parse_element (Property("", "", arg))
  | Property(_, _, FunctionCall("prec", [_; arg])) ->
      parse_element (Property("", "", arg))
  | Property(_, _, FunctionCallExpr(MemberAccess(Identifier "token", "immediate"), [FunctionCall("prec", [_; Regex r])])) ->
      Terminal (Printf.sprintf "/%s/" r)
  | Property(_, _, FunctionCallExpr(MemberAccess(Identifier "prec", _), [prec; seq])) ->
      let prec_sym = parse_element (Property("", "", prec)) in
      let seq_sym = parse_element (Property("", "", seq)) in
      Sequence [prec_sym; seq_sym]
  | Property(_, _, Spread(FunctionCallExpr(MemberAccess(Array operators, "map"),
      [ArrowFunction([ParamArray([ParamIdent _; ParamIdent _])], body)]))) ->
      Choice (List.map (fun op ->
        match op with
        | Array [String _; MemberAccess(Identifier "PREC", prec_level)] ->
            let prec_sym = NonTerminal prec_level in
            let body_sym = parse_element (Property("", "", body)) in
            Sequence [prec_sym; body_sym]
        | _ -> failwith "Invalid operator mapping format"
      ) operators)
  | Property(_, _, ArrowFunction(_, body)) ->
      let body_sym = parse_element (Property("", "", body)) in
      Sequence [Terminal "=>"; body_sym]
  | Property(_, _, FunctionCallExpr(func, args)) ->
      let func_sym = parse_element (Property("", "", func)) in
      let args_syms = List.map (fun arg -> parse_element (Property("", "", arg))) args in
      Sequence (func_sym :: args_syms)
  | Property(_, _, MemberAccess(Identifier _, prop)) ->
      Terminal ("$." ^ prop) (* Preserve the $ prefix *)
  | Property(_, _, MemberAccess(obj, prop)) ->
      let obj_sym = parse_element (Property("", "", obj)) in
      Sequence [obj_sym; Terminal ("$." ^ prop)] (* Preserve the $ prefix *)
  | Property(_, _, FunctionCall(name, args)) ->
      let args_syms = List.map (fun arg -> parse_element (Property("", "", arg))) args in
      FunctionCall (name, args_syms)
  | Property(_, _, Number n) -> 
      Terminal (string_of_int n)
  
  | Property(_, _, Spread(FunctionCallExpr(MemberAccess(Array operators, "map"),
      [ArrowFunction([ParamArray(_)], body)]))) ->
      
      (* Parse individual operator definitions *)
      let parse_operator = function
        | Array [String op; String prec] -> (op, prec, "left")
        | Array [String op; String prec; String assoc] -> (op, prec, assoc)
        | _ -> failwith "Invalid operator format"
      in
      
      (* Create symbol for each operator *)
      let operator_symbols = List.map (fun op ->
        let (op_str, prec_name, assoc) = parse_operator op in
        (* Create the full operator rule structure *)
        Sequence [
          Terminal op_str;
          NonTerminal prec_name;
          Terminal assoc;
          (* Parse the rule body *)
          parse_element (Property("", "", body))
        ]
      ) operators in
      
      Choice operator_symbols
  |  Property(_, _, Ternary(cond, true_expr, false_expr)) ->
      let cond_sym = parse_element (Property("", "", cond)) in
      let true_sym = parse_element (Property("", "", true_expr)) in
      let false_sym = parse_element (Property("", "", false_expr)) in
      Sequence [cond_sym; Terminal "?"; true_sym; Terminal ":"; false_sym]
  | _ ->
      failwith (Printf.sprintf "Failed to parse grammar element: %s" elem_str)

let parse_alternative (alt: js_property) : symbol =
  match alt with
  | Property(_,_,Object elements) ->
      let elements_as_props = List.map (fun (Property(name,arg, value)) -> Property(name,arg, value)) elements in
      Sequence (List.map parse_element elements_as_props)
  | Property(_,_,Array elements) ->
      let elements_as_props = List.map (fun e -> Property("","", e)) elements in
      Choice (List.map parse_element elements_as_props)
  | Property(_,_,Identifier id) -> NonTerminal id
  | Property(_,_,String s) -> Terminal s
  | Property(_,_,FunctionCall(name, args)) ->
      parse_element (Property("","", FunctionCall(name, args)))
  | _ -> failwith "Unsupported alternative type"

let parse_rules (properties: js_property list) : rule list * string list =
  let javascript = ref [] in
  let rules = List.map (fun prop ->
    match prop with
    | Property(name, args, Object alternatives) ->
        let alternatives_as_props = List.map (fun (Property(name,arg, value)) -> Property(name,arg, value)) alternatives in
        { name; args; production = Choice (List.map parse_alternative alternatives_as_props) }
    | Property(name,args, Array alternatives) ->
        let alternatives_as_props = List.map (fun e -> Property("","", e)) alternatives in
        { name; args; production = Choice (List.map parse_alternative alternatives_as_props) }
    | Property(name,args, FunctionCall("prec", [_; Object alternatives])) ->
        let alternatives_as_props = List.map (fun (Property(name, args, value)) -> Property(name, args, value)) alternatives in
        { name; args; production = Choice (List.map parse_alternative alternatives_as_props) }
    | Property(name, args, FunctionCall("prec", [_; Array alternatives])) ->
        let alternatives_as_props = List.map (fun e -> Property("","", e)) alternatives in
        { name; args; production = Choice (List.map parse_alternative alternatives_as_props) }
    | Property(name, args, FunctionCall(name2, args2)) ->
        { name; args; production = parse_element (Property("","", FunctionCall(name2, args2))) }
    | Property(name, args, FunctionCallExpr(MemberAccess(Identifier "token", "immediate"), args2)) ->
        { name; args; production = parse_element (Property("","", FunctionCallExpr(MemberAccess(Identifier "token", "immediate"), args2))) }
    | Property(name, args, Spread(value)) ->
        { name; args; production = parse_element (Property("","", value)) }
    | Property(name, args, String s) -> 
        { name; args; production = Terminal s }
    | Property(name, args, Boolean true) ->
        { name; args; production = Terminal "true" }
    | Property(name, args, Boolean false) ->
        { name; args; production = Terminal "false" }
    | Property(name, args, Null) ->
        { name; args; production = Terminal "null" }
    | Property(name, args, Regex r) ->
        { name; args; production = Terminal (Printf.sprintf "/%s/" r) }
    | Property(name, args, FunctionCallExpr(MemberAccess(Identifier "prec", assoc), args2)) ->
        { name; args; production = parse_element (Property("","", FunctionCallExpr(MemberAccess(Identifier "prec", assoc), args2)) )}
    | Property(name, args, ArrowFunctionBlock(params, block)) ->
        let js_impl = 
          Printf.sprintf "function %s(%s) {%s}" 
            name
            (String.concat ", " (List.map js_param_to_js params))
            (String.concat "" (List.map js_statement_to_js block))
        in
        (* Printf.printf "DEBUG: Generated JS implementation:\n%s\n" js_impl; *)
        javascript := js_impl :: !javascript;
        { name; args; production = NonTerminal name }
    | Property(name, args, ArrowFunction(params, body)) ->
        let js_code = Printf.sprintf "(%s) => %s" 
          (String.concat ", " (List.map js_param_to_js params))
          (js_value_to_js body) in
        javascript := js_code :: !javascript;
        { name; args; production = NonTerminal name }
    | Property(name, args, value) ->
        failwith (Printf.sprintf "Unsupported property type '%s' in rule '%s' with args %s Expected an object, array, or supported function call."
            (string_of_js_value value) name args)
  ) properties in
    (* Printf.printf "DEBUG: Collected %d JavaScript implementations\n" (List.length !javascript); *)
  (rules, !javascript)


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
        | Object [Property (_,_, inner_value)] -> parse_rule_ref_to_string inner_value
        | Identifier s -> parse_rule_ref_to_string (Identifier s)
        | _ ->
            let ref_str = string_of_js_value ref_value in
            failwith (Printf.sprintf "Expected an object or identifier for rule reference, got: %s" ref_str)
      ) refs
  | _ ->
      let value_str = string_of_js_value value in
      failwith (Printf.sprintf "Expected an array of rule references, got: %s" value_str)

let parse_precedence (_ : js_value) = []
let parse_string (_ : js_value) = ""


