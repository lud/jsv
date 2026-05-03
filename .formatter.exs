public_macros = [defschema: 1, defschema: 2, defschema: 3, defschema_for: 2, defcast: 1, defcast: 2, defcast: 3]

# Used by "mix format"
[
  line_length: 120,
  import_deps: [:readmix],
  inputs: ["*.exs", "{config,lib,test,tools,tmp,dev}/**/*.{ex,exs}"],
  force_do_end_blocks: true,
  locals_without_parens:
    public_macros ++
      [
        assert_invalid: 2,
        assert_valid: 2,
        assert_cast: 3,
        consume_keyword: 1,
        debang: 1,
        defcompose: 2,
        defpreset: 2,
        ignore_keyword: 1,
        pass: 1,
        passp: 1,
        take_keyword: 5,
        take_keyword: 6,
        with_decimal: 1
      ],
  export: [locals_without_parens: public_macros]
]
