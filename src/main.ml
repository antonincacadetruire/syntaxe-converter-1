open Cmdliner

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
  | _ -> None

let run from_opt to_opt input output =
  let from = match from_opt with
    | Some f -> Some f
    | None -> detect_format input
  in
  let result = match from with
  | Some "antlr" ->
      From_syntax.Logic.parse_file input;
      (* TODO: Implement conversion to target format *)
      Printf.printf "Output will be written to %s\n" output;
      Ok ()
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
