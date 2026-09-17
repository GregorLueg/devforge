# specs ------------------------------------------------------------------------

#' Parameter wrapper specification
#'
#' @description The declarative description of one `params_*()` constructor and
#' its paired checkmate extension. Everything the generator emits comes from
#' here.
#'
#' @param name String. Snake case stem. `"ica_general"` gives
#' `params_ica_general()`.
#' @param title String. The roxygen title line for the constructor.
#' @param fields Named list of [p_int()] and friends. Order is the order of the
#' formals and of the returned list.
#' @param description String or `NULL`. Roxygen `@description` prose. Defaults
#' to `NULL`.
#' @param details String or `NULL`. Roxygen `@details` prose, emitted verbatim
#' so it can carry its own `\itemize{}`. Defaults to `NULL`.
#' @param return_order Character vector or `NULL`. The order of the returned
#' list, when it differs from the order of the formals. Must be a permutation
#' of `names(fields)`. Defaults to `NULL`, meaning the order of the formals.
#' @param checker String or `NULL`. PascalCase stem for the checkmate
#' extension, giving `check<stem>Params()` and `assert<stem>Params()`. Two
#' specs may share a stem, in which case the checker is emitted once and the
#' field sets must agree. `NULL` emits no checker. Defaults to the PascalCase
#' form of `name`.
#' @param checker_args A list made with [base::alist()]. Extra formals for the
#' checker beyond `x`, for the checkers that cross-reference an outside object.
#' Defaults to an empty list.
#' @param extra_ctor Language object or `NULL`. Emitted verbatim into the
#' constructor after the per-field assertions. For cross-field rules.
#' @param extra_check Language object or `NULL`. Emitted verbatim into the
#' checker before its final return. Must `return()` an error string on failure.
#' @param class_tag String or `NULL`. When set, the returned list is tagged
#' `c(class_tag, "list")`. Only for the params objects that are dispatched on
#' with `inherits()`. Defaults to `NULL`.
#' @param strict_names Boolean. `TRUE` demands exactly the declared names,
#' `FALSE` uses `must.include` and tolerates extras. Defaults to `FALSE`.
#' @param label String or `NULL`. Human readable label used in the checker's
#' error messages. Defaults to `name` with underscores replaced by spaces,
#' followed by `"params"`.
#' @param hint String or `NULL`. Appended to the checker's error messages to
#' describe the expected types and ranges.
#' @param test_fn Boolean. Also emit `test<stem>Params()` via
#' [checkmate::makeTestFunction()]. Defaults to `FALSE`.
#' @param export Boolean. Whether the constructor gets `@export`. Defaults to
#' `TRUE`.
#'
#' @returns A list of class `devforge_spec`.
#'
#' @export
param_spec <- function(
  name,
  title,
  fields,
  description = NULL,
  details = NULL,
  return_order = NULL,
  checker = to_pascal_case(name),
  checker_args = list(),
  extra_ctor = NULL,
  extra_check = NULL,
  class_tag = NULL,
  strict_names = FALSE,
  label = NULL,
  hint = NULL,
  test_fn = FALSE,
  export = TRUE
) {
  checkmate::qassert(name, "S1")
  checkmate::qassert(title, "S1")
  checkmate::qassert(description, c("S1", "0"))
  checkmate::qassert(details, c("S1", "0"))
  checkmate::qassert(return_order, c("S+", "0"))
  checkmate::qassert(checker, c("S1", "0"))
  checkmate::qassert(class_tag, c("S1", "0"))
  checkmate::qassert(strict_names, "B1")
  checkmate::qassert(label, c("S1", "0"))
  checkmate::qassert(hint, c("S1", "0"))
  checkmate::qassert(test_fn, "B1")
  checkmate::qassert(export, "B1")
  assert_fields(fields)
  checkmate::assertList(checker_args, names = "named")
  if (test_fn && is.null(checker)) {
    stop("`test_fn = TRUE` needs a `checker`.")
  }
  if (!is.null(return_order) && !setequal(return_order, names(fields))) {
    stop("`return_order` must be a permutation of the field names.")
  }
  structure(
    list(
      name = name,
      title = title,
      fields = fields,
      description = description,
      details = details,
      return_order = return_order,
      checker = checker,
      checker_args = checker_args,
      extra_ctor = extra_ctor,
      extra_check = extra_check,
      class_tag = class_tag,
      strict_names = strict_names,
      label = label %||% paste(gsub("_", " ", name, fixed = TRUE), "params"),
      hint = hint,
      test_fn = test_fn,
      export = export,
      defaults_only = FALSE
    ),
    class = "devforge_spec"
  )
}

