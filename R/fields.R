# field constructors -----------------------------------------------------------

## internals -------------------------------------------------------------------

# qassert base letters per field type. `choice` validates as a string and gets
# its allowed set checked separately via apply_choice_rules().
QASSERT_LETTERS <- c(
  int = "I",
  dbl = "N",
  lgl = "B",
  chr = "S",
  choice = "S"
)

#' Build a field object
#'
#' @description Internal constructor behind [p_int()] and friends. A field is
#' the smallest unit of a spec: everything needed to emit one formal, one
#' assertion, one rule table entry and one roxygen line.
#'
#' @param type String. One of `c("int", "dbl", "lgl", "chr", "choice", "free")`.
#' @param default Any. The default value for the formal.
#' @param range String or `NULL`. A checkmate range suffix such as `"[1,)"`.
#' @param null_ok Boolean. Whether `NULL` is a permitted value.
#' @param len Integer or string. Length token for the qassert code. `1L` for a
#' scalar, `"+"` for one or more, `"*"` for any length.
#' @param choices Character vector or `NULL`. Allowed values for `"choice"`.
#' @param letter String or `NULL`. Overrides the qassert base letter, for the
#' rare case where a stricter class is wanted (`"R"` instead of `"N"`).
#' @param doc String or `NULL`. Roxygen prose for this field.
#'
#' @returns A list of class `devforge_field`.
#'
#' @keywords internal
new_field <- function(
  type,
  default,
  range = NULL,
  null_ok = FALSE,
  len = 1L,
  choices = NULL,
  letter = NULL,
  doc = NULL
) {
  checkmate::assertChoice(
    type,
    c("int", "dbl", "lgl", "chr", "choice", "free")
  )
  checkmate::qassert(range, c("S1", "0"))
  checkmate::qassert(null_ok, "B1")
  checkmate::qassert(choices, c("S+", "0"))
  checkmate::qassert(letter, c("S1", "0"))
  checkmate::qassert(doc, c("S1", "0"))
  if (!(checkmate::testCount(len) || checkmate::testChoice(len, c("+", "*")))) {
    stop("`len` must be a non-negative count, \"+\" or \"*\".")
  }
  structure(
    list(
      type = type,
      default = default,
      range = range,
      null_ok = null_ok,
      len = len,
      choices = choices,
      letter = letter,
      doc = doc
    ),
    class = "devforge_field"
  )
}

#' Derive the qassert pattern for a field
#'
#' @description Folds type, length, range and nullability into the single
#' pattern that both the constructor's [checkmate::qassert()] call and the
#' checker's rule table use. This is what settles the two competing spellings
#' of "integer or NULL" found across the packages onto one.
#'
#' @param field A `devforge_field`.
#'
#' @returns Character vector of qassert patterns, or `NULL` for a `"free"`
#' field, which carries no automatic validation.
#'
#' @keywords internal
field_qassert <- function(field) {
  checkmate::assertClass(field, "devforge_field")
  if (identical(field$type, "free")) {
    return(NULL)
  }
  letter <- field$letter %||% unname(QASSERT_LETTERS[[field$type]])
  code <- paste0(letter, field$len, field$range %||% "")
  if (field$null_ok) c(code, "0") else code
}

## constructors ----------------------------------------------------------------

#' Integer field
#'
#' @param default Integer or `NULL`. The default value.
#' @param range String or `NULL`. Checkmate range suffix, for example `"[1,)"`.
#' @param null_ok Boolean. Whether `NULL` is permitted. Defaults to `FALSE`.
#' @param len Integer or string. `1L` for a scalar, `"+"` for one or more.
#' Defaults to `1L`.
#' @param doc String or `NULL`. Roxygen prose for this field.
#'
#' @returns A `devforge_field`.
#'
#' @export
p_int <- function(
  default,
  range = NULL,
  null_ok = FALSE,
  len = 1L,
  doc = NULL
) {
  new_field(
    type = "int",
    default = default,
    range = range,
    null_ok = null_ok,
    len = len,
    doc = doc
  )
}

#' Numeric field
#'
#' @param default Numeric or `NULL`. The default value.
#' @param range String or `NULL`. Checkmate range suffix, for example
#' `"(0, 1]"`.
#' @param null_ok Boolean. Whether `NULL` is permitted. Defaults to `FALSE`.
#' @param len Integer or string. `1L` for a scalar, `"+"` for one or more.
#' Defaults to `1L`.
#' @param strict Boolean. `TRUE` demands a double (`"R"`) rather than any
#' number (`"N"`). Defaults to `FALSE`.
#' @param doc String or `NULL`. Roxygen prose for this field.
#'
#' @returns A `devforge_field`.
#'
#' @export
p_dbl <- function(
  default,
  range = NULL,
  null_ok = FALSE,
  len = 1L,
  strict = FALSE,
  doc = NULL
) {
  checkmate::qassert(strict, "B1")
  new_field(
    type = "dbl",
    default = default,
    range = range,
    null_ok = null_ok,
    len = len,
    letter = if (strict) "R" else NULL,
    doc = doc
  )
}

#' Boolean field
#'
#' @param default Boolean or `NULL`. The default value.
#' @param null_ok Boolean. Whether `NULL` is permitted. Defaults to `FALSE`.
#' @param doc String or `NULL`. Roxygen prose for this field.
#'
#' @returns A `devforge_field`.
#'
#' @export
p_lgl <- function(default, null_ok = FALSE, doc = NULL) {
  new_field(type = "lgl", default = default, null_ok = null_ok, doc = doc)
}

#' String field
#'
#' @param default String or `NULL`. The default value.
#' @param null_ok Boolean. Whether `NULL` is permitted. Defaults to `FALSE`.
#' @param len Integer or string. `1L` for a scalar, `"+"` for one or more.
#' Defaults to `1L`.
#' @param doc String or `NULL`. Roxygen prose for this field.
#'
#' @returns A `devforge_field`.
#'
#' @export
p_chr <- function(default, null_ok = FALSE, len = 1L, doc = NULL) {
  new_field(
    type = "chr",
    default = default,
    null_ok = null_ok,
    len = len,
    doc = doc
  )
}

#' Choice field
#'
#' @description Emits `match.arg()` plus [checkmate::assertChoice()] in the
#' constructor and a `apply_choice_rules()` entry in the checker, which is what
#' the packages already do by hand. `default` is moved to the front of
#' `choices` so the generated formal reads `method = c("default", ...)`.
#'
#' @param default String. The default value. Must be one of `choices`.
#' @param choices Character vector. The allowed values.
#' @param doc String or `NULL`. Roxygen prose for this field.
#'
#' @returns A `devforge_field`.
#'
#' @export
p_choice <- function(default, choices, doc = NULL) {
  checkmate::qassert(default, "S1")
  checkmate::qassert(choices, "S+")
  checkmate::assertChoice(default, choices)
  new_field(
    type = "choice",
    default = default,
    choices = c(default, setdiff(choices, default)),
    doc = doc
  )
}

#' Unvalidated field
#'
#' @description For anything a qassert pattern cannot express. The field
#' contributes a formal, a default and its roxygen, but no assertion and no
#' rule table entry. Pair it with `extra_ctor` / `extra_check` on the spec.
#'
#' @param default Any. The default value.
#' @param doc String or `NULL`. Roxygen prose for this field.
#'
#' @returns A `devforge_field`.
#'
#' @export
p_free <- function(default, doc = NULL) {
  new_field(type = "free", default = default, doc = doc)
}
