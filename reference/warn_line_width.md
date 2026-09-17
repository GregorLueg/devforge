# Warn about generated lines that exceed the line width

air will not reflow what a consumer's `persistent-line-breaks` setting
tells it to leave alone, and an unbreakable literal inside an
`extra_ctor` block cannot be reflowed at all. Say so rather than quietly
shipping a 95 character line into a package that formats at 80.

## Usage

``` r
warn_line_width(paths, width = 80L)
```

## Arguments

- paths:

  Character vector of file paths.

- width:

  Integer. The line width. Defaults to `80L`.

## Value

`TRUE` if every line fits, `FALSE` otherwise.
