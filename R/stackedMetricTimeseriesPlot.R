########################################################################
# stackedMetricTimeseriesPlot.R
#
# Multilpe plots at once using minimalist styling.
#
# Author: Jonathan Callahan
#         Lucy Williams
########################################################################


stackedMetricTimeseriesPlot <- function(dataList, infoList, textList, ...) {
 
  logger.info("----- stackedMetricTimeseriesPlot -----")
  
  # Get items from infoList 
  metricName<- infoList$metricName 
  starttime <- infoList$starttime
  endtime <- infoList$endtime
  xlim <- c(starttime,endtime)

  # ----- Style ----------------------------------------------------------------
  
  # Save current par() settings
  oldPar <- par()
  par(bg='gray95', mar=c(.5,3,.5,3), oma=c(5,2,4,0))

  if ( metricName == 'SOH_flags' ) {
    style <- 'minimalA'
    actualMetricNames <- c("amplifier_saturation",
                           "digitizer_clipping",
                           "spikes",
                           "glitches",
                           "missing_padded_data",
                           "telemetry_sync_error",
                           "digital_filter_charging",
                           "suspect_time_tag",
                           "calibration_signal",
                           "timing_correction",
                           "event_begin",
                           "event_end",
                           "event_in_progress",
                           "clock_locked") 
    yStyles <- rep('zeroScaled',length(actualMetricNames))
  } else if ( metricName == 'gaps_and_availability' ) {
    style <- 'minimalA'
    if (infoList$archive == "fdsnws") {
       actualMetricNames <- c("ts_num_gaps",
                           "ts_max_gap",
                           "ts_percent_availability",
                           "ts_gap_length") 
    } else {
       actualMetricNames <- c("num_gaps",
                           "max_gap",
                           "percent_availability")
    }
    yStyles <- c('zeroScaled','zeroScaled','zeroScaled','zeroScaled','percent')
  } else if ( metricName == 'basic_stats' ) {
    style <- 'minimalA'
    actualMetricNames <- c("sample_max",
                           "sample_min",
                           "sample_mean",
                           "sample_median",
                           "sample_rms") 
    yStyles <- c(rep('float',5))
  } else if ( metricName == 'latency' ) {
    style <- 'minimalA'
    actualMetricNames <- c("data_latency",
                           "feed_latency",
                           "total_latency") 
    yStyles <- c(rep('zeroScaled',3))
  } else if ( metricName == 'transfer_function' ) {
    style <- 'minimalA'
    actualMetricNames <- c("ms_coherence",
                           "gain_ratio",
                           "phase_diff") 
    yStyles <- c('zeroScaled1','zeroScaled1','float')
  } else {
    style='minimalA'
    actualMetricNames <- metricName
    yStyles <- rep('zeroScaled',length(actualMetricNames))
  }
  

  # ----- Plotting -------------------------------------------------------------
  
  # number of figures to plot
  plotCount <- length(actualMetricNames)
  
  mat <- matrix(c(seq(1,plotCount)), plotCount, 1)
  layout(mat)
  
  # plot all data series in dataList
  for (i in seq(plotCount)) {
    # NOTE:  transfer_function is unique in that a request for it returns a single dataframe
    # NOTE:  with three separate variables:  ms_coherence, gain_ratio, phase_diff
    if ( metricName == 'transfer_function' ) {
      df <- dataList[[1]]
    } else {
      df <- dataList[[actualMetricNames[i]]]
    }
    tempMetricName <- actualMetricNames[i]
    metricTitle <- textList$metricTitlesList[[tempMetricName]]
    yStyle <- yStyles[i]
    # NOTE:  transfer function metrics phase_diff and ms_coherence are in their own columns rather than 'value'
    if ( tempMetricName == 'phase_diff' ) {
      metricValues <- df$phase_diff
    } else if ( tempMetricName == 'ms_coherence' ) {
      metricValues <- df$ms_coherence
    } else if ( tempMetricName == 'gain_ratio') {
      metricValues <- df$gain_ratio
    } else {
      metricValues <- df$value
    }
    timeseriesPlot(df$starttime, metricValues, style, xlim, yStyle)
    mtext(metricTitle, line=-1.5, adj=0.05, cex=1.3)
    i <- i + 1
  }
  
  # Add a time axis on the bottom
  ITT <- irisTickTimes(xlim[1],xlim[2])
  axis.POSIXct(1, at=ITT$tickTimes, labels=ITT$tickLabels, line=0)
  

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
