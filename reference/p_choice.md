# Choice field

Emits [`match.arg()`](https://rdrr.io/r/base/match.arg.html) plus
[`checkmate::assertChoice()`](https://mllg.github.io/checkmate/reference/checkChoice.html)
in the constructor and a `apply_choice_rules()` entry in the checker,
which is what the packages already do by hand. `default` is moved to the
front of `choices` so the generated formal reads
`method = c("default", ...)`.

## Usage

``` r
p_choice(default, choices, doc = NULL)
```

## Arguments

- default:

  String. The default value. Must be one of `choices`.

- choices:

  Character vector. The allowed values.

- doc:

  String or `NULL`. Roxygen prose for this field.

## Value

A `devforge_field`.
