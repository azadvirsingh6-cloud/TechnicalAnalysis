# Run from the Assignment02 directory after running 01_setup.R.
source("02_functions.R")
source("03_display.R")
stocks <- load_stock_data("portfolio.txt", from = "2025-01-01", to = "2026-01-01")
statistics <- lapply(stocks, calculate_statistics, n = 20L)
display_stock_data(stocks)
summary_table <- save_stock_outputs(stocks, statistics)
failures <- attr(stocks, "failures")
write.csv(data.frame(Symbol = as.character(names(failures)), Error = unname(failures)),
          "results/import_failures.csv", row.names = FALSE)
writeLines(c(paste("Retrieved:", Sys.time()), "Source: Yahoo Finance via quantmod",
             "Requested interval: 2025-01-01 to 2026-01-01 (end exclusive at provider)",
             "Statistics basis: unadjusted Close, finite observations only",
             "Moving average: trailing 20 retained observations; no look ahead",
             capture.output(sessionInfo())), "results/session_info.txt")
message("Outputs saved in results/. Check import_failures.csv for missing symbols.")
