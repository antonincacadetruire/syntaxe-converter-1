type grammarType =
  | AntlrGrammar of From_syntax_antlr.Antlr_types.grammar
  | TreeSitterGrammar of From_syntax_tree_sitter.Tree_sitter_types.grammarTS

val log_json : grammarType -> (string, [> `Msg of string]) result