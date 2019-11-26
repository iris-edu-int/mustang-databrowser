########################################################################
# createInfoList.R
#
# Create an infoList from request parameters.
#
# Besides basic conversion from strings to other data types, a lot of
# specific choices are made here that will be used later on in different
# plotting scripts, e.g. deciding whether to use a logarithmic axis
# based on the metric name.
#
# Author: Jonathan Callahan
########################################################################

createInfoList <- function(request) {

  logger.info("----- createInfoList -----")

  # ----- Minumum set of infoList parameters from the UI -----------------------
  
  # Initialize the infoList from the request
  infoList <- request
  
  # NOTE:  "metric" is is used in the API to match other web services.
  # NOTE:  Internally, I vastly prefer "metricName" to communicate that this is
  # NOTE:  a character string identifier.
  infoList$metricName <- ifelse(is.null(infoList$metric),'',infoList$metric)
  metricName <- infoList$metricName

  # Convert incoming parameters to appropriate type
  infoList$plotWidth <- as.numeric(infoList$plotWidth)
  infoList$plotHeight <- as.numeric(infoList$plotHeight)
  
  # Fill in any missing parameters
  infoList$virtualNetwork <- ifelse(is.null(infoList$virtualNetwork),'',infoList$virtualNetwork)
  infoList$virtualNetwork <- ifelse(infoList$virtualNetwork == 'No virtual network','',infoList$virtualNetwork)
  infoList$network <- ifelse(is.null(infoList$network),'',infoList$network)
  infoList$station  <- ifelse(is.null(infoList$station),'',infoList$station)
  infoList$location <- ifelse(is.null(infoList$location),'',infoList$location)
  infoList$channel  <- ifelse(is.null(infoList$channel),'',infoList$channel)
  infoList$quality  <- ifelse(is.null(infoList$quality),'',infoList$quality)
  
  # TODO:  Sort out wildcards in the UI
  
  infoList$network <- stringr::str_replace(infoList$network, "\\.", "\\?")
  infoList$station <- stringr::str_replace(infoList$station, "\\.", "\\?")
  infoList$location <- stringr::str_replace(infoList$location, "\\.", "\\?")
  infoList$channel <- stringr::str_replace(infoList$channel, "\\.", "\\?")
  
  # Save date strings but also convert them to POSIXct dates
  infoList$startdate <- infoList$starttime 
  infoList$enddate <- infoList$endtime 
  infoList$starttime <- as.POSIXct(infoList$starttime, tz="GMT")
  infoList$endtime <- as.POSIXct(infoList$endtime, tz="GMT")
  
  # Optional parameters that sometimes come in
  infoList$timeseriesChannelSet <- ifelse(is.null(infoList$timeseriesChannelSet),FALSE,TRUE)
  infoList$timeseriesScale <- ifelse(is.null(infoList$timeseriesScale),FALSE,TRUE)
  infoList$boxplotShowOutliers <- ifelse(is.null(infoList$boxplotShowOutliers),FALSE,TRUE)
  infoList$transferFunctionCoherenceThreshold <- ifelse(is.null(infoList$transferFunctionCoherenceThreshold),FALSE,TRUE)
  infoList$scaleSensitivity <- ifelse(is.null(infoList$scaleSensitivity),FALSE,TRUE) 
  infoList$spectrogramScale <- ifelse(is.null(infoList$spectrogramScale),FALSE,TRUE)
    
  # ----- Adjust height based on plotType ------------------
  
  # Default setting
  infoList$plotHeight <- 0.6 * infoList$plotWidth
  
  if (infoList$plotType == 'metricTimeseries') {
    
    if (infoList$timeseriesChannelSet && metricName != 'polarity_check') {
      infoList$plotHeight <- 1.8 * infoList$plotWidth
    } else {
      infoList$plotHeight <- 0.6 * infoList$plotWidth
    }
    
  }else if (infoList$plotType == 'gapDurationPlot') { 
     infoList$plotHeight <- 1.8 * infoList$plotWidth

  }else if (infoList$plotType == 'stackedMetricTimeseries') {
    
    # TODO:  could adjust per metricName
    if (metricName == 'basic_stats' ||
        metricName == 'latency' ||
        metricName == 'gaps_and_availability'||
        metricName == 'transfer_function') {
      infoList$plotHeight <- 1.2 * infoList$plotWidth
    } else if (metricName == 'SOH_flags') {
      infoList$plotHeight <- 2.4 * infoList$plotWidth
    }
    
  } else if (infoList$plotType == 'networkMap') {
    
    infoList$plotHeight <- 0.7 * infoList$plotWidth
    
  } else if (infoList$plotType == 'networkBoxplot' ||
             infoList$plotType == 'stationBoxplot') {
    
    # NOTE:  The height of this plot is determined in Databrowser.R.in after
    # NOTE:  we get the data.  For now we just use the default setting.
    infoList$plotHeight <- 0.6 * infoList$plotWidth

  } else if (infoList$plotType == 'pdf' || infoList$plotType == 'noise-mode-timeseries' || infoList$plotType == 'spectrogram') {
    if (infoList$timeseriesChannelSet) {
      infoList$plotHeight <- 1.4 * infoList$plotWidth
    } else {
      infoList$plotHeight <- 0.6 * infoList$plotWidth
    }
    
  } else if (infoList$plotType == 'trace') {

    if (infoList$timeseriesChannelSet) {
      infoList$plotHeight <- 1.4 * infoList$plotWidth
    } else {
      infoList$plotHeight <- 0.6 * infoList$plotWidth
    }

 }  
  
  # ----- Extra info for specific plot types ---------------
  
  
  return(infoList)
}
