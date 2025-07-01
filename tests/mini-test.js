const DIGITS = token(choice('0', seq(/[1-9]/, optional(seq(optional('_'), sep1(/[0-9]+/, /_+/))))));
const DECIMAL_DIGITS = token(sep1(/[0-9]+/, '_'));
const HEX_DIGITS = token(sep1(/[A-Fa-f0-9]+/, '_'));

module.exports = grammar({
  rules: {
    this: _ => 'this',
    super: _ => 'super',
    true: _ => 'true',
    false: _ => 'false',
    null: _ => 'null',
    undefined: _ => 'undefined',

    throws: $ => seq(
      'throws', commaSep1($._type),
    ),
  }
});

function sep1(rule, separator) {
  return seq(rule, repeat(seq(separator, rule)));
}