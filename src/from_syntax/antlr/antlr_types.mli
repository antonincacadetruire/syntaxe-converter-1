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

and suffix =
  | Optional      (* ? *)
  | ZeroOrMore   (* * *)
  | OneOrMore    (* + *)

type alternative = {
  predicate: string option;
  elements: element list;
}

type rule = {
  name: string;
  modifiers: modifier list;
  returns: string list; (* Updated from string option to string list *)
  locals: string option;
  alternatives: alternative list;
  location: location;
}

type grammar_type =
  | Parser
  | Lexer
  | Combined

type option_decl = {
  name: string;
  value: string;
}

type tokens_spec = {
  name: string;
  type_: string option;
}

type mode_section = {
  mode_name: string;
  mode_rules: rule list;
}

type grammar = {
  name: string;
  type_: grammar_type;
  options: option_decl list;
  tokens: tokens_spec list;
  imports: string list;
  channels: string list;
  rules: rule list;
}