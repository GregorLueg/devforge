# Defaults block specification

A zero-argument `params_*_defaults()` helper. Same fields as a
[`param_spec()`](https://gregorlueg.github.io/devforge/reference/param_spec.md),
but the generated function takes no arguments, runs no assertions and
simply returns the defaults. These exist to be embedded in other
constructors.

## Usage

``` r
param_defaults(
  name,
  title,
  fields,
  description = NULL,
  details = NULL,
  references = NULL,
  checker = NULL,
  label = NULL,
  hint = NULL,
  export = TRUE
)
```

## Arguments

- name:

  String. Snake case stem. `"knn_defaults"` gives
  `params_knn_defaults()`.

- title:

  String. The roxygen title line.

- fields:

  Named list of
  [`p_int()`](https://gregorlueg.github.io/devforge/reference/p_int.md)
  and friends.

- description:

  String or `NULL`. Roxygen `@description` prose.

- details:

  String or `NULL`. Roxygen `@details` prose.

- references:

  String or `NULL`. Roxygen `@references` prose.

- checker:

  String or `NULL`. PascalCase stem for a checker over this block, for
  the defaults blocks that are validated on their own. Defaults to
  `NULL`.

- label:

  String or `NULL`. Label used in the checker's error messages.

- hint:

  String or `NULL`. Appended to the checker's error messages.

- export:

  Boolean. Whether the helper gets `@export`. Defaults to `TRUE`.

## Value

A list of class `devforge_spec`.
