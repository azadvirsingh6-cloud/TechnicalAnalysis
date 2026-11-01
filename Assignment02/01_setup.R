# AI-assisted example prepared for Azadvir Singh. Review before submission.
required <- c("quantmod", "TTR", "xts", "zoo")
missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
for (package in required) {
  if (!requireNamespace(package, quietly = TRUE)) stop("Package unavailable: ", package)
  cat(package, as.character(utils::packageVersion(package)), "\n")
}
sessionInfo()
