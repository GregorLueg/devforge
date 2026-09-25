# ci ---------------------------------------------------------------------------

#' Add the params drift workflow to a package
#'
#' @description Copies a GitHub Actions workflow into
#' `.github/workflows/params-drift.yml` that installs devforge and fails the
#' build when [params_up_to_date()] reports stale generated files. Also adds
#' `^\.github$` to `.Rbuildignore` if it is not there yet.
#'
#' @param pkg String. Path to the package root. Defaults to `"."`.
#' @param runner String. The GitHub Actions runner. Has to match the platform
#' the specs are forged on: macOS arm64 R has no extended long double, so
#' literals like `1e-300` deparse differently than on Linux and every file
#' reads as stale. Defaults to `"macos-latest"`.
#' @param overwrite Boolean. Replace an existing workflow file. Defaults to
#' `FALSE`.
#' @param .verbose Boolean. Report what was written. Defaults to `TRUE`.
#'
#' @returns The path of the workflow file, invisibly.
#'
#' @export
use_drift_ci <- function(
  pkg = ".",
  runner = "macos-latest",
  overwrite = FALSE,
  .verbose = TRUE
) {
  checkmate::assertDirectoryExists(pkg)
  checkmate::assertDirectoryExists(file.path(pkg, "inst", "params"))
  checkmate::qassert(runner, "S1")
  checkmate::qassert(overwrite, "B1")
  checkmate::qassert(.verbose, "B1")
  target <- file.path(pkg, ".github", "workflows", "params-drift.yml")
  if (file.exists(target) && !overwrite) {
    warning(sprintf(
      "`%s` already exists. Set `overwrite = TRUE` to replace it.",
      target
    ))
    return(invisible(target))
  }
  dir.create(dirname(target), recursive = TRUE, showWarnings = FALSE)
  template <- readLines(
    system.file("templates", "params-drift.yml", package = "devforge")
  )
  writeLines(gsub("{{runner}}", runner, template, fixed = TRUE), target)
  buildignore <- file.path(pkg, ".Rbuildignore")
  ignored <- if (file.exists(buildignore)) {
    readLines(buildignore)
  } else {
    character()
  }
  if (!"^\\.github$" %in% ignored) {
    writeLines(c(ignored, "^\\.github$"), buildignore)
  }
  if (.verbose) {
    message(sprintf("Wrote %s", target))
  }
  invisible(target)
}
