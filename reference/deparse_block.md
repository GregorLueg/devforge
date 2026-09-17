# Deparse a quoted expression, unwrapping an outer brace block

`quote({ a; b })` deparses with its braces and an extra level of indent.
Statements are emitted at the nesting level they land in, so the braces
come off.

## Usage

``` r
deparse_block(expr, budget = 78L)
```

## Arguments

- expr:

  A language object, or `NULL`.

- budget:

  Integer. Characters available per line once the block has landed at
  its nesting level. Defaults to `78L`, the 80 character width less the
  one level of indent the constructor and checker bodies put it at.

## Value

Character vector of R source lines. Empty for `NULL`.
