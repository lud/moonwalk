locals_without_parens = [operation: 2, operation: 1]

[
  import_deps: [:phoenix],
  inputs: ["*.exs", "{config,lib,test,tmp}/**/*.{ex,exs}"],
  force_do_end_blocks: true,
  locals_without_parens: locals_without_parens,
  export: [locals_without_parens: locals_without_parens],
  line_length: 120
]
