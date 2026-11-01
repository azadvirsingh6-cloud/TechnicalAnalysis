# Console tables and one closing-price/SMA chart per stock.
display_stock_data <- function(stocks, rows = 6L) {
  for (symbol in names(stocks)) {
    cat("\nSTOCK:", symbol, "\n")
    cat("Rows:", nrow(stocks[[symbol]]), "\n")
    print(utils::head(stocks[[symbol]], rows), row.names = FALSE)
    cat("Most recent records\n")
    print(utils::tail(stocks[[symbol]], rows), row.names = FALSE)
  }
}

save_stock_outputs <- function(stocks, statistics, output_dir = "results") {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  summaries <- lapply(names(stocks), function(symbol) {
    data.frame(Symbol = symbol, statistics[[symbol]]$summary, check.names = FALSE)
  })
  summary_table <- do.call(rbind, summaries)
  print(summary_table, row.names = FALSE)
  write.csv(summary_table, file.path(output_dir, "statistics.csv"), row.names = FALSE)
  for (symbol in names(stocks)) {
    safe_symbol <- gsub("[^A-Za-z0-9_-]", "_", symbol)
    d <- statistics[[symbol]]$moving_average
    write.csv(stocks[[symbol]], file.path(output_dir, paste0(safe_symbol, "_data.csv")), row.names = FALSE)
    write.csv(d, file.path(output_dir, paste0(safe_symbol, "_moving_average.csv")), row.names = FALSE)
    draw_chart <- function() {
      png(file.path(output_dir, paste0(safe_symbol, "_chart.png")), width = 1200, height = 700)
      on.exit(dev.off())
      plot(d$Date, d$Close, type = "l", col = "#1B4F72", lwd = 2,
           xlab = "Trading date", ylab = "Unadjusted closing price (USD)",
           main = paste(symbol, "closing price and moving average"))
      lines(d$Date, d$SMA, col = "#B03A2E", lwd = 2)
      legend("topleft", legend = c("Close", paste(statistics[[symbol]]$summary$MA_Window, "observation SMA")),
             col = c("#1B4F72", "#B03A2E"), lty = 1, lwd = 2, bty = "n")
    }
    draw_chart()
  }
  invisible(summary_table)
}
