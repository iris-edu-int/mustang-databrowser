########################################################################
# createDataList.R
#
# Databrowser specific creation of dataframes for inclusion in dataList.
#
# Author: Jonathan Callahan
#         Lucy Williams
#         Adam Wisch
########################################################################

createDataList <- function(infoList) {
  
  logger.info("----- createDataList -----")
  
  # Create dataList
  dataList <- list()

  # Extract elements for use in web service requests
  virtualNetwork  <- infoList$virtualNetwork
  network  <- infoList$network
  station  <- infoList$station
  location <- infoList$location
  channel  <- infoList$channel
  quality  <- infoList$quality 
  starttime <- infoList$starttime
  endtime <- infoList$endtime
  metricName  <- infoList$metricName

  # # Default settings for optional parameters associated with different plot types
  # if ( infoList$plotType == "networkMap" ) { 
  #   # showEvents toggles the display of seismic events when creating maps
  #   showEvents  <- as.logical(ifelse(is.null(infoList$showEvents),'TRUE',infoList$showEvents))    
  #   minmag  <- as.numeric(ifelse(is.null(infoList$minmag),'5.3',infoList$minmag))  
  # }
  
  # NOTE:  transfer_function is unique in that a request for it returns a single dataframe
  # NOTE:  with three separate variables:  ms_coherence, gain_ratio, phase_diff
  # NOTE:  To access any individual value, we must request and parse the data for 'transfer_function'
  if ( metricName == 'transfer_function' || metricName == 'ms_coherence' || metricName == 'gain_ratio' || metricName == 'phase_diff' ) {
    metricName <- 'transfer_function'
  }
  
  ########################################
  # Get the data
  ########################################
  
  # Open a connection to IRIS DMC webservices
  iris <- new("IrisClient",debug=FALSE)
  
  if ( infoList$plotType == 'trace' ) {
    
    dataList[['dataselect_DF']] <- getDataselect(iris,network,station,location,channel,starttime,endtime,ignoreEpoch=TRUE)
    
    # Return BSS URL
    dataList[['bssUrl']] <- ''


  } else if ( infoList$plotType == 'metricTest' ) {

    dataDF <- getGeneralValueMetrics(iris,network,station,location,channel,starttime,endtime,metricName)
    if ( is.null(dataDF) || nrow(dataDF) == 0 ) stop(paste0("No ",metricName," values found."), call.=FALSE)
    dataList <- split(dataDF, dataDF$metricName)

    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,station,location,channel,starttime,endtime,metricName)      

    
  } else if ( infoList$plotType == 'metricTimeseries' ) {

    if  ( infoList$timeseriesChannelSet ) {
      # Get the single dataframe including metric for an entire channelSet
      logger.debug("getGeneralValueMetrics(iris,'%s','%s','%s','%s',starttime,endtime,'%s')",network,station,location,channel,metricName)
      dataDF <- getGeneralValueMetrics(iris,network,station,location,channel,starttime,endtime,metricName)
      if ( is.null(dataDF) || nrow(dataDF) == 0 ) stop(paste0("No ",metricName," values found."), call.=FALSE)
      dataList <- split(dataDF, dataDF$snclq)
    } else {
      logger.debug("getGeneralValueMetrics(iris,'%s','%s','%s','%s',starttime,endtime,'%s')",network,station,location,channel,metricName)
      dataDF <- getGeneralValueMetrics(iris,network,station,location,channel,starttime,endtime,metricName)
      if ( is.null(dataDF) || nrow(dataDF) == 0 ) stop(paste0("No ",metricName," values found."), call.=FALSE)
      if ( metricName == 'max_stalta' ||
           metricName == 'polarity_check' ||
           metricName == 'transfer_function') {
        dataList[[metricName]] <- dataDF
      # } else if ( metricName == 'transfer_function' ) {
      #   # NOTE:  transfer_function is unique in that a request for it returns a single dataframe
      #   # NOTE:  with three separate variables:  ms_coherence, gain_ratio, phase_diff
      #   # NOTE:  See stackedMetricTimeseriesPlot.R
      #   dataList <- list('transfer_function'=dataDF)
      } else {
        dataList <- split(dataDF, dataDF$metricName)
      }
    }

    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,station,location,channel,starttime,endtime,metricName)      


  } else if ( infoList$plotType == 'stackedMetricTimeseries' ) {
    
    if ( metricName == 'basic_stats' ) {
      actualMetricNames <- c("sample_max",
                             "sample_min",
                             "sample_mean",
                             "sample_median",
                             "sample_rms") 
    } else if ( metricName == 'latency' ) {
      actualMetricNames <- c("data_latency",
                             "feed_latency",
                             "total_latency") 
    } else if ( metricName == 'gaps_and_overlaps' ) {
      actualMetricNames <- c("num_gaps",
                             "max_gap",
                             "num_overlaps",
                             "max_overlap",
                             "percent_availability") 
    } else if ( metricName == 'SOH_flags' ) {
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
    } else if ( metricName == 'transfer_function' ) {
      # NOTE:  transfer_function is unique in that a request for it returns a single dataframe
      # NOTE:  with three separate variables:  ms_coherence, gain_ratio, phase_diff
      actualMetricNames <- c("transfer_function")
    }
    actualMetricNames <- paste0(actualMetricNames, collapse=",")
    logger.debug("location = '%s', metrics = '%s'", location, actualMetricNames)
    dataDF <- getGeneralValueMetrics(iris,network,station,location,channel,starttime,endtime,actualMetricNames)
    if ( is.null(dataDF) || nrow(dataDF) == 0 ) stop(paste0("No ",metricName," values found."), call.=FALSE)
    
    if ( metricName == 'max_stalta' ||
         metricName == 'polarity_check' ||
         metricName == 'transfer_function' ) {
      # NOTE:  These metrics are unique in that a request returns a single dataframe with no 'metricName' column.
      dataList[[metricName]] <- dataDF
    } else {
      dataList <- split(dataDF, dataDF$metricName)
    }
    
    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,station,location,channel,starttime,endtime,actualMetricNames)      

    
  } else if ( infoList$plotType == 'networkBoxplot' ) {
    
    if ( virtualNetwork != '' ) {
      network <- virtualNetwork
    }
    
    # getNetwork returns network description
    dataList[['network_DF']] <- getNetwork(iris,network,'','','',starttime,endtime)

    # loads single values for each station based on whatever metric we ask for
    dataDF <- getGeneralValueMetrics(iris,network,'',location,channel,starttime,endtime,metricName)
    if ( is.null(dataDF) || nrow(dataDF) == 0 ) stop(paste0("No ",metricName," values found."), call.=FALSE)

    # transferFunctionCoherenceThreshold should only be used for transfer_function metrics
    if ( metricName == 'transfer_function' && infoList$transferFunctionCoherenceThreshold ) {
      dataList[['metric_DF']] <- dataDF[dataDF$ms_coherence > 0.999,]
    } else {
      dataList[['metric_DF']] <- dataDF
    }
    
    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,'',location,channel,starttime,endtime,metricName)      


  } else if ( infoList$plotType == 'stationBoxplot' ) {
    
    # get the station description
    dataList[['station_DF']] <- getStation(iris,network,station,'','',starttime,endtime)

    # loads single values for all seismic channels
    # NOTE:  Here, we need to use '.' instead of '?'.
    # TODO:  IRISMustangMetrics::getGeneralValueMetrics should settle on '.' or '?' as the single character wildcard or should support both.
    allSeismicChannels <- "LH.|LL.|LG.|LM.|LN.|MH.|ML.|MG.|MM.|MN.|BH.|BL.|BG.|BM.|BN.|HH.|HL.|HG.|HM.|HN."
    dataDF <- getGeneralValueMetrics(iris,network,station,'',allSeismicChannels,starttime,endtime,metricName)
    if ( is.null(dataDF) || nrow(dataDF) == 0 ) stop(paste0("No ",metricName," values found."), call.=FALSE)

    # transferFunctionCoherenceThreshold should only be used for transfer_function metrics
    if ( metricName == 'transfer_function' && infoList$transferFunctionCoherenceThreshold ) {
      dataList[['metric_DF']] <- dataDF[dataDF$ms_coherence > 0.999,]
    } else {
      dataList[['metric_DF']] <- dataDF
    }

    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,station,'',allSeismicChannels,starttime,endtime,metricName)      


  } else if (infoList$plotType == 'networkMap' ) {
    
    if ( virtualNetwork != '' ) {
      network <- virtualNetwork
    }
    
    start <- (proc.time())[3]
    timepoint <- (proc.time())[3]
    
    dataList[['network_DF']] <- getNetwork(iris,network,'','','',starttime,endtime)
    
    elapsed <- ( (proc.time())[3] - timepoint )
    timepoint <- (proc.time())[3]
    logger.debug("%f seconds to load getNetwork", round(elapsed,4))
    
    dataList[['station_DF']] <- getStation(iris,network,'','','',starttime,endtime)
    
    elapsed <- ( (proc.time())[3] - timepoint )
    timepoint <- (proc.time())[3]
    logger.debug("%f seconds to load getStation", round(elapsed,4))
    
    if (showEvents) {
      dataList[['event_DF']] <- getEvent(iris,starttime,endtime,minmag)
    } else {
      dataList[['event_DF']] <- NA
    }
    
    elapsed <- ( (proc.time())[3] - timepoint )
    timepoint <- (proc.time())[3]
    logger.debug("%f seconds to load getEvent", round(elapsed,4))
    
    # Loading world_countries dataframe for use in generating maps
    library(sp)
    load(paste(infoList$databrowserDir,'/data_local/simpleMap.RData',sep=""))
    dataList[['world_countries_DF']] <- world_countries
    
    elapsed <- ( (proc.time())[3] - timepoint )
    timepoint <- (proc.time())[3]
    logger.debug("%f seconds to load simplemap.RData", round(elapsed,4))
    
    # get individual station measurements
    dataDF <- getGeneralValueMetrics(iris,network,'',location,channel,starttime,endtime,metricName)
    if ( is.null(dataDF) || nrow(dataDF) == 0 ) stop(paste0("No ",metricName," values found."), call.=FALSE)

    metricList <- split(dataDF, dataDF$metricName)
    dataList[['metric_DF']] <- metricList[[1]] # just to match the previous code, we could just use dataDF
    
    elapsed <- ( (proc.time())[3] - timepoint )
    timepoint <- (proc.time())[3]
    logger.debug("%f seconds to load getGeneralValueMetrics", round(elapsed,4))
    
    total_elapsed <- ( (proc.time())[3] - start )
    logger.debug("Total elapsed = %f seconds to load getGeneralValueMetrics", round(elapsed,4))
    
    # Return BSS URL
    dataList[['bssUrl']] <- ''

  }

  # Check to make sure that all dataframes have some data
  for (i in seq(length(dataList))) {
    if (class(dataList[[i]]) == "data.frame") {
      if ( nrow(dataList[[i]]) == 0 ) {
        stop(paste0("No ",metricName," values found."), call.=FALSE)
      }
    }
  }
  
  return(dataList)
  
  
}

