module.exports = grammar({
  rules: {
    foo: _ => { const x = 1; return x; },
    bar: _ => { const y = 2; return y; }
  }
});
