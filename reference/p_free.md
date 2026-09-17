# Unvalidated field

For anything a qassert pattern cannot express. The field contributes a
formal, a default and its roxygen, but no assertion and no rule table
entry. Pair it with `extra_ctor` / `extra_check` on the spec.

## Usage

``` r
p_free(default, doc = NULL)
```

## Arguments

- default:

  Any. The default value.

- doc:

  String or `NULL`. Roxygen prose for this field.

## Value

A `devforge_field`.
