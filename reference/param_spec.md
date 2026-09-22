# Parameter wrapper specification

The declarative description of one `params_*()` constructor and its
paired checkmate extension. Everything the generator emits comes from
here.

## Usage

``` r
param_spec(
  name,
  title,
  fields,
  description = NULL,
  details = NULL,
  references = NULL,
  return_order = NULL,
  checker = to_pascal_case(name),
  checker_args = list(),
  extra_ctor = NULL,
  extra_check = NULL,
  class_tag = NULL,
  strict_names = FALSE,
  label = NULL,
  hint = NULL,
  test_fn = FALSE,
  export = TRUE
)
```

## Arguments

- name:

  String. Snake case stem. `"ica_general"` gives `params_ica_general()`.

- title:

  String. The roxygen title line for the constructor.

- fields:

  Named list of
  [`p_int()`](https://gregorlueg.github.io/devforge/reference/p_int.md)
  and friends. Order is the order of the formals and of the returned
  list.

- description:

  String or `NULL`. Roxygen `@description` prose. Defaults to `NULL`.

- details:

  String or `NULL`. Roxygen `@details` prose. Line breaks are kept so it
  can carry its own `\itemize{}`, and lines over the width are wrapped.
  Defaults to `NULL`.

- references:

  String or `NULL`. Roxygen `@references` prose. Defaults to `NULL`.

- return_order:

  Character vector or `NULL`. The order of the returned list, when it
  differs from the order of the formals. Must be a permutation of
  `names(fields)`. Defaults to `NULL`, meaning the order of the formals.

- checker:

  String or `NULL`. PascalCase stem for the checkmate extension, giving
  `check<stem>Params()` and `assert<stem>Params()`. Two specs may share
  a stem, in which case the checker is emitted once and the field sets
  must agree. `NULL` emits no checker. Defaults to the PascalCase form
  of `name`.

- checker_args:

  A list made with [`base::alist()`](https://rdrr.io/r/base/list.html).
  Extra formals for the checker beyond `x`, for the checkers that
  cross-reference an outside object. Defaults to an empty list.

- extra_ctor:

  Language object or `NULL`. Emitted verbatim into the constructor after
  the per-field assertions. For cross-field rules.

- extra_check:

  Language object or `NULL`. Emitted verbatim into the checker before
  its final return. Must
  [`return()`](https://rdrr.io/r/base/function.html) an error string on
  failure.

- class_tag:

  String or `NULL`. When set, the returned list is tagged
  `c(class_tag, "list")`. Only for the params objects that are
  dispatched on with [`inherits()`](https://rdrr.io/r/base/class.html).
  Defaults to `NULL`.

- strict_names:

  Boolean. `TRUE` demands exactly the declared names, `FALSE` uses
  `must.include` and tolerates extras. Defaults to `FALSE`.

- label:

  String or `NULL`. Human readable label used in the checker's error
  messages. Defaults to `name` with underscores replaced by spaces,
  followed by `"params"`.

- hint:

  String or `NULL`. Appended to the checker's error messages to describe
  the expected types and ranges.

- test_fn:

  Boolean. Also emit `test<stem>Params()` via
  [`checkmate::makeTestFunction()`](https://mllg.github.io/checkmate/reference/makeTest.html).
  Defaults to `FALSE`.

- export:

  Boolean. Whether the constructor gets `@export`. Defaults to `TRUE`.

## Value

A list of class `devforge_spec`.
