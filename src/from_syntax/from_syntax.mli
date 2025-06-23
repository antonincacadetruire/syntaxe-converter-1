type any_grammar =
  | Antlr of From_syntax_antlr.Antlr_types.grammar
  | TreeSitter of From_syntax_tree_sitter.Tree_sitter_types.grammar

val parse_file : string -> (any_grammar, string) result
