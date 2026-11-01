# Portfolio visualization dashboard

Azadvir Singh | BDA400 Assignment 6 Technical Analysis using R Visualization Phase

## Run in RStudio

1. Extract the ZIP and open the `Assignment06` folder.
2. Set that folder as your working directory. Keep `app.R` and `data/` together.
3. Run `source("install_packages.R")` once. This installs missing shiny, ggplot2, and quantmod packages from CRAN. An internet connection is required for installation.
4. Open `app.R` and select **Run App**, or run `shiny::runApp(".")` in the Console. Do not run the application one line at a time.
5. Use **Stop** in RStudio to stop the application.

The main `app.R` contains the package checks, reused indicator functions, data collection, bar aggregation, signals, chart code, complete UI, server, and shinyApp entry point. All dashboard implementation code is in this one R script as requested. The separate installation helper and test runner are support files.

## Controls

- **Stock:** AAPL, MSFT, or GOOGL.
- **Data source:** included 2025 Yahoo snapshot or a fresh Yahoo Finance request through quantmod::getSymbols. The default is explicitly labeled offline data. Live failures produce an explanatory message; there is no silent fallback.
- **Display dates:** inclusive displayed bar dates. Extra earlier history supports live indicator warm-up. Saved snapshots contain 2025 only.
- **Time frame:** daily, Monday-based weekly, or calendar monthly bars. Periods count bars in that selected timeframe.
- **Chart style:** line, real OHLC candlestick, or area chart.
- **Indicators:** turn moving averages, RSI, and MACD on/off independently. Fast and slow SMAs overlay price with a fast-period EMA; RSI and MACD appear in aligned panels with appropriate units.
- **Scaled overlay:** additionally place RSI/MACD on the price panel with explicit rescaling. Read actual oscillator values in their own panels, not against the price axis.
- **Fast/slow MA and RSI periods:** integer values from 1 through 250; fast must be below slow. Offline monthly testing can use fast 3, slow 6, RSI 3 because only 12 monthly bars are available. Longer periods show warm-up guidance rather than invented signals.
- **Signal rule:** MA crossover alone, or crossover with MACD confirmation.
- **Annotations:** toggle BUY/SELL markers. The Signals and data tab shows actual event rows and recent observations. Hold bars are not cluttered with repeated text.
- **Refresh data:** re-fetches the selected source. Date, symbol, timeframe and period changes also update reactively.
- **Download:** exports all displayed OHLCV, indicator, signal, and example execution columns as CSV.

## Rules and interpretation

Buy is an event where the current fast SMA exceeds slow SMA and the previous fast SMA was at or below slow SMA. Sell is the reverse crossing. Other bars are Hold; the application does not label every bullish bar a new buy. The MACD confirmation option additionally requires MACD above its signal for Buy or below for Sell. Missing MA transitions do not generate events.

Chart annotations mark close-based signals, not completed trades. A flat/long-only example in the export executes valid signals at the next available bar's open, ignoring redundant entries/exits. No brokerage connection, order transmission, return, cost, slippage, or profitability calculation is included. The card shows the latest event within the displayed interval, not a recommendation for today.

The code reuses Assignment 5 SMA, first-price EMA, MACD, and literal-pseudocode RSI. That RSI updates the initialized averages with the last seed change again; it differs from standard Wilder initialization. The chart and Method tab identify this convention. StochRSI is excluded. MACD uses 12/26/9. A flat RSI series uses 50, a loss-free rising series 100, and insufficient history stays missing.

Aggregation uses first Open, maximum High, minimum Low, last Close, summed Volume, and last Adjusted. Adjusted is not an adjusted OHLC series. Candles use raw OHLC. Data after the requested end is removed before grouping so partial weekly/monthly end bars cannot include future days. The start filter operates on aggregate bar dates after calculation; a displayed weekly/monthly bar may begin before the start date. Warm-up bars before the view are retained for calculations. Terminal bars can be partial.

## Actual verification

- R 4.6.2 executed `test_dashboard.R`; 50 automated checks passed.
- A real quantmod Yahoo Finance request returned 250 AAPL rows for 2025.
- Tests cover OHLC validity, sorting, volume reconciliation, date boundaries, partial monthly cutoff, missing warm-up, period validation, crossing events, next-open execution, all chart types, plot layers, and Shiny reactive controls.
- Browser testing confirmed daily charts, monthly aggregation, custom periods, scaled overlays, and CSV download. The downloaded monthly file has 12 rows.
- `evidence/Test_Output.txt` contains the real test log and session versions. `Browser_Checks.txt` records actual UI checks. Two JPEGs are screenshots of the running app, not mockups.
- R startup locale warnings fall back to C and did not prevent execution. UI text uses ASCII so labels remain readable in that environment.

To rerun: `source("test_dashboard.R")`. The runner performs a live request and regenerates the example CSV/price chart. To save a fresh log from a terminal: `Rscript test_dashboard.R > evidence/Test_Output.txt 2>&1`.

## Submission

Upload `Assignment06` under the existing TechnicalAnalysis repository. Keep the data folder in the same location as app.R. The cover document includes the actual repository root and the intended Assignment06 path; this package does not claim that the new folder is already published. Submit the cover page through the LMS after confirming the public repository link works.

Repository: https://github.com/azadvirsingh6-cloud/TechnicalAnalysis
Intended assignment path: https://github.com/azadvirsingh6-cloud/TechnicalAnalysis/tree/main/Assignment06

## Sources and AI assistance

- Yahoo Finance: data source metadata in data/*_source.json. The included 2025 snapshots were retrieved during Assignment 5 preparation.
- quantmod getSymbols: https://www.quantmod.com/documentation/getSymbols.html
- Shiny server testing: https://shiny.posit.co/r/reference/shiny/latest/testserver.html
- ggplot2 segments: https://ggplot2.tidyverse.org/reference/geom_segment.html
- Supplied Assignment 6 PDF: requirements for controls, overlay toggles, charts, rules, and cover page.

OpenAI Codex assisted with code, testing, screenshots and documentation on November 1, 2026 in response to "make this" with the Assignment 6 PDF attached. The code was run and the actual browser states were inspected. No personal student testing history or fabricated screenshot evidence is claimed.
