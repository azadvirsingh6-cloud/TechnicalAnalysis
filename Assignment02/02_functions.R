# AI-assisted code. No downloaded data or numerical results are claimed.
# Each list element is a separate data frame, accessed with stocks[["AAPL"]].
load_stock_data <- function(portfolio_file = "portfolio.txt",
                            from = "2025-01-01", to = "2026-01-01") {
  if (!requireNamespace("quantmod", quietly = TRUE)) stop("Run 01_setup.R first.")
  if (!file.exists(portfolio_file)) stop("Missing portfolio file: ", portfolio_file)
  start <- as.Date(from); end <- as.Date(to)
  if (length(start) != 1L || length(end) != 1L || is.na(start) || is.na(end) || start >= end)
    stop("Use a valid start date earlier than the end date.")
  symbols <- unique(toupper(trimws(readLines(portfolio_file, warn = FALSE))))
  symbols <- symbols[nzchar(symbols)]
  if (!length(symbols)) stop("Portfolio contains no symbols.")
  stocks <- list(); failures <- character()
  for (symbol in symbols) {
    result <- tryCatch({
      x <- quantmod::getSymbols(symbol, src = "yahoo", from = start,
                               to = end, auto.assign = FALSE)
      if (NROW(x) == 0L) stop("No observations returned")
      data.frame(Date = as.Date(zoo::index(x)),
                 Open = as.numeric(quantmod::Op(x)),
                 High = as.numeric(quantmod::Hi(x)),
                 Low = as.numeric(quantmod::Lo(x)),
                 Close = as.numeric(quantmod::Cl(x)),
                 Volume = as.numeric(quantmod::Vo(x)),
                 Adjusted = as.numeric(quantmod::Ad(x)))
    }, error = function(e) e)
    if (inherits(result, "error")) {
      failures[symbol] <- conditionMessage(result)
    } else {
      stocks[[symbol]] <- result[order(result$Date), , drop = FALSE]
    }
  }
  if (!length(stocks)) stop("All imports failed: ", paste(names(failures), failures, collapse = "; "))
  attr(stocks, "failures") <- failures
  if (length(failures)) warning("Imports failed: ", paste(names(failures), collapse = ", "))
  stocks
}

# Statistical mode, not base::mode (which reports an object's storage type).
# Return all tied modal values; no unique mode if every value occurs once.
statistical_mode <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) return(NA_real_)
  values <- sort(unique(x))
  counts <- tabulate(match(x, values), nbins = length(values))
  if (max(counts) == 1L) return(NA_real_)
  values[counts == max(counts)]
}

calculate_statistics <- function(stock_data, n = 20L) {
  if (!requireNamespace("TTR", quietly = TRUE)) stop("Install TTR first.")
  if (!is.data.frame(stock_data) || !all(c("Date", "Close") %in% names(stock_data)))
    stop("Expected a data frame with Date and Close columns.")
  if (length(n) != 1L || !is.finite(n) || n < 1 || n != floor(n))
    stop("Moving average window must be a positive integer.")
  d <- stock_data[order(stock_data$Date), , drop = FALSE]
  if (!is.numeric(d$Close)) stop("Close must be numeric.")
  valid <- is.finite(d$Close)
  clean <- d[valid, , drop = FALSE]
  x <- clean$Close
  if (!length(x)) stop("No finite closing prices.")
  ma <- rep(NA_real_, length(x))
  if (length(x) >= n) ma <- as.numeric(TTR::SMA(x, n = n))
  modes <- statistical_mode(x)
  list(
    summary = data.frame(
      Observations = length(x), Excluded = sum(!valid),
      Mean = mean(x), Median = median(x),
      Mode = if (all(is.na(modes))) "No repeated value" else paste(modes, collapse = "; "),
      SD = if (length(x) > 1L) sd(x) else NA_real_,
      MA_Window = n, Latest_MA = tail(ma, 1L)),
    moving_average = data.frame(Date = clean$Date, Close = x, SMA = ma)
  )
}
