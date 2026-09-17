# Deparse a quoted expression, unwrapping an outer brace block

`quote({ a; b })` deparses with its braces and an extra level of indent.
Statements are emitted at the nesting level they land in, so the braces
come off.

## Usage

``` r
deparse_block(expr)
```

## Arguments

- expr:

  A language object, or `NULL`.

## Value

Character vector of R source lines. Empty for `NULL`.
