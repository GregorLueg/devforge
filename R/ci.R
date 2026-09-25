# ci ---------------------------------------------------------------------------

#' Add the params drift workflow to a package
#'
#' @description Copies a GitHub Actions workflow into
#' `.github/workflows/params-drift.yml` that installs devforge and fails the
#' build when [params_up_to_date()] reports stale generated files. The runner
#' is macOS, since that is where the specs get forged; see the comments in the
#' workflow. Also adds `^\.github$` to `.Rbuildignore` if it is not there yet.
#'
#' @param pkg String. Path to the package root. Defaults to `"."`.
#' @param overwrite Boolean. Replace an existing workflow file. Defaults to
#' `FALSE`.
#' @param .verbose Boolean. Report what was written. Defaults to `TRUE`.
#'
#' @returns The path of the workflow file, invisibly.
#'
#' @export
use_drift_ci <- function(pkg = ".", overwrite = FALSE, .verbose = TRUE) {
  checkmate::assertDirectoryExists(pkg)
  checkmate::assertDirectoryExists(file.path(pkg, "inst", "params"))
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
  file.copy(
    system.file("templates", "params-drift.yml", package = "devforge"),
    target,
    overwrite = TRUE
  )
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
