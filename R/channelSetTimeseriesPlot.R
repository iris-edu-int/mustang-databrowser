########################################################################
# channelSetTimeseriesPlot.R
#
# Multilpe channels at once using matlab styling.
#
# Author: Jonathan Callahan
#         Lucy Williams
########################################################################


channelSetTimeseriesPlot <- function(dataList, infoList, textList, ...) {

  logger.info("----- channelSetTimeseriesPlot -----")
  
  # Get items from infoList 
  metricName <- infoList$metricName
  starttime <- infoList$starttime
  endtime <- infoList$endtime
  xlim <- c(starttime,endtime)

  # ----- Style ----------------------------------------------------------------
  
  # Save current par() settings
  oldPar <- par()
  par(bg='gray95', mar=c(3,3,2,3), oma=c(5,3,4,0))

  style <- 'matlab'

  # Y-axis styling depends on the metric
  if (metricName == 'num_gaps' ||
      metricName == 'num_overlaps' ||
      metricName == 'num_spikes' ||
      metricName == 'max_gap' ||
      metricName == 'max_overlap' ||
      metricName == 'data_latency' ||
      metricName == 'feed_latency' ||
      metricName == 'total_latency' ||
      metricName == 'timing_quality' ||
      metricName == 'amplifier_saturation' ||
      metricName == 'calibration_signal' ||
      metricName == 'clock_locked' ||
      metricName == 'digital_filter_charging' ||
      metricName == 'digitizer_clipping' ||
      metricName == 'event_begin' ||
      metricName == 'event_end' ||
      metricName == 'event_in_progress' ||
      metricName == 'missing_padded_data' ||
      metricName == 'suspect_tim_gat' ||
      metricName == 'telemetry_sync_error' ||
      metricName == 'timing_correction' ||
      metricName == 'sample_unique' ||
      metricName == 'dead_channel_lin' ||
      metricName == 'ts_num_gaps' ||
      metricName == 'ts_max_gap' ||
      metricName == 'ts_gap_length' ||
      metricName == 'ts_channel_up_time' ||
      metricName == 'xxx') {
    
    yStyle <- 'zeroScaled' 
    
  } else if (metricName == 'dead_channel_exp' ||
             metricName == 'ms_coherence' ||
             metricName == 'gain_ratio' ||
             metricName == 'xxx') {
    
    yStyle <- 'zeroScaled1' 
    
  } else if (metricName == 'dead_channel_gsn') {
    
    yStyle <- 'zeroOrOne' 
    
  } else if (metricName == 'cross_talk' ||
             metricName == 'polarity_check' ||
             metricName == 'xxx') {
    
    yStyle <- 'zeroCentered1'
    
  } else if (metricName == 'percent_availability' ||
             metricName == 'ts_percent_availability' ||
             metricName == 'pct_above_nhnm' ||
             metricName == 'pct_below_nlnm') {
    
    yStyle <- 'percent' 
    
  } else {
    
    yStyle <- 'float' 
    
  }
  
  
  

  # ----- Plotting -------------------------------------------------------------
  
  # number of figures to plot
  plotCount <- length(dataList)
  
  mat <- matrix(c(seq(1,plotCount)), plotCount, 1)
  layout(mat)
  
  # dataframe column name for values
  if ( metricName == 'gain_ratio' ) { valueName <- "gain_ratio" }
  else if ( metricName == 'phase_diff' ) { valueName <- "phase_diff" }
  else if ( metricName == 'ms_coherence' ) { valueName <- "ms_coherence" }
  else { valueName <- "value" }

  # limits for group scaling
  ymax <- max(unlist(lapply(dataList, function(x) max(x[,valueName],na.rm=TRUE))))
  ymin <- min(unlist(lapply(dataList, function(x) min(x[,valueName],na.rm=TRUE))))
  yRange <- c(ymin,ymax)
  
  # plot all data series in dataList
  for (i in seq(plotCount)) {
    df <- dataList[[i]]
    metricValues <- df[,valueName]

    if (infoList$timeseriesScale) {
       timeseriesPlot(df$starttime, metricValues, style, xlim, yStyle, yRange=yRange)
    } else {
       timeseriesPlot(df$starttime, metricValues, style, xlim, yStyle)
    }

    # NOTE:  For polarity_check we need to include the second station
    if ( metricName == 'polarity_check' ) {
      snclq1 <- substr(df$snclq[1],1,nchar(df$snclq[1])-2)
      snclq2s <- unique(df$snclq2)
      snclq2s <- substr(snclq2s,1,nchar(snclq2s)-2)
      if (length(snclq2s) == 1) {
         snclq2s <- paste0(snclq2s, collapse=", ")
      } else if (length(snclq2s) == 2) {
         snclq2s <- paste0(snclq2s, collapse=", ")
         snclq2s <- paste0("[",snclq2s,"]")
      } else {
         staNum2 <- length(snclq2s) -2
         snclq2s <- paste(paste0(snclq2s[1:2], collapse=", "),"+",staNum2,"additional")
         snclq2s <- paste0("[",snclq2s,"]")
      }
      snclq <- paste0(snclq1,":",snclq2s)
    } else {
      snclq <- df$snclq[1]
    }
    mtext(snclq, line=0.5, adj=0.05, cex=1.3)
    i <- i + 1
    # Y axis label
    # NOTE:  for transfer functions we skip the y axis
    line <- par('oma')[2] + 2  # 
    mtext(textList$metricYlab, side=2, line=line, cex=1.0)
   
  }
  

  # ----- Annotations ----------------------------------------------------------

  # Annotations are created in createTextList_en.R
  
  # Title at the top
  text <- paste(textList$snclName,'--',textList$metricTitle)
  title(text, outer=TRUE)

  # Dates of available data at the bottom
  line <- par('oma')[1] - 1.5  # 1.5 lines off the outer margin bottom
  mtext(textList$dataRange, side=1, line=line, cex=1.3)

  # Restore old par() settings
  par(oldPar)
  
  return(c(1.0,2.0,3.0,4.0))
  
}
