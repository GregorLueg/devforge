# shared checker helpers -------------------------------------------------------

# Emitted into every package so the generated checkers are three calls deep
# rather than a copy-pasted purrr::imap_lgl() dance. Lifted from bixverse's
# hand-written versions, with `strict` added to check_list_shape().
PRELUDE_SOURCE <- '# internal helpers ------------------------------------------------------------

#\' Check that a value is a list with the required names
#\'
#\' @description Boilerplate guard at the top of every generated parameter
#\' checker: verifies `x` is a list and that `required_names` are present in
#\' `names(x)`.
#\'
#\' @param x The object to check.
#\' @param required_names Character vector of names that must be present in
#\' `names(x)`.
#\' @param strict Boolean. `TRUE` additionally rejects names that are not in
#\' `required_names`. Defaults to `FALSE`.
#\'
#\' @returns `TRUE` if the check was successful, otherwise a checkmate-style
#\' error string.
#\'
#\' @keywords internal
check_list_shape <- function(x, required_names, strict = FALSE) {
  res <- checkmate::checkList(x)
  if (!isTRUE(res)) {
    return(res)
  }
  res <- checkmate::checkNames(names(x), must.include = required_names)
  if (!isTRUE(res) || !strict) {
    return(res)
  }
  extra <- setdiff(names(x), required_names)
  if (length(extra) > 0L) {
    return(sprintf(
      "Unexpected element(s): %s.",
      paste(sprintf("`%s`", extra), collapse = ", ")
    ))
  }
  TRUE
}

#\' Apply qtest rules by name
#\'
#\' @description Validates the elements of a named list `x` against per-field
#\' [checkmate::qtest()] patterns. Fields whose names are not in `rules` are
#\' skipped. On failure, returns an error string naming the first offending
#\' element and appending an optional `hint`.
#\'
#\' @param x Named list of parameters to validate.
#\' @param rules Named list mapping field name to a qtest pattern (or vector of
#\' patterns passed to `qtest`).
#\' @param label Short human-readable label used in the error message
#\' (e.g. `"GSEA params"`).
#\' @param hint Optional string appended to the error message to describe the
#\' expected types/ranges. Defaults to `NULL` (no hint).
#\'
#\' @returns `TRUE` if all checked fields pass, otherwise a string of the form
#\' `` "The element `<field>` in <label> is invalid. <hint>" ``.
#\'
#\' @keywords internal
apply_qtest_rules <- function(x, rules, label, hint = NULL) {
  res <- purrr::imap_lgl(x, \\(val, name) {
    if (name %in% names(rules)) {
      checkmate::qtest(val, rules[[name]])
    } else {
      TRUE
    }
  })
  if (all(res)) {
    return(TRUE)
  }
  broken <- names(res)[!res][1]
  msg <- sprintf("The element `%s` in %s is invalid.", broken, label)
  if (!is.null(hint)) {
    msg <- paste(msg, hint)
  }
  msg
}

#\' Apply testChoice rules by name
#\'
#\' @description Validates the elements of a named list `x` against per-field
#\' [checkmate::testChoice()] choice sets. Fields whose names are not in `rules`
#\' are skipped. On failure, returns an error string naming the first offending
#\' element and appending an optional `hint`.
#\'
#\' @param x Named list of parameters to validate.
#\' @param rules Named list mapping field name to the character vector of
#\' allowed choices.
#\' @param label Short human-readable label used in the error message
#\' (e.g. `"MELD params"`).
#\' @param hint Optional string appended to the error message. Defaults to
#\' `NULL` (no hint).
#\'
#\' @returns `TRUE` if all checked fields pass, otherwise a string naming the
#\' first offending element.
#\'
#\' @keywords internal
apply_choice_rules <- function(x, rules, label, hint = NULL) {
  res <- purrr::imap_lgl(x, \\(val, name) {
    if (name %in% names(rules)) {
      checkmate::testChoice(val, rules[[name]])
    } else {
      TRUE
    }
  })
  if (all(res)) {
    return(TRUE)
  }
  broken <- names(res)[!res][1]
  msg <- sprintf(
    "The element `%s` in %s is not one of the expected choices.",
    broken,
    label
  )
  if (!is.null(hint)) {
    msg <- paste(msg, hint)
  }
  msg
}
'

# Only emitted for packages that declare enums, so adding it did not change the
# prelude of every existing consumer.
PRELUDE_ENUM_SOURCE <- '
#\' Check a tagged enum value
#\'
#\' @description Verifies that `x` is a list whose `variant` is one of
#\' `names(variants)` and whose other names are exactly that variant\'s fields,
#\' then validates the fields with their qtest patterns and choice sets.
#\'
#\' @param x The object to check.
#\' @param variants Named list, one entry per variant, each a list with
#\' `fields` (character vector) and optionally `rules` (named list of qtest
#\' patterns) and `choices` (named list of allowed values).
#\' @param label Short human-readable label used in the error message.
#\'
#\' @returns `TRUE` if the check was successful, otherwise a checkmate-style
#\' error string.
#\'
#\' @keywords internal
check_enum_value <- function(x, variants, label) {
  res <- checkmate::checkList(x)
  if (!isTRUE(res)) {
    return(res)
  }
  res <- checkmate::checkChoice(x[["variant"]], names(variants))
  if (!isTRUE(res)) {
    return(sprintf("The `variant` of %s is invalid: %s", label, res))
  }
  spec <- variants[[x[["variant"]]]]
  label <- sprintf("%s variant `%s`", label, x[["variant"]])
  res <- check_list_shape(x, c("variant", spec$fields), strict = TRUE)
  if (!isTRUE(res)) {
    return(sprintf("Invalid %s. %s", label, res))
  }
  res <- apply_qtest_rules(x, spec$rules, label)
  if (!isTRUE(res)) {
    return(res)
  }
  apply_choice_rules(x, spec$choices, label)
}
'

#' The shared checker helpers as source lines
#'
#' @param enums Boolean. Also emit the enum helper. Defaults to `FALSE`.
#'
#' @returns Character vector of R source lines.
#'
#' @keywords internal
emit_prelude <- function(enums = FALSE) {
  checkmate::qassert(enums, "B1")
  src <- if (enums) paste0(PRELUDE_SOURCE, PRELUDE_ENUM_SOURCE) else
    PRELUDE_SOURCE
  strsplit(src, "\n", fixed = TRUE)[[1L]]
}
