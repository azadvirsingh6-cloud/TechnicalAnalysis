# Azadvir Singh | BDA400 Assignment 6 Visualization Phase
# AI-assisted implementation by OpenAI Codex, November 1, 2026.
# SECTION 1: packages and indicator implementations reused from Assignment 5.
required_packages <- c("shiny", "ggplot2", "quantmod")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages)) stop("Install packages first: ", paste(missing_packages, collapse = ", "))
suppressPackageStartupMessages(library(shiny))
suppressPackageStartupMessages(library(ggplot2))

# Azadvir Singh | BDA400 Assignment 5
# AI-assisted implementation by OpenAI Codex, November 1, 2026.
# Standard R functions only; no external indicator libraries.
# Compact trailing average; output j belongs to input j + period - 1.
sma <- function(data, period) {
  if (!is.numeric(data) || is.complex(data) || !is.null(dim(data)))
    stop("data must be a real numeric vector.")
  if (!is.numeric(period) || length(period) != 1L || !is.finite(period) ||
      period < 1 || period != floor(period)) stop("period must be a positive integer.")
  if (length(data) < period) stop("Data length should be greater than or equal to the period.")
  if (any(is.infinite(data))) stop("Infinite observations are unsupported.")
  sma_values <- numeric(length(data) - period + 1L)
  for (i in seq_along(sma_values)) {
    window <- data[i:(i + period - 1L)]
    sma_values[i] <- sum(window) / period # NA windows remain missing.
  }
  return(sma_values)
}


# Azadvir Singh | BDA400 Assignment 5
# AI-assisted implementation by OpenAI Codex, November 1, 2026.
# Standard R functions only; no external indicator libraries.
# First-observation seed, exactly as in the assignment pseudocode.
ema <- function(data, period) {
  if (!is.numeric(data) || is.complex(data) || !is.null(dim(data)))
    stop("data must be a real numeric vector.")
  if (!is.numeric(period) || length(period) != 1L || !is.finite(period) ||
      period < 1 || period != floor(period)) stop("period must be a positive integer.")
  if (any(!is.finite(data))) stop("EMA requires finite observations.")
  multiplier <- 2 / (period + 1)
  ema_values <- numeric(length(data))
  if (!length(data)) return(ema_values)
  ema_values[1L] <- data[1L]
  if (length(data) > 1L) for (i in 2:length(data)) {
    ema_values[i] <- (data[i] - ema_values[i - 1L]) * multiplier + ema_values[i - 1L]
  }
  return(ema_values)
}


# Azadvir Singh | BDA400 Assignment 5
# AI-assisted implementation by OpenAI Codex, November 1, 2026.
# Standard R functions only; no external indicator libraries.
# Requires the student's ema() function to have been sourced.
macd <- function(data, short_period, long_period, signal_period) {
  for (value in list(short_period, long_period, signal_period)) {
    if (!is.numeric(value) || length(value) != 1L || !is.finite(value) ||
        value < 1 || value != floor(value)) stop("All MACD periods must be positive integers.")
  }
  if (short_period >= long_period) stop("short_period must be less than long_period.")
  short_ema <- ema(data, short_period)
  long_ema <- ema(data, long_period)
  macd_line <- short_ema - long_ema
  signal_line <- ema(macd_line, signal_period)
  histogram <- macd_line - signal_line
  result <- list(macd_line = macd_line, signal_line = signal_line, histogram = histogram)
  return(result)
}


# Azadvir Singh | BDA400 Assignment 5
# AI-assisted implementation by OpenAI Codex, November 1, 2026.
# Standard R functions only; no external indicator libraries.
# Literal supplied pseudocode: first loop updates the already-initialized
# averages with the last seed change again. This differs from standard Wilder.
rsi <- function(data, period) {
  if (!is.numeric(data) || is.complex(data) || !is.null(dim(data)))
    stop("data must be a real numeric vector.")
  if (!is.numeric(period) || length(period) != 1L || !is.finite(period) ||
      period < 1 || period != floor(period)) stop("period must be a positive integer.")
  if (any(!is.finite(data))) stop("RSI requires finite observations.")
  rsi_values <- rep(NA_real_, length(data))
  if (length(data) <= period) return(rsi_values)
  changes <- diff(data)
  gains <- pmax(changes, 0)
  losses <- pmax(-changes, 0)
  avg_gain <- sum(gains[seq_len(period)]) / period
  avg_loss <- sum(losses[seq_len(period)]) / period
  for (i in seq.int(period + 1L, length(data))) {
    avg_gain <- (avg_gain * (period - 1L) + gains[i - 1L]) / period
    avg_loss <- (avg_loss * (period - 1L) + losses[i - 1L]) / period
    rsi_values[i] <- if (avg_gain == 0 && avg_loss == 0) 50 else if (avg_loss == 0) 100 else
      100 - 100 / (1 + avg_gain / avg_loss)
  }
  return(rsi_values)
}


