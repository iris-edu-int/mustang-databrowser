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
  network  <- infoList$network
  station  <- infoList$station
  location <- infoList$location
  channel  <- infoList$channel
  quality  <- infoList$quality 
  starttime <- infoList$starttime
  endtime <- infoList$endtime
  metricName  <- infoList$metricName

  # Default settings for optional parameters associated with different plot types
  if ( infoList$plotType == "networkMap" ) {
    # showEvents toggles the display of seismic events when creating maps
    showEvents  <- as.logical(ifelse(is.null(infoList$showEvents),'TRUE',infoList$showEvents))    
    # minmag specifies the minimum magnitude for querying for events when creating maps
    minmag  <- as.numeric(ifelse(is.null(infoList$minmag),'5.3',infoList$minmag))  
  }

  # NOTE:  transfer_function is unique in that a request for it returns a single dataframe
  # NOTE:  with three separate variables:  ms_coherence, gain_ratio, phase_diff
  if ( metricName == 'transfer_function' || metricName == 'ms_coherence' || metricName == 'gain_ratio' || metricName == 'phase_diff' ) {
    metricName <- c("transfer_function")
  }
  
  ########################################
  # Get the data
  ########################################
  
  # Open a connection to IRIS DMC webservices
  iris <- new("IrisClient",debug=FALSE)
  
  if ( infoList$plotType == 'trace' ) {
    
    dataList[['dataselect_DF']] <- getDataselect(iris,network,station,location,channel,starttime,endtime)
    
    # Return BSS URL
    dataList[['bssUrl']] <- ''


  } else if ( infoList$plotType == 'metricTest' ) {

    dataDF <- getSingleValueMetrics(iris,network,station,location,channel,starttime,endtime,metricName)
    dataList <- split(dataDF, dataDF$metricName)

    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,station,location,channel,starttime,endtime,metricName)      

    
  } else if ( infoList$plotType == 'metricTimeseries' ) {

    if  ( infoList$timeseriesChannelSet ) {
      # NOTE:  infoList$channel will only have two characters so we add '.' as a wildcard character
      channel <- paste0(channel,'?')
      # Get the single dataframe including metric for an entire channelSet
      logger.debug("getSingleValueMetrics(iris,'%s','%s','%s','%s',starttime,endtime,'%s')",network,station,location,channel,metricName)
      df <- getSingleValueMetrics(iris,network,station,location,channel,starttime,endtime,metricName)
      # Check if any data is returned
      if ( nrow(df) == 0 ) {
        stop("No data found.", call.=FALSE)
      }
      # Then fill the dataList with as many dataframes as there are unique snclqs
      snclqs <- sort(unique(df$snclq))
      index <- 1
      for (snclq in snclqs) {
        dataList[[index]] <- df[df$snclq == snclq,]
        index <- index + 1
      }
    } else {
      logger.debug("getSingleValueMetrics(iris,'%s','%s','%s','%s',starttime,endtime,'%s')",network,station,location,channel,metricName)
      dataDF <- getSingleValueMetrics(iris,network,station,location,channel,starttime,endtime,metricName)
      dataList <- split(dataDF, dataDF$metricName)
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
    dataDF <- getSingleValueMetrics(iris,network,station,location,channel,starttime,endtime,actualMetricNames)
    
    # NOTE:  transfer_function is unique in that a request for it returns a single dataframe
    # NOTE:  with three separate variables:  ms_coherence, gain_ratio, phase_diff
    # NOTE:  See stackedMetricTimeseriesPlot.R
    if ( metricName == 'transfer_function' ) {
      dataList <- list()
      dataList[['transfer_function']] <- dataDF
    } else {
      dataList <- split(dataDF, dataDF$metricName)
    }
    
    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,station,location,channel,starttime,endtime,actualMetricNames)      

    
  } else if ( infoList$plotType == 'networkBoxplot' ) {
    
    # getNetwork returns network description
    dataList[['network_DF']] <- getNetwork(iris,network,'','','',starttime,endtime)

    # loads single values for each station based on whatever metric we ask for
    dataDF <- getSingleValueMetrics(iris,network,'',location,channel,starttime,endtime,metricName)
    metricList <- split(dataDF, dataDF$metricName)
    dataList[['metric_DF']] <- metricList[[1]] # just to match the previous code. We could just use dataDF.
    
    # transferFunctionCoherenceThreshold should only come in if metricName is one of the transfer metrics
    if (infoList$transferFunctionCoherenceThreshold) {
      dfTemp <- dataList[['metric_DF']]
      dfTemp <- dfTemp[dfTemp$ms_coherence > 0.999,]
      dataList[['metric_DF']] <- dfTemp
    }

    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,'',location,channel,starttime,endtime,metricName)      


  } else if ( infoList$plotType == 'stationBoxplot' ) {
    
    # get the station description
    dataList[['station_DF']] <- getStation(iris,network,station,'','',starttime,endtime)

    # loads single values for all seismic channels
    # NOTE:  Here, we need to use '.' instead of '?'.
    # TODO:  IRISMustangMetrics::getSingleValueMetrics should settle on '.' or '?' as the single character wildcard or should support both.
    allSeismicChannels <- "LH.|LL.|LG.|LM.|LN.|MH.|ML.|MG.|MM.|MN.|BH.|BL.|BG.|BM.|BN.|HH.|HL.|HG.|HM.|HN."
    dataDF <- getSingleValueMetrics(iris,network,station,'',allSeismicChannels,starttime,endtime,metricName)
    metricList <- split(dataDF, dataDF$metricName)
    dataList[['metric_DF']] <- metricList[[1]] # just to match the previous code. We could just use dataDF.
    
    # transferFunctionCoherenceThreshold should only come in if metricName is one of the transfer metrics
    if ( infoList$transferFunctionCoherenceThreshold ) {
      dfTemp <- dataList[['metric_DF']]
      dfTemp <- dfTemp[dfTemp$ms_coherence > 0.999,]
      dataList[['metric_DF']] <- dfTemp
    }

    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,station,'',allSeismicChannels,starttime,endtime,metricName)      


  } else if (infoList$plotType == 'networkMap' ) {
    
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
    ###metricList <- getSingleValueMeasurements(iris,network,'',location,channel,starttime,endtime,metricName)
    ###dataList[['metric_DF']] <- metricList[[1]]
    dataDF <- getSingleValueMetrics(iris,network,'',location,channel,starttime,endtime,metricName)
    metricList <- split(dataDF, dataDF$metricName)
    dataList[['metric_DF']] <- metricList[[1]] # just to match the previous code, we could just use dataDF
    
    elapsed <- ( (proc.time())[3] - timepoint )
    timepoint <- (proc.time())[3]
    logger.debug("%f seconds to load getSingleValueMetrics", round(elapsed,4))
    
    total_elapsed <- ( (proc.time())[3] - start )
    logger.debug("Total elapsed = %f seconds to load getSingleValueMetrics", round(elapsed,4))
    
    # Return BSS URL
    dataList[['bssUrl']] <- ''

  }

  # Check to make sure that all dataframes have some data
  for (i in seq(length(dataList))) {
    if (class(dataList[[i]]) == "data.frame") {
      if ( nrow(dataList[[i]]) == 0 ) {
        stop("No data found.", call.=FALSE)
      }
    }
  }
  
  return(dataList)
  
  
}

