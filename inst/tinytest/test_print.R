# printing of devforge's own objects -------------------------------------------

expect_equal(
  format(p_int(10L, range = "[0,)", doc = "x")),
  "int = 10L in [0,)"
)
expect_equal(format(p_dbl(1, doc = "x")), "dbl = 1.0")
expect_equal(format(p_int(range = "[1,)", doc = "x")), "int (required) in [1,)")
expect_equal(
  format(p_chr(NULL, null_ok = TRUE, len = "+", doc = "x")),
  "chr?[+] = NULL"
)
expect_equal(
  format(p_choice("qr", c("lu", "qr"), doc = "x")),
  'choice("qr", "lu") = "qr"'
)
expect_equal(
  format(p_enum("pca_solver", "exact", doc = "x")),
  'PcaSolver = "exact"'
)
expect_equal(format(p_merge("knn_defaults", doc = "x")), "merge(knn_defaults)")

solver <- param_enum(
  name = "pca_solver",
  title = "PCA solver",
  variants = list(
    covariance = p_variant("Cross-product."),
    randomised = p_variant(
      "Randomised SVD.",
      n_iter = p_int(2L, range = "[0,)", doc = "Power iterations.")
    )
  ),
  methods = list(is_exact = "Exactness")
)
expect_equal(
  format(solver),
  c(
    "// pca_solver: PCA solver",
    "enum PcaSolver {",
    "  /// Cross-product.",
    "  Covariance,",
    "  /// Randomised SVD.",
    "  Randomised { n_iter: int = 2L in [0,) },",
    "}",
    "impl PcaSolver { is_exact() }"
  )
)
expect_stdout(print(solver), "enum PcaSolver")
expect_equal(
  format(solver$variants$randomised),
  c("/// Randomised SVD.", "Variant { n_iter: int = 2L in [0,) }")
)

# too wide for one line, so one field per line
spec <- param_spec(
  name = "pca",
  title = "Wrapper function for PCA parameters",
  fields = list(
    no_pcs = p_int(30L, range = "[1,)", doc = "Number of PCs."),
    svd_solver = p_enum("pca_solver", "covariance", doc = "Solver."),
    genes = p_chr(NULL, null_ok = TRUE, len = "+", doc = "Genes.")
  )
)
expect_equal(
  format(spec),
  c(
    "// param_spec: Wrapper function for PCA parameters",
    "params_pca() -> checkPcaParams() {",
    "  no_pcs: int = 30L in [1,),",
    '  svd_solver: PcaSolver = "covariance",',
    "  genes: chr?[+] = NULL,",
    "}"
  )
)
expect_equal(
  format(param_defaults(
    name = "knn_defaults",
    title = "kNN defaults",
    fields = list(k = p_int(15L, doc = "Neighbours."))
  )),
  c("// param_defaults: kNN defaults", "params_knn_defaults() { k: int = 15L }")
)