# SECTION 2: collection, validation, aggregation, and causal rule calculation.
validate_market <- function(d) {
  columns <- c("Date", "Open", "High", "Low", "Close", "Volume", "Adjusted")
  if (!all(columns %in% names(d))) stop("Missing required OHLCV fields.")
  d <- d[, columns, drop = FALSE]; d$Date <- as.Date(d$Date)
  if (!nrow(d) || anyNA(d$Date) || anyDuplicated(d$Date)) stop("No data, invalid dates, or duplicate dates.")
  for (field in columns[-1]) if (!is.numeric(d[[field]]) || any(!is.finite(d[[field]])))
    stop("Missing or invalid market values. Try another range or refresh.")
  if (any(d$Open <= 0 | d$Low <= 0 | d$Close <= 0 | d$High < d$Low | d$Volume < 0 |
          d$High < pmax(d$Open, d$Close) | d$Low > pmin(d$Open, d$Close))) stop("Invalid OHLCV price relationships.")
  d[order(d$Date), , drop = FALSE]
}

fetch_market <- function(symbol, from, to, mode = "saved") {
  if (!symbol %in% c("AAPL", "MSFT", "GOOGL")) stop("Choose a portfolio symbol.")
  if (!mode %in% c("saved", "live")) stop("Invalid data mode.")
  if (mode == "saved") {
    d <- read.csv(file.path("data", paste0(symbol, ".csv")), stringsAsFactors = FALSE)
    source <- "Included Yahoo Finance snapshot (2025)"
  } else {
    x <- tryCatch(quantmod::getSymbols(symbol, src = "yahoo", from = as.Date(from),
       to = as.Date(to) + 1L, auto.assign = FALSE), error = function(e)
       stop("Yahoo Finance request failed. Try again or select the included 2025 snapshot. ", conditionMessage(e)))
    d <- data.frame(Date = as.Date(zoo::index(x)), Open = as.numeric(quantmod::Op(x)),
      High = as.numeric(quantmod::Hi(x)), Low = as.numeric(quantmod::Lo(x)),
      Close = as.numeric(quantmod::Cl(x)), Volume = as.numeric(quantmod::Vo(x)),
      Adjusted = as.numeric(quantmod::Ad(x)))
    source <- "Yahoo Finance live request"
  }
  d <- validate_market(d)
  d <- d[d$Date >= as.Date(from) & d$Date <= as.Date(to), , drop = FALSE]
  if (!nrow(d)) stop("No observations in this range. The offline snapshot covers 2025 only.")
  list(data = d, source = source, accessed = format(Sys.time(), tz = "America/Toronto"))
}

aggregate_bars <- function(d, timeframe = "Daily") {
  if (!timeframe %in% c("Daily", "Weekly", "Monthly")) stop("Invalid timeframe.")
  d <- validate_market(d)
  if (timeframe == "Daily") return(d)
  key <- if (timeframe == "Weekly") as.character(cut(d$Date, "week", start.on.monday = TRUE)) else format(d$Date, "%Y-%m")
  out <- do.call(rbind, lapply(split(d, key), function(g) data.frame(Date = tail(g$Date, 1),
    Open = g$Open[1], High = max(g$High), Low = min(g$Low), Close = tail(g$Close,1),
    Volume = sum(g$Volume), Adjusted = tail(g$Adjusted,1))))
  rownames(out) <- NULL; out
}

