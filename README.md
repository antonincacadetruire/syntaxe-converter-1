# Syntaxe Converter

Syntaxe Converter est un outil CLI écrit en OCaml et Menhir pour transformer des grammaires entre différents formats : BNF, EBNF, Antlr, TreeSitter, Flex et Bison.

## Installation

Assurez-vous d'avoir OCaml, Dune et Menhir installés sur votre système.

```bash
opam install dune menhir
```

## Utilisation

Compilez le projet avec Dune :

```bash
dune build
```

Exécutez l'outil :

```bash
_build/default/syntaxe-converter.exe
```

Ajoutez vos options CLI pour spécifier les formats source et cible.

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à ouvrir une issue ou une pull request.