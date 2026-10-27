# conda ------------------------------------------------------------------------

## helpers ---------------------------------------------------------------------

#' Licences the recipe generator knows how to map
#'
#' @description Maps the `License` field of a DESCRIPTION to its SPDX
#' identifier. Extend when a package needs another licence.
#'
#' @noRd
CONDA_LICENSES <- c("MIT + file LICENSE" = "MIT")

#' Split a DESCRIPTION dependency field into names and constraints
#'
#' @param x String or `NULL`. The raw field, e.g. `"a, b (>= 1.0)"`.
#'
#' @returns A list with:
#' \itemize{
#'  \item name - Character vector. Package names.
#'  \item constraint - Character vector. Conda version constraints such as
#'  `">=1.0"`, empty where the field gives none.
#' }
#'
#' @keywords internal
parse_dep_field <- function(x) {
  checkmate::qassert(x, c("0", "S1"))
  entries <- if (is.null(x)) character() else trimws(strsplit(x, ",")[[1L]])
  entries <- entries[nzchar(entries)]
  list(
    name = trimws(sub("\\(.*$", "", entries)),
    constraint = purrr::map_chr(entries, \(e) {
      if (!grepl("\\(", e)) {
        return("")
      }
      conda_version(gsub("[[:space:]]", "", sub("^.*\\((.*)\\).*$", "\\1", e)))
    })
  )
}

#' Turn an R version string into a conda one
#'
#' @description Conda versions cannot contain `-`, so `1.2-3` becomes `1.2_3`,
#' the same rewrite rattler-build's CRAN recipes use.
#'
#' @param x String. An R version, optionally with a comparison prefix.
#'
#' @returns String. The conda version.
#'
#' @keywords internal
conda_version <- function(x) {
  checkmate::qassert(x, "S1")
  gsub("-", "_", x, fixed = TRUE)
}

#' Map R package dependencies to conda package specs
#'
#' @description Base packages ship with `r-base` and are dropped. Bioconductor
#' packages are prefixed `bioconductor-`, everything else `r-`, both
#' lowercased as conda-forge and bioconda name them.
#'
#' @param deps List. Output of [parse_dep_field()].
#' @param bioconductor Character vector. Names of the Bioconductor packages.
#'
#' @returns Character vector of conda specs, e.g. `"r-duckdb >=1.5.5"`.
#'
#' @keywords internal
conda_deps <- function(deps, bioconductor) {
  checkmate::assertList(deps, len = 2L)
  checkmate::qassert(bioconductor, "S*")
  base_pkgs <- c(
    "R",
    rownames(utils::installed.packages(priority = "base"))
  )
  keep <- !deps$name %in% base_pkgs
  if (!any(keep)) {
    return(character())
  }
  prefix <- ifelse(
    deps$name[keep] %in% bioconductor,
    "bioconductor-",
    "r-"
  )
  trimws(paste0(
    prefix,
    tolower(deps$name[keep]),
    " ",
    deps$constraint[keep]
  ))
}

#' Quote a string for YAML
#'
#' @param x String.
#'
#' @returns String. `x` in double quotes with backslashes and quotes escaped.
#'
#' @keywords internal
yaml_quote <- function(x) {
  checkmate::qassert(x, "S1")
  sprintf('"%s"', gsub('(["\\\\])', "\\\\\\1", x))
}

#' Emit a YAML list under a key
#'
#' @param key String. The key.
#' @param items Character vector. The list items, already formatted.
#' @param n Integer. Indent of the key in spaces.
#'
#' @returns Character vector of YAML lines.
#'
#' @keywords internal
yaml_list <- function(key, items, n = 2L) {
  checkmate::qassert(key, "S1")
  checkmate::qassert(items, "S*")
  checkmate::qassert(n, "I1[0,)")
  pad <- strrep(" ", n)
  c(paste0(pad, key, ":"), paste0(pad, "  - ", items))
}

## recipe ----------------------------------------------------------------------

