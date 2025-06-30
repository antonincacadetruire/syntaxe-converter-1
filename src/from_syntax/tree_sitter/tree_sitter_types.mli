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
  (* external_functions: external_function list option; *)
  precedences: (string * int) list option;
  word: string option;
  supertypes: string list option;
  scope: string option;
  file_types: string list option;
  injection_regex: string option;
  comments: string list option;
  auto_alias: bool option;
} [@@deriving yojson]


val parse_rules : js_property list -> rule list
val parse_rule_ref : js_value -> symbol
val parse_rule_ref_to_string : js_value -> string
val parse_conflict: js_value -> string list
val parse_precedence : js_value -> (string * int) list
val parse_string : js_value -> string
