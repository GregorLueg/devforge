# Build a field object

Internal constructor behind
[`p_int()`](https://gregorlueg.github.io/devforge/reference/p_int.md)
and friends. A field is the smallest unit of a spec: everything needed
to emit one formal, one assertion, one rule table entry and one roxygen
line.

## Usage

``` r
new_field(
  type,
  default,
  range = NULL,
  null_ok = FALSE,
  len = 1L,
  choices = NULL,
  letter = NULL,
  check_as = NULL,
  from = NULL,
  overrides = NULL,
  required = FALSE,
  doc = NULL
)
```

## Arguments

- type:

  String. One of
  `c("int", "dbl", "lgl", "chr", "choice", "free", "merge")`.

- default:

  Any. The default value for the formal.

- range:

  String or `NULL`. A checkmate range suffix such as `"[1,)"`.

- null_ok:

  Boolean. Whether `NULL` is a permitted value.

- len:

  Integer or string. Length token for the qassert code. `1L` for a
  scalar, `"+"` for one or more, `"*"` for any length.

- choices:

  Character vector or `NULL`. Allowed values for `"choice"`.

- letter:

  String or `NULL`. Overrides the qassert base letter, for the rare case
  where a stricter class is wanted (`"R"` instead of `"N"`).

- check_as:

  Character vector or `NULL`. Overrides the pattern used in the
  checker's rule table. For fields the constructor resolves, such as a
  worker count that takes `NULL` and comes back as an integer.

- from:

  String, language object or `NULL`. For `"merge"` fields, the base the
  caller's list is merged into, see
  [`p_merge()`](https://gregorlueg.github.io/devforge/reference/p_merge.md).

- overrides:

  List, language object or `NULL`. For `"merge"` fields,
  constructor-specific defaults layered over `from`.

- required:

  Boolean. The formal has no default and the caller must supply it.
  `default` is ignored. Defaults to `FALSE`.

- doc:

  String or `NULL`. Roxygen prose for this field.

## Value

A list of class `devforge_field`.
