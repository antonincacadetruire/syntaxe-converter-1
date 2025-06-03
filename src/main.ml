open Cmdliner

let from =
  let doc = "Source grammar format (e.g., ebnf, antlr, bison, etc.)" in
  Arg.(required & opt (some string) None & info ["from"] ~docv:"FORMAT" ~doc)

let to_ =
  let doc = "Target grammar format (e.g., ebnf, antlr, bison, etc.)" in
  Arg.(required & opt (some string) None & info ["to"] ~docv:"FORMAT" ~doc)

let input =
  let doc = "Input grammar file." in
  Arg.(required & pos 0 (some file) None & info [] ~docv:"INPUT" ~doc)

let output =
  let doc = "Output grammar file." in
  Arg.(required & pos 1 (some string) None & info [] ~docv:"OUTPUT" ~doc)

let run from to_ input output =
  Printf.printf "Converting from %s to %s: %s -> %s\n" from to_ input output

let cmd =
  let doc = "Convert grammars between different formats" in
  Cmd.v (Cmd.info "syntaxe_converter" ~version:"0.1" ~doc)
    Term.(const run $ from $ to_ $ input $ output)

let () = exit (Cmd.eval cmd)
