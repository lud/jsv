# Used by "mix format"
[
  line_length: 120,
  inputs: ["*.exs", "{config,lib,test,tools,tmp}/**/*.{ex,exs}"],
  force_do_end_blocks: true,
  locals_without_parens: [pass: 1, ignore_keyword: 1, take_keyword: 5, take_keyword: 6, consume_keyword: 1]
]
