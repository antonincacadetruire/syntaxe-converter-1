open Cmdliner
open From_syntax_antlr
open Antlr_types
open To_syntax
open To_syntax_antlr
open Antlr

let from =
  let doc = "Source grammar format (e.g., ebnf, antlr, bison, etc.). If not provided, will be detected from file extension." in
  Arg.(value & opt (some string) None & info ["from"] ~docv:"FORMAT" ~doc)

let to_ =
  let doc = "Target grammar format (e.g., ebnf, antlr, bison, etc.). If not provided, will be detected from file extension." in
  Arg.(value & opt (some string) None & info ["to"] ~docv:"FORMAT" ~doc)

let input =
  let doc = "Input grammar file." in
  Arg.(required & pos 0 (some string) None & info [] ~docv:"INPUT" ~doc)

let output =
  let doc = "Output grammar file." in
  Arg.(required & pos 1 (some string) None & info [] ~docv:"OUTPUT" ~doc)

let detect_format filename =
  match Filename.extension filename with
  | ".g4" -> Some "antlr"
  | ".js" -> Some "treesitter"
  | _ -> None

let ensure_dir_exists dir =
  if Sys.file_exists dir then
    if not (Sys.is_directory dir) then
      failwith (dir ^ " exists but is not a directory")
    else
      ()  (* Directory exists, do nothing *)
  else
    Unix.mkdir dir 0o755

let run from_opt to_opt input output =
  ensure_dir_exists "logs";
  let from = match from_opt with
    | Some f -> Some f
    | None -> detect_format input
  in
  let result = match from with
    | Some "antlr" ->
      (match From_syntax.parse_file input with
      | Ok (Antlr grammar) ->
          let grammar_string = convert_grammar_to_string_antlr grammar in
          let oc = open_out output in
          output_string oc grammar_string;
          close_out oc;
          Printf.printf "Output written to %s\n" output;

          let logPath_result = log_json grammar "ANTLR" in
          let grammarOf_result =
            match logPath_result with
            | Ok logPath ->
                Yojson.Safe.from_file logPath
                |> grammar_of_yojson
            | Error (`Msg msg) -> Error msg
            | Error _ -> Error "Unknown error"
          in
          (match grammarOf_result with
          | Ok grammarOf ->
              let oc = open_out "output2.g4" in
              let grammar_string2 = convert_grammar_to_string_antlr grammarOf in
              output_string oc grammar_string2;
              close_out oc;
              Printf.printf "Output written to %s\n" "output2.g4";
              Ok ()
          | Error msg ->
              Error (`Msg ("Failed to parse JSON: " ^ msg)))
      | Ok (TreeSitter _) ->
          Error (`Msg "Tree-sitter grammar is not supported for this operation")
      | Error msg -> Error (`Msg ("Parsing error: " ^ msg)))
    | Some "treesitter" -> Error (`Msg (Printf.sprintf "Unsupported treesitter format"))
      (* (match From_syntax.parse_file input with
      | Ok grammar ->
          (* Convert the grammar to a string format *)
          let grammar_string = convert_grammar_to_string_antlr grammar in
          let oc = open_out output in
          output_string oc grammar_string;
          close_out oc;
          Printf.printf "Output written to %s\n" output;

          let logPath = log_json grammar in
          let grammarOf_result =
            Yojson.Safe.from_file logPath
            |> grammar_of_yojson
          in
          (match grammarOf_result with
          | Ok grammarOf ->
              let oc = open_out "output2.g4" in
              let grammar_string2 = convert_grammar_to_string_antlr grammarOf in
              output_string oc grammar_string2;
              close_out oc;
              Printf.printf "Output written to %s\n" "output2.g4";
              Ok ()
          | Error msg ->
              Error (`Msg ("Failed to parse JSON: " ^ msg)))
      | Error msg -> Error (`Msg ("Parsing error: " ^ msg))) *)
    | Some fmt ->
      Error (`Msg (Printf.sprintf "Unsupported input format: %s" fmt))
    | None ->
      Error (`Msg (Printf.sprintf "Could not detect format for file: %s" input))
  in
  match result, to_opt with
  | Ok _, Some fmt ->
      Printf.printf "Target format will be: %s\n" fmt;
      result
  | _ -> result



let cmd =
  let doc = "Convert grammars between different formats" in
  let info = Cmd.info "syntaxe_converter" ~version:"0.1" ~doc in
  Cmd.v info Term.(term_result (const run $ from $ to_ $ input $ output))

let () = exit (Cmd.eval cmd)
