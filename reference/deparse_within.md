# Deparse one statement, tightening the cutoff if it comes out too wide

`width.cutoff` is a hint to
[`base::deparse()`](https://rdrr.io/r/base/deparse.html), not a limit:
the default of 60 happily returns a 95 character line. Nothing can be
done about an unbreakable literal, but a call with several arguments
does break once the cutoff is low enough, so try that before giving up.

## Usage

``` r
deparse_within(stmt, budget)
```

## Arguments

- stmt:

  A language object.

- budget:

  Integer. Characters available per line, measured after
  [`halve_indent()`](https://gregorlueg.github.io/devforge/reference/halve_indent.md).

## Value

Character vector of R source lines.
