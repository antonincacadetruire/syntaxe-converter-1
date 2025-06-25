open To_syntax_antlr
open Antlr
open To_syntax_tree_sitter
open Tree_sitter

type grammarType =
  | AntlrGrammar of From_syntax_antlr.Antlr_types.grammar
  | TreeSitterGrammar of From_syntax_tree_sitter.Tree_sitter_types.grammarTS

let log_json (grammar: grammarType) =
  match grammar with
  | AntlrGrammar g -> log_json_antlr g
  | TreeSitterGrammar g -> log_json_tree_sitter g
