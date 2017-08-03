########################################################################
# metricTimeseriesPlot.R
#
# Simple plots using 'Quack' (i.e. MATLAB) styling.
#
# Author: Jonathan Callahan
#         Steven Brey
#         Lucy Williams
########################################################################


metricTimeseriesPlot <- function(dataList, infoList, textList, ...) {
 
  logger.info("----- metricTimeseriesPlot -----")
  
  # Get the dataframe of time-sorted data
  df <- dataList[[1]]
  
  # Get items from infoList 
  starttime <- infoList$starttime
  endtime <- infoList$endtime
  xlim <- c(starttime,endtime)

  metricName <- infoList$metricName

  # ----- Style ----------------------------------------------------------------
  
  # Save current par() settings
  oldPar <- par()
  par(bg='gray95', mar=c(.5,3,.5,3), oma=c(5,3,4,0))
  
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
      metricName == 'xxx') {

    yStyle <- 'zeroScaled' 

  } else if (metricName == 'dead_channel_exp' ||
             metricName == 'dead_channel_gsn' ||
             metricName == 'ms_coherence' ||
             metricName == 'gain_ratio') {
    
    yStyle <- 'zeroScaled1' 
    
  } else if (metricName == 'percent_availability' ||
             metricName == 'pct_above_nhnm' ||
             metricName == 'pct_below_nlnm') {

    yStyle <- 'percent' 

  } else {

    yStyle <- 'float' 

  }


  # ----- Plotting -------------------------------------------------------------
  
  timeseriesPlot(df$starttime, df$value, style, xlim, yStyle)
  

  # ----- Annnotation ----------------------------------------------------------

  # Title 
  text <- paste(textList$snclName,'--',textList$metricTitle)
  title(text, outer=TRUE)
    
  # Dates of available data at the bottom
  line <- par('oma')[1] - 1.5  # 1.5 lines off the outer margin bottom
  mtext(textList$dataRange, side=1, line=line, cex=1.3)

  # # Y axis label
  line <- par('oma')[2] + 1.0  # 
  mtext(textList$metricYlab, side=2, line=line, cex=1.0)
  
  
  # Restore old par() settings
  par(oldPar)
  
  return(c(1.0,2.0,3.0,4.0))
  
}