make_signals <- function(fast, slow, macd_line, signal_line, strategy = "MA crossover") {
  if (length(fast) != length(slow)) stop("Unequal MA lengths.")
  n <- length(fast); result <- rep("Hold", n)
  if (n > 1L) for (i in 2:n) {
    if (!all(is.finite(c(fast[i], slow[i], fast[i-1], slow[i-1])))) next
    up <- fast[i] > slow[i] && fast[i-1] <= slow[i-1]
    down <- fast[i] < slow[i] && fast[i-1] >= slow[i-1]
    if (strategy == "MA + MACD confirmation") {
      up <- up && is.finite(macd_line[i]) && macd_line[i] > signal_line[i]
      down <- down && is.finite(macd_line[i]) && macd_line[i] < signal_line[i]
    }
    if (up) result[i] <- "Buy" else if (down) result[i] <- "Sell"
  }
  result
}

prepare_data <- function(d, timeframe, start, end, fast_period, slow_period, rsi_period, strategy) {
  for (period in list(fast_period,slow_period,rsi_period)) if (length(period)!=1L ||
    !is.numeric(period) || !is.finite(period) || period<1 || period!=floor(period) || period>250)
    stop("Indicator periods must be integers from 1 to 250.")
  if (fast_period >= slow_period) stop("Fast MA must be shorter than slow MA.")
  if (as.Date(start) > as.Date(end)) stop("Start date must precede end date.")
  # Remove observations after the selected end BEFORE any monthly/weekly grouping.
  # This prevents a bar from incorporating a future date beyond the requested range.
  d <- d[d$Date <= as.Date(end), , drop = FALSE]
  if (!nrow(d)) stop("No observations before the selected end date.")
  d <- aggregate_bars(d, timeframe); n <- nrow(d)
  aligned_sma <- function(x, period) if (length(x)<period) rep(NA_real_,length(x)) else
    c(rep(NA_real_,period-1L),sma(x,period))
  d$FastMA <- aligned_sma(d$Close, fast_period); d$SlowMA <- aligned_sma(d$Close, slow_period)
  d$EMA <- ema(d$Close,fast_period); d$RSI <- rsi(d$Close,rsi_period)
  m <- macd(d$Close,12,26,9);d$MACD <- m$macd_line;d$MACDSignal <- m$signal_line;d$Histogram <- m$histogram
  d$Ready <- is.finite(d$FastMA) & is.finite(d$SlowMA)
  d$Signal <- make_signals(d$FastMA,d$SlowMA,d$MACD,d$MACDSignal,strategy)
  # Execution is a next-bar illustration, not a backtest or brokerage order.
  d$Execution <- rep("None",n);d$Position <- integer(n);held <- 0L
  if (n>1L) for (i in 2:n) {
    if (d$Signal[i-1L]=="Sell" && held==1L) {d$Execution[i]<-"Sell";held<-0L}
    else if (d$Signal[i-1L]=="Buy" && held==0L) {d$Execution[i]<-"Buy";held<-1L}
    d$Position[i]<-held
  }
  d$ExecutionPrice <- ifelse(d$Execution=="None",NA_real_,d$Open)
  d <- d[d$Date>=as.Date(start) & d$Date<=as.Date(end), , drop=FALSE]
  if (!nrow(d)) stop("No trading bars in the selected display interval.")
  d
}

