# Deparse a value into source code

Turns an R value back into the source text that recreates it. Used to
write defaults and rule tables into the generated files. Integers keep
their `L` suffix, strings keep their quotes, `NULL` stays `NULL`.

## Usage

``` r
deparse_value(x)
```

## Arguments

- x:

  Any R object that can be deparsed.

## Value

String. A single line of R source.
