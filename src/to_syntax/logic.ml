open To_syntax_antlr
open Antlr

let log_json grammar format_type =
  match format_type with
  | "ANTLR" -> (log_json_antlr grammar)
  | "TREESITTER" -> Error (`Msg (Printf.sprintf "Implementation not done")) (* (log_json_tree_sitter grammar)*)
  | _ -> Error (`Msg (Printf.sprintf "Unsupported format"))