#' Defaults block specification
#'
#' @description A zero-argument `params_*_defaults()` helper. Same fields as a
#' [param_spec()], but the generated function takes no arguments, runs no
#' assertions and simply returns the defaults. These exist to be embedded in
#' other constructors.
#'
#' @param name String. Snake case stem. `"knn_defaults"` gives
#' `params_knn_defaults()`.
#' @param title String. The roxygen title line.
#' @param fields Named list of [p_int()] and friends.
#' @param description String or `NULL`. Roxygen `@description` prose.
#' @param checker String or `NULL`. PascalCase stem for a checker over this
#' block, for the defaults blocks that are validated on their own. Defaults to
#' `NULL`.
#' @param label String or `NULL`. Label used in the checker's error messages.
#' @param hint String or `NULL`. Appended to the checker's error messages.
#' @param export Boolean. Whether the helper gets `@export`. Defaults to `TRUE`.
#'
#' @returns A list of class `devforge_spec`.
#'
#' @export
param_defaults <- function(
  name,
  title,
  fields,
  description = NULL,
  checker = NULL,
  label = NULL,
  hint = NULL,
  export = TRUE
) {
  spec <- param_spec(
    name = name,
    title = title,
    fields = fields,
    description = description,
    checker = checker,
    label = label,
    hint = hint,
    export = export
  )
  spec$defaults_only <- TRUE
  spec
}

#' Validate a named list of fields
#'
#' @param fields Named list of `devforge_field` objects.
#'
#' @returns `TRUE`, invisibly. Errors otherwise.
#'
#' @keywords internal
assert_fields <- function(fields) {
  checkmate::assertList(
    fields,
    types = "devforge_field",
    min.len = 1L,
    names = "unique"
  )
  undocumented <- names(fields)[purrr::map_lgl(fields, \(f) is.null(f$doc))]
  if (length(undocumented) > 0L) {
    stop(sprintf(
      "Fields without `doc`: %s. Every field needs roxygen prose.",
      paste(undocumented, collapse = ", ")
    ))
  }
  invisible(TRUE)
}

#' Collect the specs defined in a package's spec directory
#'
#' @description Sources every `.R` file under `inst/params/` in a fresh
#' environment and returns the `devforge_spec` objects it finds, in file then
#' definition order.
#'
#' @param pkg String. Path to the package root. Defaults to `"."`.
#'
#' @returns A named list of `devforge_spec` objects, named by their `name`.
#'
#' @export
load_specs <- function(pkg = ".") {
  checkmate::assertDirectoryExists(pkg)
  spec_dir <- file.path(pkg, "inst", "params")
  checkmate::assertDirectoryExists(spec_dir)
  files <- sort(list.files(spec_dir, pattern = "\\.R$", full.names = TRUE))
  if (length(files) == 0L) {
    stop(sprintf("No spec files found in `%s`.", spec_dir))
  }
  env <- new.env(parent = asNamespace("devforge"))
  for (file in files) {
    sys.source(file, envir = env, keep.source = FALSE)
  }
  objs <- mget(ls(env, sorted = TRUE), envir = env)
  specs <- objs[purrr::map_lgl(objs, \(x) inherits(x, "devforge_spec"))]
  if (length(specs) == 0L) {
    stop(sprintf("No `param_spec()` objects found in `%s`.", spec_dir))
  }
  names(specs) <- purrr::map_chr(specs, \(x) x$name)
  duplicated_names <- names(specs)[duplicated(names(specs))]
  if (length(duplicated_names) > 0L) {
    stop(sprintf(
      "Duplicate spec names: %s.",
      paste(unique(duplicated_names), collapse = ", ")
    ))
  }
  specs[order(names(specs))]
}

#' The names of a spec's returned list, in order
#'
#' @param spec A `devforge_spec`.
#'
#' @returns Character vector of field names.
#'
#' @keywords internal
spec_field_names <- function(spec) {
  checkmate::assertClass(spec, "devforge_spec")
  spec$return_order %||% names(spec$fields)
}
