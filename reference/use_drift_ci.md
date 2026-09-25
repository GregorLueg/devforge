# Add the params drift workflow to a package

Copies a GitHub Actions workflow into
`.github/workflows/params-drift.yml` that installs devforge and fails
the build when
[`params_up_to_date()`](https://gregorlueg.github.io/devforge/reference/params_up_to_date.md)
reports stale generated files. Also adds `^\.github$` to `.Rbuildignore`
if it is not there yet.

## Usage

``` r
use_drift_ci(
  pkg = ".",
  runner = "macos-latest",
  overwrite = FALSE,
  .verbose = TRUE
)
```

## Arguments

- pkg:

  String. Path to the package root. Defaults to `"."`.

- runner:

  String. The GitHub Actions runner. Has to match the platform the specs
  are forged on: macOS arm64 R has no extended long double, so literals
  like `1e-300` deparse differently than on Linux and every file reads
  as stale. Defaults to `"macos-latest"`.

- overwrite:

  Boolean. Replace an existing workflow file. Defaults to `FALSE`.

- .verbose:

  Boolean. Report what was written. Defaults to `TRUE`.

## Value

The path of the workflow file, invisibly.
