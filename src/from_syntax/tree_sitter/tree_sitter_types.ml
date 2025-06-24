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

and js_property =
  | Property of string * js_value

type js_statement =
  | Comment of string
  | ConstDecl of string * js_value
  | LetDecl of string * js_value
  | VarDecl of string * js_value

type location = {
  line: int;
  column: int;
}

type modifier =
  | Fragment
  | Public
  | Private

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

and suffix =
  | Optional
  | ZeroOrMore
  | OneOrMore
  | ZeroOrMoreNonGreedy
  | OneOrMoreNonGreedy
  | OptionalNonGreedy

type alternative = {
  predicate: string option;
  elements: element list;
  command: string option;
}

type rule = {
  name: string;
  modifiers: modifier list;
  returns: string list;
  locals: string option;
  alternatives: alternative list;
  location: location;
}

type option_decl = {
  name: string;
  value: string;
}

type tokens_spec = {
  name: string;
  type_: string option;
}

type grammar = {
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
}

(* Helper stubs for Menhir parser - to be implemented properly *)
let parse_rules (_ : js_property list) = []
let parse_rule_ref = function
  | Identifier s -> s
  | Regex r -> "/" ^ r ^ "/"
  | _ -> failwith "Unsupported rule reference in extras"let parse_conflict (_ : js_value) = []
let parse_precedence (_ : js_value) = []
let parse_string (_ : js_value) = ""
