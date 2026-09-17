# Wrap roxygen prose to the 80 character line width

The house style caps lines at 80 characters. Roxygen continuation lines
carry no extra indent, matching what is written by hand.

## Usage

``` r
wrap_roxygen(text, prefix, cont = "#' ")
```

## Arguments

- text:

  String. The prose to wrap.

- prefix:

  String. What goes in front of the first line, for example
  `"#' @param maxit "`.

- cont:

  String. What goes in front of every continuation line. Defaults to
  `"#' "`.

## Value

Character vector of roxygen lines.
