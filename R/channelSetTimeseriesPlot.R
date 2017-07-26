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
  par(bg='gray95', mar=c(3,3,2,3), oma=c(5,2,4,0))

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
        metricName == 'timing_correction') {
    
    yStyle <- 'zeroScaled'
    
  } else if (metricName == 'percent_availability') {
    
    yStyle <- 'percent'
    
  } else {
    
    yStyle <- 'float'
    
  }
  
  
  

  # ----- Plotting -------------------------------------------------------------
  
  # number of figures to plot
  plotCount <- length(dataList)
  
  mat <- matrix(c(seq(1,plotCount)), plotCount, 1)
  layout(mat)
  
  # plot all data series in dataList
  for (i in seq(plotCount)) {
    df <- dataList[[i]]
    ###timeseriesPlot(df$starttime, df[[metricName]], style, xlim, yStyle)
    # NOTE:  dataframes returned by getSingleValueMetric have "metricName|value|snclq|starttime|endtime|loadtime"
    timeseriesPlot(df$starttime, df$value, style, xlim, yStyle)
    snclq <- unique(df$snclq)[1]
    mtext(snclq, line=0.5, adj=0.05, cex=1.3)
    i <- i + 1
  }
  
  # Add a time axis on the bottom
  ITT <- irisTickTimes(xlim[1],xlim[2])
  axis.POSIXct(1, at=ITT$tickTimes, labels=ITT$tickLabels, line=0)
  

  # ----- Annotations ----------------------------------------------------------

  # Annotations are created in createTextList_en.R
  
  metricTitle <- textList$metricTitlesList[[metricName]]

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
