# Syntaxe Converter

Syntaxe Converter is a powerful CLI tool designed to convert grammars between popular formats: TreeSitter, ANTLR, BNFC, BISON/FLEX, ASDL, and EBNF.

The tool first parses the source syntax into a universal unique language, then generates the equivalent grammar in the chosen target format. This approach ensures reliable, structured, and extensible conversion between different grammar ecosystems.

Ideal for developers, researchers, and tool creators working with formal languages and parser generators.

## Installation

Make sure you have OCaml, Dune, and Menhir installed on your system, as well as Node.js and antlr4

```bash
opam install dune menhir
npm i
```

## Usage

Build the project with Dune:

```bash
dune build
```

Run the tool (with CLI options):

```bash
dune exec ./src/main.exe -- --from <source_format> --to <target_format> <input_file> <output_file>
```

Replace `<source_format>`, `<target_format>`, `<input_file>`, and `<output_file>` with your desired formats and file paths.

Example:

```bash
dune exec ./src/main.exe -- --from ebnf --to antlr input.ebnf output.g4
```

To run some test on the grammar you can use :
```bash
antlr4-parse Java8Lexer.g4 Java8Parser.g4 [files.g4, ...] functionStartEOF [compilationUnit] -gui [-tree, -gui]
```