# SECTION 3: plots. MA overlays retain price units; optional RSI/MACD overlays
# are explicitly scaled, while separate panels retain their original units.
make_price_plot <- function(d, symbol, chart_type, indicators, annotations, scaled, fast_period, slow_period) {
  theme <- theme_minimal(base_size=12)+theme(panel.grid.minor=element_blank(),
    legend.position="bottom",plot.title=element_text(face="bold",color="#163144"))
  g <- ggplot(d,aes(x=Date))
  width <- if(nrow(d)>1L) max(.5,as.numeric(stats::median(diff(d$Date)))*.65) else .65
  if(chart_type=="Candlestick") {
    g <- g+geom_segment(aes(xend=Date,y=Low,yend=High),color="#63798a",linewidth=.35)+
      geom_rect(aes(xmin=Date-width/2,xmax=Date+width/2,ymin=pmin(Open,Close),
        ymax=pmax(Open,Close),fill=Close>=Open),color=NA)+
      geom_segment(aes(xend=Date+width/2,y=Close,yend=Close),linewidth=.35)+
      scale_fill_manual(values=c("TRUE"="#167d8d","FALSE"="#bd5b55"),guide="none")
  } else if(chart_type=="Area") {
    g<-g+geom_area(aes(y=Close),fill="#167d8d",alpha=.17)+geom_line(aes(y=Close),color="#167d8d",linewidth=.7)
  } else g<-g+geom_line(aes(y=Close),color="#167d8d",linewidth=.8)
  if("Moving averages" %in% indicators) g<-g+
    geom_line(aes(y=FastMA,color="Fast SMA"),linewidth=.75,na.rm=TRUE)+
    geom_line(aes(y=SlowMA,color="Slow SMA"),linewidth=.8,na.rm=TRUE)+
    geom_line(aes(y=EMA,color="Fast EMA"),linewidth=.55,linetype="dotted",na.rm=TRUE)
  bottom<-min(d$Low);top<-max(d$High);span<-max(top-bottom,top*.01)
  if(scaled && "RSI" %in% indicators) g<-g+geom_line(aes(y=bottom+RSI/100*span,color="RSI scaled"),linetype="dashed",na.rm=TRUE)
  if(scaled && "MACD" %in% indicators) {
    bound<-max(abs(c(d$MACD,d$MACDSignal)),na.rm=TRUE);if(bound==0)bound<-1
    g<-g+geom_line(aes(y=bottom+(MACD/bound+1)/2*span,color="MACD scaled"),linetype="dotdash",na.rm=TRUE)
  }
  if(annotations) {
    buys<-d[d$Signal=="Buy",];sells<-d[d$Signal=="Sell",]
    g<-g+geom_point(data=buys,aes(y=Low-span*.04),shape=24,size=3,fill="#167d8d",color="#167d8d")+
      geom_text(data=buys,aes(y=Low-span*.09,label="BUY"),color="#126877",size=3,fontface="bold")+
      geom_point(data=sells,aes(y=High+span*.04),shape=25,size=3,fill="#bd5b55",color="#bd5b55")+
      geom_text(data=sells,aes(y=High+span*.09,label="SELL"),color="#a44843",size=3,fontface="bold")
  }
  if("Moving averages" %in% indicators || (scaled && any(c("RSI","MACD") %in% indicators)))
    g<-g+scale_color_manual(values=c("Fast SMA"="#3267b1","Slow SMA"="#d28a31","Fast EMA"="#71808e",
    "RSI scaled"="#8b64ad","MACD scaled"="#b05b87"),name=NULL)
  g+coord_cartesian(ylim=c(bottom-span*.14,top+span*.14))+
    labs(title=paste(symbol,"price and signals"),subtitle=paste(chart_type,"| SMA",fast_period,"/",slow_period),
      x=NULL,y="Unadjusted price (USD)",caption=if(scaled)"RSI/MACD price overlays are scaled for visual comparison only." else NULL)+theme
}
make_rsi_plot <- function(d) ggplot(d,aes(Date,RSI))+geom_hline(yintercept=c(30,70),linetype="dashed",color="#a6b1bc")+
  geom_line(color="#8b64ad",linewidth=.7,na.rm=TRUE)+coord_cartesian(ylim=c(0,100))+
  labs(title="RSI - Assignment 5 convention",x=NULL,y="RSI (0-100)")+
  theme_minimal(base_size=11)+theme(panel.grid.minor=element_blank(),plot.title=element_text(face="bold",size=12))
make_macd_plot <- function(d) ggplot(d,aes(Date))+
  geom_col(aes(y=Histogram),fill="#cdd9e3",width=if(nrow(d)>1)max(.5,as.numeric(median(diff(d$Date)))*.65) else .6)+
  geom_line(aes(y=MACD,color="MACD"),linewidth=.7)+geom_line(aes(y=MACDSignal,color="Signal"),linewidth=.6)+
  scale_color_manual(values=c("MACD"="#3267b1","Signal"="#d28a31"),name=NULL)+
  labs(title="MACD 12 / 26 / 9",x=NULL,y="Difference (USD)")+theme_minimal(base_size=11)+
  theme(legend.position="bottom",panel.grid.minor=element_blank(),plot.title=element_text(face="bold",size=12))

