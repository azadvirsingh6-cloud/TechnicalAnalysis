# BDA400 Assignment 2

Author: Azadvir Singh  
Project: Technical Analysis using R Preliminary Stage

## Run

Open this folder in RStudio as a project or set the working directory to `Assignment02`. Then run:

```r
source("01_setup.R")
source("04_run_analysis.R")
```

Internet access is required for package installation and Yahoo Finance data. The example portfolio contains AAPL, MSFT, and GOOGL; these are assignment examples, not investment recommendations. The requested interval is January 1, 2025 through December 31, 2025. Provider availability and date handling must be checked after import.

## Files and outputs

- `portfolio.txt`: one symbol per line.
- `01_setup.R`: installs missing packages and displays versions.
- `02_functions.R`: loads each stock into a separate data frame within a named list and computes statistics.
- `03_display.R`: displays tables and saves CSV files and price/SMA charts.
- `04_run_analysis.R`: runs the workflow and records failures and session information.
- Word report: methods, setup procedure, and screenshot evidence checklist.

Statistics use finite unadjusted daily closing prices, not returns. The mode includes all tied repeated values; when every value is unique, it reports no repeated value. SD is sample standard deviation. The trailing SMA uses 20 retained observations, leaving initial values missing. Missing/nonfinite closes are excluded and counted; this can make a window span more than 20 original trading records. Prices are not rounded before finding the mode.

## Verification status

Code has been reviewed statically but has not been executed in R here. No real numerical outputs, installation screenshots, or GitHub link are included. Run the workflow, inspect the saved files, add genuine screenshots to the report, and upload the files under `TechnicalAnalysis/Assignment02` in your GitHub repository.

## AI disclosure

OpenAI Codex assisted with code, documentation, and report preparation in response to "make this" with the Assignment 2 PDF attached. Review the code and disclose this assistance according to your course rules.
