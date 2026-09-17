# Halve the indentation of deparsed source

[`deparse()`](https://rdrr.io/r/base/deparse.html) indents nested blocks
by four spaces and offers no option to change that. The house style is
two.

## Usage

``` r
halve_indent(lines)
```

## Arguments

- lines:

  Character vector of R source lines.

## Value

Character vector with every leading indent halved.
