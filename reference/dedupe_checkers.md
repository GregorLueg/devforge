# Group specs by the checker they declare

Two specs may share a checker stem, in which case the checker is emitted
once. Their field sets have to agree, otherwise one of the two
constructors would be validated against the wrong shape.

## Usage

``` r
dedupe_checkers(specs)
```

## Arguments

- specs:

  Named list of `devforge_spec` objects.

## Value

A list of `devforge_spec` objects, one per distinct checker stem, in the
order the stems first appear.
