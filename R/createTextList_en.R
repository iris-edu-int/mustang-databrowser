########################################################################
# textList_en.R
#
# English language text strings for plot annotations.
#
# Author: Jonathan Callahan
########################################################################

createTextList <- function(dataList, infoList) {

  logger.info("----- createTextList -----")
  
  # Create empty textList
  textList <- list()
  
  # Get useful variables from infoList
  metricName <- infoList$metricName

  # ----- Common annotations ---------------------------------------------------
  
  # NOTE:  Metrics are described here:
  # NOTE:  
  # NOTE:  http://service.iris.edu/mustang/metrics/1/query
  
  # Add a metric title
  metricTitles <- list(amplifier_saturation='MiniSEED Flag Count: Amplifier Saturation Detected',
                       calibration_signal='MiniSEED Flag Count: Calibration Signals Present',
                       clock_locked='MiniSEED Flag Count: Clock locked',
                       cross_talk='Cross-Talk Check: Channel Cross-Correlation Coefficient',
                       data_latency='Time Since Last Data Sample Was Acquired',
                       dc_offset='Indicator of Likelihood of DC Offset Shift',
                       dc_offset_times='Times of DC Offsets Detected',
                       dead_channel_exp='Dead Channel Metric: Exponential Fit',
                       dead_channel_gsn='Dead Channel Metric: GSN',
                       dead_channel_lin='Dead Channel Metric: Linear Fit',
                       digital_filter_charging='MiniSEED Flag Count: Digital Filter Charging',
                       digitizer_clipping='MiniSEED Flag Count: Digitizer Clipping Detected',
                       event_begin='MiniSEED Flag Count: Beginning of Event (Trigger)',
                       event_end='MiniSEED Flag Count: End of Event (Detrigger)',
                       event_in_progress='MiniSEED Flag Count: Event in Progress',
                       feed_latency='Time Since Latest Data Was Received',
                       gap_list='Data Gap Durations',
                       glitches='MiniSEED Flag Count: Glitches Detected',
                       max_gap='Maximum Gap Length',
                       max_overlap='Maximum Overlap Length',
                       max_stalta='Maximum Short-Term Average/Long-Term Average Amplitude Ratio',
                       missing_padded_data='MiniSEED Flag Count: Missing/Padded Data Present',
                       num_gaps='Number of Gaps',
                       num_overlaps='Number of Overlaps',
                       num_spikes='Number of Spikes',
                       pct_above_nhnm='Percent Above New High Noise Model',
                       pct_below_nlnm='Percent Below New Low Noise Model',
                       percent_availability='Channel Percent Data Available',
                       polarity_check='Nearest Station Polarity Reversal Check',
                       pressure_effects='Atmospheric Pressure Check: Barometer-Seismometer Cross-Correlation Coefficient',
                       sample_max='Maximum Amplitude',
                       sample_mean='Mean Amplitude',
                       sample_median='Median Amplitude',
                       sample_min='Minimum Amplitude',
                       sample_rms='Root-Mean-Squared-Variance of Amplitudes',
                       sample_snr='P-Wave Signal-To-Noise Ratio',
                       sample_unique='Count of Unique Sample Values',
                       spikes='MiniSEED Flag Count: Spikes Detected',
                       station_completeness='Station Percent Data Available',
                       station_up_down_times='Station Up/Down Time Spans',
                       suspect_time_tag='MiniSEED Flag Count: Time Tag Questionable',
                       telemetry_sync_error='MiniSEED Flag Count: Telemetry Synchronization Error',
                       timing_correction='MiniSEED Flag Count: Timing Correction Applied',
                       timing_quality='MiniSEED Average Timing Quality',
                       total_latency='Total Latency',
                       ts_num_gaps='TsIndex Number of Gaps',
                       ts_max_gap='TsIndex Maximum Gap Length',
                       ts_gap_length='TsIndex Sum of Gap Lengths in Seconds',
                       ts_percent_availability='TsIndex Channel Percent Data Available',
                       ts_channel_up_time='TsIndex Durations of Continuous Data',
                       up_down_times='Channel Up/Down Time Spans',

                       # multi-metrics
                       basic_stats='Basic Statistics',
                       latency='Latency',
                       gaps_and_availability='Gaps and Availability',
                       SOH_flags='State-of-Health Daily Flag Counts',
                       transfer_function='Transfer Function Metrics',
                       # names within the transfer function dataframe
                       ms_coherence='Coherence',
                       gain_ratio='Gain Ratio',
                       phase_diff='Phase Difference (deg)',    
                       xxx='xxx')

  textList$metricTitlesList <- metricTitles

  textList$metricTitle <- metricTitles[[metricName]]

  # Add a metric Y-axis label
  metricYlabs <- list(amplifier_saturation='flag count (number of occurrences)',
                      calibration_signal='flag count (number of occurrences)',
                      clock_locked='flag count (number of occurrences)',
                      cross_talk='correlation coefficient', # no units
                      data_latency='latency (seconds)',
                      dc_offset='indicator of likelihood of DC offset shift', # no units
                      dead_channel_exp='standard deviation of residuals (log10(dB))',
                      dead_channel_gsn='indicator',
                      dead_channel_lin='standard deviation of residuals (dB)',
                      digital_filter_charging='flag count (number of occurrences)',
                      digitizer_clipping='flag count (number of occurrences)',
                      event_begin='flag count (number of occurrences)',
                      event_end='flag count (number of occurrences)',
                      event_in_progress='flag count (number of occurrences)',
                      feed_latency='latency (seconds)',
                      gap_list='gap length (seconds)',
                      glitches='flag count (number of occurrences)',
                      max_gap='maximum gap length (seconds)',
                      max_overlap='overlap length (seconds)',
                      max_stalta='short-term average / long-term average', # no units
                      missing_padded_data='flag count (number of occurrences)',
                      num_gaps='gap count (number of occurrences)',
                      num_overlaps='overlap count (number of occurrences)',
                      num_spikes='outlier count (number of occurrences)',
                      pct_above_nhnm='PDF matrix above New High Noise Model (%)',
                      pct_below_nlnm='PDF matrix below New Low Noise Model (%)',
                      percent_availability='availability (%)',
                      polarity_check='maximum cross-correlation function', # no units
                      pressure_effects='zero-lag cross-correlation function', # no units
                      sample_max='maximum amplitude (counts)',
                      sample_mean='mean amplitude (counts)',
                      sample_median='median amplitude (counts)',
                      sample_min='minimum amplitude (counts)',
                      sample_rms='root-mean-square variance (counts)',
                      sample_snr='signal-to-noise ratio', # no units
                      sample_unique='unique sample values (number of occurrences)',
                      spikes='flag count (number of occurrences)',
                      suspect_time_tag='flag count (number of occurrences)',
                      telemetry_sync_error='flag count (number of occurrences)',
                      timing_correction='flag count (number of occurrences)',
                      timing_quality='average timing quality (%)',
                      total_latency='latency (seconds)',
                      ts_num_gaps='gap count (number of occurrences)',
                      ts_max_gap='maximum gap length (seconds)',
                      ts_gap_length='total gap length (seconds)',
                      ts_percent_availability='availability (%)',
                      ts_channel_up_time='trace segment length (seconds)',
                      
                      # transfer_function:
                      gain_ratio='data/metadata gain ratio', # no units
                      phase_diff='data-metadata phase difference (degrees)',
                      ms_coherence='coherence function', # no units
                      xxx='xxx')
  
  textList$metricYlabsList <- metricYlabs
  
  textList$metricYlab <- metricYlabs[[metricName]]

  
  
  # Create the SNCL name
   textList$snclName <- paste(infoList$network,infoList$station,infoList$location,infoList$channel,sep='.')    
  
  
  # Add the network title if an appropriate dataframe exists
  textList$networkTitle <- ""
  if ( infoList$virtualNetwork != '' ) {
    textList$networkTitle <- paste0('Virtual Network:  ',infoList$virtualNetwork)
  } else {
    if ( !is.null(dataList[['network_DF']]) ) {
      textList$networkTitle <- dataList[['network_DF']]$description[1]
    }    
  }

  # Add the station title if an appropriate dataframe exists
  textList$stationTitle <- ""
  if ( !is.null(dataList[['station_DF']]) ) {
    df <- dataList[['station_DF']]
    sn <- paste(df$network[1],df$station[1],sep=".")
    textList$stationTitle <- paste(sn,"--",df$sitename[1])
  }

  # Create date range strings
  if ( !is.null(dataList[['metric_DF']]) ) {
    # Add a date range string based on actual dates in the data
    starttime <- dataList[['metric_DF']]$starttime[1]
    endtime <-dataList[['metric_DF']]$starttime[nrow(dataList[['metric_DF']])]
  } else if ( infoList$plotType == 'metricTimeseries' ||
              infoList$plotType == 'stackedMetricTimeseries' ) {
    # Also do this for metricTimeseries plots where the dataframes are named after metrics
    starttime <- dataList[[1]]$starttime[1]
    endtime <- dataList[[1]]$starttime[nrow(dataList[[1]])]
  } else {
    # Default to the requested starttime and endtime
    starttime <- infoList$starttime
    endtime <- infoList$endtime
  }
  
  dayCount <- as.numeric( difftime(endtime,starttime,units="days") )
  if (dayCount < 3) { 
    textList$dataDateRange <- paste(format(starttime,"%b %d, %Y",tz="GMT"))
    textList$dataJulianDateRange <- paste(format(starttime,"%Y.%j",tz="GMT"))
  } else {
    textList$dataDateRange <- paste(format(starttime,"%b %d, %Y",tz="GMT"),"-",format(endtime,"%b %d, %Y",tz="GMT"))    
    textList$dataJulianDateRange <- paste(format(starttime,"%Y.%j",tz="GMT"),"-",format(endtime,"%Y.%j",tz="GMT"))    
  }
  
  textList$dataRange <- paste("Data for",textList$dataDateRange,'(',textList$dataJulianDateRange,')')
  
  return(textList)
  
}