#' Write a rattler-build recipe for a package
#'
#' @description Generates a rattler-build `recipe.yaml` from the package's
#' DESCRIPTION, for publishing to a conda channel such as prefix.dev. The
#' recipe is a build artefact rather than a file to commit: it builds from the
#' package directory as it stands, so building an older release means checking
#' out its tag and generating again.
#'
#' `Imports` and `Depends` become host and run requirements, `LinkingTo` host
#' only. Base packages are dropped, the R version comes from the `r_base`
#' variant at build time. List Bioconductor dependencies in a
#' `Config/devforge/bioconductor` field (comma separated) so they map to
#' bioconda's `bioconductor-` names. Your own packages need no mapping, add
#' their channel when building.
#'
#' A package with `src/rust/Cargo.toml` gets the Rust compiler and has
#' `CARGO_BUILD_TARGET` unset before the install: conda's Rust activation sets
#' it, which moves the static library under `target/<triple>/` where
#' rextendr's Makevars does not look. Windows is skipped.
#'
#' @param pkg String. Path to the package root. Defaults to `"."`.
#' @param dir String. Directory to write `recipe.yaml` into. Created if
#' needed. Keep it outside `pkg`, the build copies `pkg` as its source.
#' Defaults to a temporary directory.
#' @param .verbose Boolean. Report what was written. Defaults to `TRUE`.
#'
#' @returns The path of the recipe, invisibly.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' recipe <- conda_recipe(".")
#' system2("rattler-build", c("build", "--recipe", recipe, "-c", "conda-forge"))
#' }
conda_recipe <- function(
  pkg = ".",
  dir = file.path(tempdir(), "conda"),
  .verbose = TRUE
) {
  checkmate::assertDirectoryExists(pkg)
  checkmate::assertFileExists(file.path(pkg, "DESCRIPTION"))
  checkmate::qassert(dir, "S1")
  checkmate::qassert(.verbose, "B1")

  desc <- as.list(read.dcf(file.path(pkg, "DESCRIPTION"))[1L, ])
  license <- CONDA_LICENSES[desc$License]
  if (is.na(license)) {
    stop(sprintf(
      "No SPDX mapping for License `%s`. Add it to CONDA_LICENSES.",
      desc$License
    ))
  }
  bioconductor <- parse_dep_field(desc[["Config/devforge/bioconductor"]])$name
  runtime <- conda_deps(
    purrr::map2(
      parse_dep_field(desc$Depends),
      parse_dep_field(desc$Imports),
      c
    ),
    bioconductor
  )
  linking <- conda_deps(parse_dep_field(desc$LinkingTo), bioconductor)

  src <- file.path(pkg, "src")
  has_src <- dir.exists(src)
  has_rust <- file.exists(file.path(src, "rust", "Cargo.toml"))
  has_cxx <- has_src &&
    length(list.files(src, pattern = "\\.(cpp|cc)$")) > 0L

  urls <- if (is.null(desc$URL)) {
    character()
  } else {
    trimws(strsplit(desc$URL, "[,[:space:]]+")[[1L]])
  }
  urls <- urls[nzchar(urls)]
  repo <- urls[grepl("github\\.com", urls)]

  install <- "R CMD INSTALL --build . ${R_ARGS}"
  script <- if (has_rust) {
    yaml_list("script", c("unset CARGO_BUILD_TARGET", install))
  } else {
    paste0("  script: ", install)
  }
  build_reqs <- c(
    if (has_src) 'cross-r-base ${{ r_base }}.*',
    if (has_src) '${{ compiler("c") }}',
    if (has_cxx) '${{ compiler("cxx") }}',
    if (has_rust) '${{ compiler("rust") }}',
    if (has_src) "make",
    if (has_rust) "xz"
  )
  build_block <- if (length(build_reqs) == 0L) {
    character()
  } else {
    c(
      "  build:",
      if (has_src) {
        c(
          "    - if: build_platform != target_platform",
          "      then:",
          paste0("        - ", build_reqs[1L])
        )
      },
      paste0("    - ", build_reqs[-1L])
    )
  }

  recipe <- c(
    "schema_version: 1",
    "",
    "context:",
    paste0("  version: ", yaml_quote(conda_version(desc$Version))),
    "",
    "package:",
    paste0("  name: r-", tolower(desc$Package)),
    "  version: ${{ version }}",
    "",
    "source:",
    paste0("  path: ", yaml_quote(normalizePath(pkg))),
    "",
    "build:",
    "  number: 0",
    "  skip: win",
    if (!has_src) "  noarch: generic",
    script,
    if (has_src) {
      c(
        "  dynamic_linking:",
        "    rpaths:",
        "      - lib/R/lib/",
        "      - lib/"
      )
    },
    "",
    "requirements:",
    build_block,
    yaml_list("host", c("r-base", linking, runtime)),
    yaml_list("run", c("r-base", runtime)),
    "",
    "tests:",
    "  - r:",
    "      libraries:",
    paste0("        - ", desc$Package),
    "",
    "about:",
    if (length(urls) > 0L) paste0("  homepage: ", urls[1L]),
    paste0("  summary: ", yaml_quote(desc$Title)),
    paste0("  license: ", license),
    "  license_file: LICENSE",
    if (length(repo) > 0L) paste0("  repository: ", repo[1L])
  )

  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  target <- file.path(dir, "recipe.yaml")
  writeLines(recipe, target)
  if (.verbose) {
    message(sprintf("Wrote %s", target))
  }
  invisible(target)
}
