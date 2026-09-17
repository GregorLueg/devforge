# checker emission -------------------------------------------------------------

#' The qtest rule table for a spec
#'
#' @description Choice fields are left out: `apply_choice_rules()` already
#' implies a string scalar, so a qtest entry would be redundant. Free fields
#' carry no pattern at all.
#'
#' @param spec A `devforge_spec`.
#'
#' @returns Named list mapping field name to qassert pattern. Possibly empty.
#'
#' @keywords internal
spec_qtest_rules <- function(spec) {
  checkmate::assertClass(spec, "devforge_spec")
  ordered <- spec$fields[spec_field_names(spec)]
  keep <- purrr::map_lgl(ordered, \(f) {
    !identical(f$type, "choice") && !is.null(field_qassert(f, for_check = TRUE))
  })
  purrr::map(ordered[keep], \(f) field_qassert(f, for_check = TRUE))
}

#' The choice rule table for a spec
#'
#' @param spec A `devforge_spec`.
#'
#' @returns Named list mapping field name to allowed values. Possibly empty.
#'
#' @keywords internal
spec_choice_rules <- function(spec) {
  checkmate::assertClass(spec, "devforge_spec")
  ordered <- spec$fields[spec_field_names(spec)]
  keep <- purrr::map_lgl(ordered, \(f) identical(f$type, "choice"))
  purrr::map(ordered[keep], \(f) f$choices)
}

#' Source text for a named list of rules
#'
#' @param rules Named list of character vectors.
#' @param trailing_comma Boolean. Append a comma to the closing paren, for when
#' the list is one argument among several. Defaults to `FALSE`.
#'
#' @returns Character vector of R source lines, the opening `list(` included.
#'
#' @keywords internal
emit_rules_list <- function(rules, trailing_comma = FALSE) {
  checkmate::assertList(rules, names = "unique")
  checkmate::qassert(trailing_comma, "B1")
  entries <- paste0(
    sprintf("%s = %s", names(rules), purrr::map_chr(rules, deparse_value)),
    c(rep(",", length(rules) - 1L), "")
  )
  c("list(", indent(entries), if (trailing_comma) ")," else ")")
}

#' A guarded call that returns early on failure
#'
#' @param call_lines Character vector. The source of the call.
#'
#' @returns Character vector of R source lines.
#'
#' @keywords internal
emit_guarded <- function(call_lines) {
  c(
    paste0("res <- ", call_lines[[1L]]),
    call_lines[-1L],
    "if (!isTRUE(res)) {",
    indent("return(res)"),
    "}",
    ""
  )
}

#' A generated `check*Params()` and its assertion sibling
#'
#' @param spec A `devforge_spec`.
#'
#' @returns Character vector of R source lines, or an empty vector when the
#' spec declares no checker.
#'
#' @keywords internal
emit_checker <- function(spec) {
  checkmate::assertClass(spec, "devforge_spec")
  if (is.null(spec$checker)) {
    return(character(0))
  }
  check_name <- paste0("check", spec$checker, "Params")
  assert_name <- paste0("assert", spec$checker, "Params")
  # The comma belongs on the end of the label line, not on one of its own.
  label_arg <- sprintf("label = %s", deparse_value(spec$label))
  hint_arg <- character(0)
  if (!is.null(spec$hint)) {
    label_arg <- paste0(label_arg, ",")
    hint_arg <- sprintf("hint = %s", deparse_value(spec$hint))
  }

  shape_args <- list("x", emit_char_vector(spec_field_names(spec)))
  if (spec$strict_names) {
    shape_args <- c(shape_args, list("strict = TRUE"))
  }
  body <- emit_guarded(emit_call("check_list_shape", shape_args))

  qtest_rules <- spec_qtest_rules(spec)
  if (length(qtest_rules) > 0L) {
    body <- c(
      body,
      emit_guarded(c(
        "apply_qtest_rules(",
        indent("x,"),
        indent(emit_rules_list(qtest_rules, trailing_comma = TRUE)),
        indent(label_arg),
        indent(hint_arg),
        ")"
      ))
    )
  }

  choice_rules <- spec_choice_rules(spec)
  if (length(choice_rules) > 0L) {
    body <- c(
      body,
      emit_guarded(c(
        "apply_choice_rules(",
        indent("x,"),
        indent(emit_rules_list(choice_rules, trailing_comma = TRUE)),
        indent(label_arg),
        indent(hint_arg),
        ")"
      ))
    )
  }

  if (!is.null(spec$extra_check)) {
    body <- c(body, deparse_block(spec$extra_check), "")
  }
  body <- c(body, "return(TRUE)")

  formals_src <- paste(
    c("x", names(spec$checker_args)),
    collapse = ", "
  )
  if (length(spec$checker_args) > 0L) {
    formals_src <- paste(
      c(
        "x",
        sprintf(
          "%s = %s",
          names(spec$checker_args),
          purrr::map_chr(spec$checker_args, deparse_value)
        )
      ),
      collapse = ", "
    )
  }

  roxygen <- c(
    sprintf("#' Check %s", spec$label),
    "#'",
    wrap_roxygen(
      sprintf(
        "Checkmate extension for the output of %s.",
        paste(
          sprintf("[params_%s()]", spec$covers %||% spec$name),
          collapse = " and "
        )
      ),
      prefix = "#' @description "
    ),
    "#'",
    "#' @param x The object to check.",
    if (length(spec$checker_args) > 0L) {
      purrr::imap_chr(spec$checker_args, \(value, name) {
        sprintf("#' @param %s Extra context for the check.", name)
      }) |>
        unname()
    },
    "#'",
    "#' @returns `TRUE` if the check was successful, otherwise a",
    "#' checkmate-style error string.",
    "#'",
    "#' @keywords internal"
  )

  assert_roxygen <- c(
    sprintf("#' Assert %s", spec$label),
    "#'",
    sprintf("#' @inheritParams %s", check_name),
    "#' @param .var.name Name of the checked object to print in assertions.",
    "#' @param add Collection to store assertion messages. See",
    "#' [checkmate::makeAssertCollection()].",
    "#'",
    "#' @returns Invisibly returns the checked object if the assertion is",
    "#' successful.",
    "#'",
    "#' @keywords internal"
  )

  out <- c(
    roxygen,
    sprintf("%s <- function(%s) {", check_name, formals_src),
    indent(body),
    "}",
    "",
    assert_roxygen,
    prefix_first(
      paste0(assert_name, " <- "),
      emit_call(
        "checkmate::makeAssertionFunction",
        list(check_name),
        budget = 80L - nchar(assert_name) - 4L
      )
    )
  )
  if (spec$test_fn) {
    out <- c(
      out,
      "",
      sprintf("#' Test %s", spec$label),
      "#'",
      sprintf("#' @inheritParams %s", check_name),
      "#'",
      "#' @returns Boolean. `TRUE` if the check was successful, otherwise",
      "#' `FALSE`.",
      "#'",
      "#' @keywords internal",
      prefix_first(
        paste0("test", spec$checker, "Params <- "),
        emit_call(
          "checkmate::makeTestFunction",
          list(check_name),
          budget = 80L - nchar(spec$checker) - 14L
        )
      )
    )
  }
  out
}
