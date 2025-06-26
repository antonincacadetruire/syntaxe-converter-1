module.exports = grammar({
  name: "java",
  rules: {
  },
  extras: ["line_comment", "block_comment", "/\s/"],
  conflicts: [[], [], [], [], [], [], [], [], [], [], [], [], []],
  inline: ["_name", "_simple_type", "_class_body_declaration", "_variable_initializer"],
  word: "identifier",
  supertypes: ["expression", "declaration", "statement", "primary_expression", "_literal", "_type", "_simple_type", "_unannotated_type", "module_directive"],
})