# SECTION 4: Shiny UI and interactive controls.
ui <- fluidPage(
  tags$head(tags$style(HTML("
    body {background:#f4f7fa;color:#213547;font-family:Arial,sans-serif;}
    .topbar {background:#17364a;color:white;padding:24px 28px;margin:0 -15px 22px;}
    .topbar h1 {margin:0 0 7px;font-size:28px;font-weight:700;}
    .topbar p {margin:0;color:#d3e3ec;}
    .well {background:white;border:1px solid #dce4eb;border-radius:10px;box-shadow:none;}
    .mainpanel {background:white;border:1px solid #dce4eb;border-radius:10px;padding:20px;}
    .metric {background:#edf4f8;border-radius:8px;padding:14px;margin:12px 0;min-height:88px;}
    .metric .labeltext {font-size:12px;color:#5a6c7b;}
    .metric .value {font-size:23px;font-weight:bold;color:#17364a;}
    .note {font-size:12px;color:#5e7283;line-height:1.5;}
    .source {padding:10px 0;color:#526a7c;font-size:12px;}
    .btn-primary {background:#167d8d;border-color:#167d8d;}
    .nav-tabs {margin-bottom:14px;}
  "))),
  div(class="topbar",h1("Portfolio dashboard"),p("Azadvir Singh  |  BDA400  |  Technical Analysis Visualization")),
  sidebarLayout(
    sidebarPanel(width=3,
      selectInput("symbol","Stock",c("Apple - AAPL"="AAPL","Microsoft - MSFT"="MSFT","Alphabet - GOOGL"="GOOGL")),
      selectInput("data_mode","Data source",c("Included 2025 snapshot (offline)"="saved","Yahoo Finance (live request)"="live")),
      dateRangeInput("date_range","Display dates",start="2025-01-01",end="2025-12-31",max=Sys.Date(),format="yyyy-mm-dd"),
      selectInput("time_frame","Time frame",c("Daily","Weekly","Monthly")),
      selectInput("chart_type","Chart style",c("Candlestick","Line","Area")),
      checkboxGroupInput("technical_indicators","Indicators",c("Moving averages","RSI","MACD"),selected=c("Moving averages","RSI","MACD")),
      fluidRow(column(6,numericInput("fast_period","Fast MA",20,min=1,max=249,step=1)),
               column(6,numericInput("slow_period","Slow MA",50,min=2,max=250,step=1))),
      numericInput("rsi_period","RSI period",14,min=1,max=250,step=1),
      selectInput("strategy","Signal rule",c("MA crossover","MA + MACD confirmation")),
      checkboxInput("annotations","Show buy / sell annotations",TRUE),
      checkboxInput("scaled_overlay","Also overlay scaled RSI / MACD on price",FALSE),
      actionButton("refresh","Refresh data",class="btn-primary"),
      br(),br(),downloadButton("download_csv","Download displayed data"),
      p(class="note","Periods count bars in the selected time frame. Offline data covers 2025. Live requests include extra history for indicator warm-up.")
    ),
    mainPanel(width=9,div(class="mainpanel",
      uiOutput("metrics"),div(class="source",textOutput("source_status")),
      tabsetPanel(id="view_tab",
        tabPanel("Charts",textOutput("warmup_note"),plotOutput("stock_chart",height="460px"),uiOutput("indicator_panels")),
        tabPanel("Signals and data",h4("Crossover events"),tableOutput("signals_table"),h4("Latest displayed observations"),tableOutput("data_table")),
        tabPanel("Method",h4("Rules and timing"),
          p("Buy occurs only when the fast SMA crosses above the slow SMA; sell occurs only when it crosses below. Other bars are Hold. The confirmation rule additionally requires MACD above its signal for buys and below for sells."),
          p("Annotations mark close-based signals, not completed trades. The data export includes a flat/long-only execution example using the next bar's open. No transaction costs or performance claims are included."),
          h4("Indicators and units"),
          p("SMA, first-price-seeded EMA, MACD and the literal Assignment 5 RSI implementation are reused. RSI repeats the last seed change as specified in that assignment, so it differs from conventional Wilder initialization. StochRSI is not used."),
          p("Moving averages share price units. RSI and MACD have separate panels. Optional price overlays scale oscillators for visual comparison only; use their own panels for actual values."),
          p("The offline option uses the included Yahoo snapshots. Switching to live invokes quantmod::getSymbols; failures are displayed without silently substituting other data. No user input is uploaded to a trading service."),
          p("Weekly bars begin Monday. Bars are labeled with the last trading date, aggregate OHLCV correctly, and stop at the requested end date. Warm-up history is used before display filtering."))
      ),p(class="note","Educational analysis only. Signals are rule demonstrations, not investment recommendations.")
    ))
  )
)

# SECTION 5: reactive server, validation, downloads, and app entry point.
server <- function(input,output,session) {
  fetched <- reactive({
    input$refresh
    req(input$symbol,input$date_range,input$data_mode,input$slow_period,input$time_frame)
    validate(need(length(input$date_range)==2 && !anyNA(input$date_range),"Choose a valid date range."))
    validate(need(input$date_range[1]<=input$date_range[2],"Start date must precede end date."))
    # Include enough calendar history for daily, weekly, or monthly warm-up.
    factor <- switch(input$time_frame,Daily=3,Weekly=10,Monthly=35)
    history <- max(input$slow_period,input$rsi_period,26)*factor+90
    tryCatch(fetch_market(input$symbol,as.Date(input$date_range[1])-history,
      input$date_range[2],input$data_mode),error=function(e) list(error=conditionMessage(e)))
  })
  prepared <- reactive({
    f<-fetched();validate(need(is.null(f$error),f$error))
    req(input$fast_period,input$slow_period,input$rsi_period,input$strategy)
    tryCatch(prepare_data(f$data,input$time_frame,input$date_range[1],input$date_range[2],
      input$fast_period,input$slow_period,input$rsi_period,input$strategy),error=function(e)
      validate(need(FALSE,conditionMessage(e))))
  })
  price_plot <- reactive({
    make_price_plot(prepared(),input$symbol,input$chart_type,input$technical_indicators,
      isTRUE(input$annotations),isTRUE(input$scaled_overlay),input$fast_period,input$slow_period)
  })
  output$stock_chart<-renderPlot({print(price_plot())},res=110)
  output$indicator_panels<-renderUI({
    tagList(if("RSI" %in% input$technical_indicators)plotOutput("rsi_chart",height="220px"),
            if("MACD" %in% input$technical_indicators)plotOutput("macd_chart",height="250px"))
  })
  output$rsi_chart<-renderPlot({print(make_rsi_plot(prepared()))},res=110)
  output$macd_chart<-renderPlot({print(make_macd_plot(prepared()))},res=110)
  output$source_status<-renderText({f<-fetched();validate(need(is.null(f$error),f$error));
    paste(f$source," |  accessed",f$accessed,"America/Toronto  | ",input$time_frame)})
  output$warmup_note<-renderText({d<-prepared();if(!any(d$Ready))
    "Not enough bars for the slow MA. Choose shorter periods or a longer/live history; signals remain Hold." else
    if(any(!d$Ready))"Initial bars lack MA history; no events are generated until both MAs are available." else ""})
  output$metrics<-renderUI({
    d<-prepared();last<-tail(d,1);events<-d[d$Signal!="Hold",,drop=FALSE]
    latest_event<-if(nrow(events))paste(tail(events$Signal,1),format(tail(events$Date,1))) else "No events"
    metric<-function(label,value)column(4,div(class="metric",div(class="labeltext",label),div(class="value",value)))
    fluidRow(metric("Last displayed close (USD)",sprintf("%.2f",last$Close)),
      metric("Displayed bars",format(nrow(d),big.mark=",")),metric("Latest crossover event",latest_event))
  })
  output$signals_table<-renderTable({d<-prepared();e<-d[d$Signal!="Hold",c("Date","Close","FastMA","SlowMA","Signal")];
    if(!nrow(e))data.frame(Status="No crossover events in the selected interval") else {e$Date<-as.character(e$Date);tail(e,25)}},digits=2,striped=TRUE)
  output$data_table<-renderTable({d<-tail(prepared()[,c("Date","Open","High","Low","Close","Volume","Signal","Ready")],15);d$Date<-as.character(d$Date);d},digits=2,striped=TRUE)
  output$download_csv<-downloadHandler(filename=function()paste0(input$symbol,"_",input$time_frame,"_dashboard.csv"),
    content=function(file)write.csv(prepared(),file,row.names=FALSE,na=""))
}
shinyApp(ui=ui,server=server)
