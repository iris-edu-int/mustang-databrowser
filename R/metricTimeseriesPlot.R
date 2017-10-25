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
             metricName == 'pct_above_nhnm' ||
             metricName == 'pct_below_nlnm') {

    yStyle <- 'percent' 

  } else {

    yStyle <- 'float' 

  }


  # ----- Plotting -------------------------------------------------------------
 
  # NOTE:  transfer function metrics phase_diff and ms_coherence are in their own columns rather than 'value'
  if ( metricName == 'gain_ratio' ) {
    metricValues <- df$gain_ratio
  } else if ( metricName == 'phase_diff' ) {
    metricValues <- df$phase_diff
  } else if ( metricName == 'ms_coherence' ) {
    metricValues <- df$ms_coherence
  } else {
    metricValues <- df$value
  }
  
  timeseriesPlot(df$starttime, metricValues, style, xlim, yStyle)
  

  # ----- Annnotation ----------------------------------------------------------

  # Annotations are created in createTextList_en.R
  
  # Title at the top
  text <- paste(textList$snclName,'--',textList$metricTitle)
  title(text, outer=TRUE)
  
  # For polarity_check, add snclq2 underneath the title
  if ( metricName == 'polarity_check' ) {
    snclq2s <- unique(df$snclq2)
    snclq2s <- substr(snclq2s,1,nchar(snclq2s)-2)
    if (length(snclq2s) <= 2) {
      snclq2s <- paste0(snclq2s, collapse=", ")
    } else {
      staNum2 <- length(snclq2s) -2
      snclq2s <- paste(paste0(snclq2s[1:2], collapse=", "),"+",staNum2,"additional")
    }
    text <- paste0('Nearest stations: ',snclq2s)
    mtext(text, side=3, line=0.5, cex=1.3)
  }
    
  # Dates of available data at the bottom
  line <- par('oma')[1] - 1.5  # 1.5 lines off the outer margin bottom
  mtext(textList$dataRange, side=1, line=line, cex=1.3)

  # Y axis label
  line <- par('oma')[2] + 1.5  # 
  mtext(textList$metricYlab, side=2, line=line, cex=1.0)
  
  # Restore old par() settings
  par(oldPar)
  
  return(c(1.0,2.0,3.0,4.0))
  
}
