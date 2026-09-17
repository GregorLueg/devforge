# source text helpers ----------------------------------------------------------

expect_equal(devforge:::to_pascal_case("ica_general"), "IcaGeneral")
expect_equal(devforge:::to_pascal_case("sc_harmony_v2"), "ScHarmonyV2")
expect_equal(devforge:::to_pascal_case("nn"), "Nn")

expect_equal(devforge:::deparse_value(200L), "200L")
expect_equal(devforge:::deparse_value(NULL), "NULL")
expect_equal(devforge:::deparse_value(c("a", "b")), 'c("a", "b")')
expect_equal(devforge:::deparse_value(TRUE), "TRUE")

# whole doubles keep their decimal point so the formals read as doubles
expect_equal(devforge:::deparse_double(1), "1.0")
expect_equal(devforge:::deparse_double(0.25), "0.25")
expect_equal(devforge:::deparse_double(NULL), "NULL")
expect_equal(devforge:::deparse_double(c(1, 2)), "c(1.0, 2.0)")

expect_equal(devforge:::indent(c("a", "")), c("  a", ""))

wrapped <- devforge:::wrap_roxygen(
  paste(rep("word", 40L), collapse = " "),
  prefix = "#' @param x "
)
expect_true(all(nchar(wrapped) <= 80L))
expect_true(length(wrapped) > 1L)
expect_true(all(grepl("^#' ", wrapped)))
