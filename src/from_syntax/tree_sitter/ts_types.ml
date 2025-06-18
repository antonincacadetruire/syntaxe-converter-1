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
  | Wildcard  (* . *)
[@@deriving yojson]

and suffix =
  | Optional      (* ? *)
  | ZeroOrMore   (* * *)
  | OneOrMore    (* + *)
  | ZeroOrMoreNonGreedy (* *? *)
  | OneOrMoreNonGreedy (* +? *)
  | OptionalNonGreedy (* ?? *)
[@@deriving yojson]

type alternative = {
  predicate: string option;
  elements: element list;
  command: string option;
} [@@deriving yojson]

type rule = {
  name: string;
  modifiers: modifier list;
  returns: string list; (* Updated from string option to string list *)
  locals: string option;
  alternatives: alternative list;
  location: location;
} [@@deriving yojson]

type tokens_spec = {
  name: string;
  type_: string option;
} [@@deriving yojson]

type mode_section = {
  mode_name: string;
  mode_rules: rule list;
} [@@deriving yojson]

type reservation = {
  reserved_words: string list;
  reserved_rules: rule list;
} [@@deriving yojson]

type grammar = {
  name : string;
  tokens : tokens_spec list;
  imports : string list;
  channels : string list;
  rules : rule list;
  extras : string; (* à modifier *) 
  inline : rule list;
  conflicts : rule list list;
  externals : tokens_spec list;
  precedences : string list list;
  word: tokens_spec;
  supertypes: rule list;
  reserved: reservation;
} [@@deriving yojson]