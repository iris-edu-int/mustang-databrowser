########################################################################
# textList_en.R
#
# English language text strings for plot annotations.
#
# Author: Jonathan Callahan
########################################################################

createTextList <- function(dataList, infoList) {

  # Create empty textList
  textList <- list()
  
  # Get useful variables from infoList
  metricName <- infoList$metricName

  # ----- Common annotations ---------------------------------------------------
  
# ----- Here are Mary Templeton's preferred names for metric variables ---------
#
#'amplifier_saturation': 'Daily Flag Count: Amplifier Saturation Detected',
#'calibration_signal': 'Daily Flag Count: Calibration Signals Present',
#'clock_locked': 'Daily Flag Count: Clock locked',
#'cross_talk': 'Cross-Talk Check: Channel Cross-Correlation Coefficient',
#'data_latency': 'Time Since Last Data Sample Was Acquired',
#'dc_offset_times': 'Times of DC Offsets Detected',
#'digital_filter_charging': 'Daily Flag Count: Digital Filter Charging',
#'digitizer_clipping': 'Daily Flag Count: Digitizer Clipping Detected',
#'event_begin': 'Daily Flag Count: Beginning of Event (Trigger)',
#'event_end': 'Daily Flag Count: End of Event (Detrigger)',
#'event_in_progress': 'Daily Flag Count: Event in Progress',
#'feed_latency': 'Time Since Latest Data Was Received',
#'glitches': 'Daily Flag Count: Glitches Detected',
#'max_gap': 'Daily Maximum Gap Length',
#'max_overlap': 'Daily Maximum Overlap Length',
#'max_stalta': 'Maximum Daily Short-Term Average/Long-Term Average Amplitude Ratio',
#'missing_padded_data': 'Daily Flag instances: Missing/Padded Data Present',
#'num_gaps': 'Gaps Per Day',
#'num_overlaps': 'Overlaps Per Day',
#'num_spikes': 'Spikes Per Day',
#'percent_availability': 'Channel Percent Data Available Per Day',
#'pressure_effects': 'Atmospheric Pressure Check: Barometer-Seismometer Cross-Correlation Coefficient',
#'sample_max': 'Daily Maximum Amplitude',
#'sample_mean': 'Daily Mean Amplitude',
#'sample_median': 'Daily Median Amplitude',
#'sample_min': 'Daily Minimum Amplitude',
#'sample_rms': 'Daily Root Mean Squared Variance of Amplitudes',
#'sample_snr': 'P-Wave Signal-To-Noise Ratio',
#'spikes': 'Daily Flag Count: Spikes Detected',
#'station_completeness': 'Station Percent Data Available Per Day',
#'station_up_down_times': 'Station Up/Down Time Spans',
#'suspect_time_tag': 'Daily Flag Count: Time Tag Questionable',
#'telemetry_sync_error': 'Daily Flag Count: Telemetry Synchronization Error',
#'timing_correction': 'Daily Flag Count: Timing Correction Applied',
#'timing_quality': 'Daily Average Timing Quality',
#'total_latency': 'Total Latency',
#'up_down_times': 'Channel Up/Down Time Spans',

  # TODO:  Update metric title list (last updated on 2013-11-16)
  # Add a metric title
  metricTitles <- list(amplifier_saturation='Daily Flag Count: Amplifier Saturation Detected',
                       calibration_signal='Daily Flag Count: Calibration Signals Present',
                       clock_locked='Daily Flag Count: Clock locked',
                       cross_talk='Cross-Talk Check: Channel Cross-Correlation Coefficient',
                       data_latency='Time Since Last Data Sample Was Acquired',
                       dc_offset_times='Times of DC Offsets Detected',
                       digital_filter_charging='Daily Flag Count: Digital Filter Charging',
                       digitizer_clipping='Daily Flag Count: Digitizer Clipping Detected',
                       event_begin='Daily Flag Count: Beginning of Event (Trigger)',
                       event_end='Daily Flag Count: End of Event (Detrigger)',
                       event_in_progress='Daily Flag Count: Event in Progress',
                       feed_latency='Time Since Latest Data Was Received',
                       glitches='Daily Flag Count: Glitches Detected',
                       max_gap='Daily Maximum Gap Length',
                       max_overlap='Daily Maximum Overlap Length',
                       max_stalta='Maximum Daily Short-Term Average/Long-Term Average Amplitude Ratio',
                       missing_padded_data='Daily Flag instances: Missing/Padded Data Present',
                       num_gaps='Gaps Per Day',
                       num_overlaps='Overlaps Per Day',
                       num_spikes='Spikes Per Day',
                       percent_availability='Channel Percent Data Available Per Day',
                       pressure_effects='Atmospheric Pressure Check: Barometer-Seismometer Cross-Correlation Coefficient',
                       sample_max='Daily Maximum Amplitude',
                       sample_mean='Daily Mean Amplitude',
                       sample_median='Daily Median Amplitude',
                       sample_min='Daily Minimum Amplitude',
                       sample_rms='Daily Root Mean Squared Variance of Amplitudes',
                       sample_snr='P-Wave Signal-To-Noise Ratio',
                       spikes='Daily Flag Count: Spikes Detected',
                       station_completeness='Station Percent Data Available Per Day',
                       station_up_down_times='Station Up/Down Time Spans',
                       suspect_time_tag='Daily Flag Count: Time Tag Questionable',
                       telemetry_sync_error='Daily Flag Count: Telemetry Synchronization Error',
                       timing_correction='Daily Flag Count: Timing Correction Applied',
                       timing_quality='Daily Average Timing Quality',
                       total_latency='Total Latency',
                       up_down_times='Channel Up/Down Time Spans',

                       # multi-metrics
                       basic_stats='Basic Statistics',
                       latency='Latency',
                       gaps_and_overlaps='Gaps and Overlaps',
                       SOH_flags='State-of-Health Daily Flag Counts',
                       transfer_function='Transfer Function Metrics',
                       # names within the transfer function dataframe
                       ms_coherence='Coherence',
                       gain_ratio='Gain Ratio',
                       phase_diff='Phase Difference (deg)',    
                       xxx='xxx')

  textList$metricTitlesList <- metricTitles

  textList$metricTitle <- metricTitles[[metricName]]


  # Adjust location as needed
  if (metricName == 'transfer_function' || metricName == 'ms_coherence' || metricName == 'gain_ratio' || metricName == 'phase_diff') {
    # Transfer functions have two locations
    if (infoList$location == '00')
      location <- '10:00'
    else
      location <- paste(infoList$location,'00',sep=':')
  } else {
    location <- infoList$location
  }

  # Create the SNCL name
  if (infoList$timeseriesChannelSet) {
    textList$snclName <- paste(infoList$network,'.',infoList$station,'.',location,'.',infoList$channel,'?',sep='')        
  } else {
    textList$snclName <- paste(infoList$network,infoList$station,location,infoList$channel,sep='.')    
  }

  
  # Add the network title if an appropriate dataframe exists
  textList$networkTitle <- ""
  if ( !is.null(dataList[['network_DF']]) ) {
    textList$networkTitle <- dataList[['network_DF']]$description[1]
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
