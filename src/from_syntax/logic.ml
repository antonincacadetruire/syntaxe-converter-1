open From_syntax_antlr
open Antlr_types

type grammar_type =
  | ANTLR
  | Unsupported

let detect_grammar_type filename =
  match Filename.extension filename with
  | ".g4" -> ANTLR
  | _ -> Unsupported

let parse_antlr_file filename =
  let ic = open_in filename in
  let src = really_input_string ic (in_channel_length ic) in
  close_in ic;
  try
    let lexbuf = Lexing.from_string src in
    lexbuf.lex_curr_p <- { lexbuf.lex_curr_p with pos_fname = filename };
    let grammar = Antlr_parser.main Antlr_lexer.token lexbuf in
    Ok grammar
  with e ->
    Error (Printexc.to_string e)

let parse_file filename =
  let result = match detect_grammar_type filename with
  | ANTLR -> 
      (match parse_antlr_file filename with
      | Ok grammar -> 
          Printf.printf "Successfully parsed ANTLR grammar file: %s\n" filename;
          Printf.printf "Found %d rules:\n" (List.length grammar);
          List.iter (fun rule ->
            Printf.printf "  Rule: %s -> %s\n" rule.name rule.definition
          ) grammar;
          Ok grammar
      | Error msg ->
          Printf.eprintf "Failed to parse ANTLR grammar: %s\n" msg;
          Error msg)
  | Unsupported ->
      let msg = Printf.sprintf "Unsupported file type: %s\n  Supported types:\n  .g4 (ANTLR)\n" 
        (Filename.extension filename) in
      Printf.eprintf "%s" msg;
      Error msg
  in
  match result with
  | Ok _ -> ()
  | Error _ -> ()

let () =
  if Array.length Sys.argv < 2 then (
    prerr_endline "Usage: syntaxe-converter <grammar-file>";
    prerr_endline "Supported file types:";
    prerr_endline "  .g4 (ANTLR)";
    exit 1
  );
  let filename = Sys.argv.(1) in
  parse_file filename
