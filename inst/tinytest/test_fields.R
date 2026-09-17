# field construction and qassert derivation ------------------------------------

expect_equal(devforge:::field_qassert(p_int(1L)), "I1")
expect_equal(devforge:::field_qassert(p_int(1L, range = "[1,)")), "I1[1,)")
expect_equal(
  devforge:::field_qassert(p_int(NULL, range = "[1,)", null_ok = TRUE)),
  c("I1[1,)", "0")
)
expect_equal(
  devforge:::field_qassert(p_int(NULL, len = "+", null_ok = TRUE)),
  c("I+", "0")
)
expect_equal(devforge:::field_qassert(p_dbl(1)), "N1")
expect_equal(devforge:::field_qassert(p_dbl(1, strict = TRUE)), "R1")
expect_equal(devforge:::field_qassert(p_dbl(1, range = "(0, 1]")), "N1(0, 1]")
expect_equal(devforge:::field_qassert(p_lgl(TRUE)), "B1")
expect_equal(devforge:::field_qassert(p_chr("a")), "S1")
expect_equal(devforge:::field_qassert(p_choice("a", c("a", "b"))), "S1")
expect_null(devforge:::field_qassert(p_free(NULL)))

# the default is moved to the front so match.arg() picks it
expect_equal(p_choice("b", c("a", "b", "c"))$choices, c("b", "a", "c"))
expect_error(p_choice("z", c("a", "b")))

# `len` only takes a count or the two checkmate wildcards
expect_error(devforge:::new_field("int", 1L, len = "?", doc = "x"))

# every field needs prose, otherwise the generated roxygen would be empty
expect_error(param_spec(
  name = "x",
  title = "X",
  fields = list(a = p_int(1L))
))

# `test_fn` without a checker has nothing to wrap
expect_error(param_spec(
  name = "x",
  title = "X",
  fields = list(a = p_int(1L, doc = "A.")),
  checker = NULL,
  test_fn = TRUE
))
