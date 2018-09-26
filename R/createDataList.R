#######################################################################n

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

    stationInfo <- data.frame()

    stationInfo <- getChannel(iris,network,station,location,channel,starttime,endtime)
    stationInfo <- dplyr::distinct(stationInfo,network,station,location,channel,.keep_all=TRUE)
    if (stationInfo$samplerate[1] > 50 && stationInfo$samplerate[1] < 200 ) {
       if (difftime(endtime,starttime,units="days") > 15) {
          stop(paste("Please select time span of 15 days or less for",channel,"channels."))
       }
    } else if (stationInfo$samplerate[1] >= 200 && stationInfo$samplerate[1] < 300) {
       if (difftime(endtime,starttime,units="days") > 7) {
          stop(paste("Please select time span of 7 days or less for",channel,"channels."))
       }
    } else if (stationInfo$samplerate[1] >= 300) {
       if (difftime(endtime,starttime,units="days") > 2) {
          stop(paste("Please select time span of 2 days or less for",channel,"channels."))
       }
    } else {
       if (difftime(endtime,starttime,units="days") > 31) {
          stop(paste("Please select time span of 31 days or less for",channel,"channels."))
       }
    }

    if (nrow(stationInfo) == 1 ) {
       result <- try(dataList[['dataselect_DF']] <- getDataselect(iris,network,station,location,channel,starttime,endtime,ignoreEpoch=TRUE))
       if ( "try-error" %in% class(result) ) {
           stop(geterrmessage())
       }
    } else {
       for (i in 1:nrow(stationInfo)) {
          result <- try(dataList[[i]] <- getDataselect(iris,network,station,location,stationInfo$channel[i],starttime,endtime,ignoreEpoch=TRUE))
          if ( "try-error" %in% class(result) ) {
             stop(geterrmessage())
          }
       }
    }
    
    if(length(dataList)==0) stop("No data returned")
    rm(result)

    # Return BSS URL
    dataList[['bssUrl']] <- ''

  } else if ( infoList$plotType == 'pdf' || infoList$plotType == 'noise-mode-timeseries' ) {
     stationInfo <- data.frame()

     if (grepl("..\\?", channel)) {
         stationInfo <- getChannel(iris,network,station,location,channel,starttime,endtime)
         stationInfo <- dplyr::distinct(stationInfo,network,station,location,channel,.keep_all=TRUE)
     }

     if (nrow(stationInfo) == 0 ) {
        dataList[['channel_DF']] <- infoList$channel
     } else {
        for (i in 1:nrow(stationInfo)) {
           dataList[[i]] <- stationInfo$channel[i]
        }
     }

  } else if ( infoList$plotType == 'metricTimeseries' ) {

    if  ( infoList$timeseriesChannelSet || metricName %in% c('transfer_function','cross_talk' )) {
      # Get the single dataframe including metric for an entire channelSet
      logger.debug("getGeneralValueMetrics(iris,'%s','%s','%s','%s',starttime,endtime,'%s')",network,station,location,channel,metricName)

      result <- try(dataDF <- getGeneralValueMetrics(iris,network,station,location,channel,starttime,endtime,metricName),silent=TRUE)
      if ( "try-error" %in% class(result) ) {
           stop(geterrmessage())
      }

      if ( is.null(dataDF) || nrow(dataDF) == 0 ) stop(paste0("No ",metricName," values found."), call.=FALSE)
    
      dataList <- split(dataDF, dataDF$snclq)

    } else {
      logger.debug("getGeneralValueMetrics(iris,'%s','%s','%s','%s',starttime,endtime,'%s')",network,station,location,channel,metricName)
      result <- try(dataDF <- getGeneralValueMetrics(iris,network,station,location,channel,starttime,endtime,metricName),silent=TRUE)
      if ( "try-error" %in% class(result) ) {
           stop(geterrmessage())
      }

      if ( is.null(dataDF) || nrow(dataDF) == 0 ) stop(paste0("No ",metricName," values found."), call.=FALSE)
      if ( metricName == 'max_stalta' ||
           metricName == 'polarity_check' ||
           metricName == 'transfer_function') {
        dataList[[metricName]] <- dataDF
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
    } else if ( metricName == 'gaps_and_availability' ) {
      actualMetricNames <- c("ts_num_gaps",
                             "ts_max_gap",
                             "ts_gap_length",
                             "ts_percent_availability") 
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
    result <- try(dataDF <- getGeneralValueMetrics(iris,network,station,location,channel,starttime,endtime,actualMetricNames))
    if ( "try-error" %in% class(result) ) {
           stop(geterrmessage())
    }
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
    result <- try(dataList[['network_DF']] <- getNetwork(iris,network,'','','',starttime,endtime))
    if ( "try-error" %in% class(result) ) {
           stop(geterrmessage())
    }

    # loads single values for each station based on whatever metric we ask for
    result <- try(dataDF <- getGeneralValueMetrics(iris,network,'','',channel,starttime,endtime,metricName))
    if ( "try-error" %in% class(result) ) {
           stop(geterrmessage())
    } 
    if ( is.null(dataDF) || nrow(dataDF) == 0 ) stop(paste0("No ",metricName," values found."), call.=FALSE)

    # transferFunctionCoherenceThreshold should only be used for transfer_function metrics
    # add optional scaling by sensitivity
    if ( metricName == 'transfer_function' && infoList$transferFunctionCoherenceThreshold ) {
      dataList[['metric_DF']] <- dataDF[dataDF$ms_coherence > 0.999,]

    } else if ( metricName %in% c('sample_mean','sample_max','sample_min','sample_rms','sample_median') && infoList$scaleSensitivity) { 
      dataDF$starttime <- as.Date(dataDF$starttime)
      result <- try(metaDF <- getChannel(iris,network,'','',channel,starttime,endtime),siltent=TRUE)
      if ( "try-error" %in% class(result) ) {
           stop(geterrmessage())
      }

      metaDF$starttime <- as.Date(if_else(difftime(metaDF$starttime,starttime) < 0, starttime, metaDF$starttime))
      metaDF$endtime <- as.Date(if_else(difftime(metaDF$endtime,endtime) < 0, metaDF$endtime, endtime))
      metaDF <- mutate(metaDF, snclq=paste(snclId,"M",sep="."))
      metaDF <- metaDF %>%
         select(snclq,scale,scaleunits,starttime,endtime) %>%
         group_by(snclq,scale,scaleunits) %>%
         expand(starttime = full_seq(c(starttime,endtime), 1))
      scaledDF <- left_join(dataDF,metaDF,by=c("snclq","starttime"))
      scaledDF <- mutate(scaledDF, value=value/scale)

      dataList[['metric_DF']] <- scaledDF  
    } else {
      dataList[['metric_DF']] <- dataDF
    }
    
    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,'','',channel,starttime,endtime,metricName)


  } else if ( infoList$plotType == 'stationBoxplot' ) {
    
    # get the station description
    result <- try(dataList[['station_DF']] <- getStation(iris,network,station,'','',starttime,endtime))
    if ( "try-error" %in% class(result) ) {
           stop(geterrmessage())
    }

    # loads single values for all seismic channels
    # allSeismicChannels <- "LH.|LL.|LG.|LM.|LN.|MH.|ML.|MG.|MM.|MN.|BH.|BL.|BG.|BM.|BN.|HH.|HL.|HG.|HM.|HN.|BX.|BY.|HX.|HY.|EH.|EN.|CH.|DH.|SH.|DP."
    currentSeismicChannels <- "?H?,?P?,?L?,?N?,BY?,HY?,BX?,HX?"
    result <- try(dataDF <- getGeneralValueMetrics(iris,network,station,'',currentSeismicChannels,starttime,endtime,metricName), silent=TRUE)
    if ( "try-error" %in% class(result) ) {
           stop(geterrmessage())
    }
    if ( is.null(dataDF) || nrow(dataDF) == 0 ) stop(paste0("No ",metricName," values found."), call.=FALSE)

    # transferFunctionCoherenceThreshold should only be used for transfer_function metrics
    # add optional scaling by sensitivity
    if ( metricName == 'transfer_function' && infoList$transferFunctionCoherenceThreshold ) {
      dataList[['metric_DF']] <- dataDF[dataDF$ms_coherence > 0.999,]

    } else if ( metricName %in% c('sample_mean','sample_max','sample_min','sample_rms','sample_median') && infoList$scaleSensitivity) {  
      dataDF$starttime <- as.Date(dataDF$starttime)
      result <- try(metaDF <- getChannel(iris,network,station,'',currentSeismicChannels,starttime,endtime),silent=TRUE)
      if ( "try-error" %in% class(result) ) {
           stop(geterrmessage())
      }
      metaDF$starttime <- as.Date(if_else(difftime(metaDF$starttime,starttime) < 0, starttime, metaDF$starttime))
      metaDF$endtime <- as.Date(if_else(difftime(metaDF$endtime,endtime) < 0, metaDF$endtime, endtime))
      metaDF <- mutate(metaDF, snclq=paste(snclId,"M",sep="."))
      metaDF <- metaDF %>%
         select(snclq,scale,scaleunits,starttime,endtime) %>%
         group_by(snclq,scale,scaleunits) %>%
         expand(starttime = full_seq(c(starttime,endtime), 1))
      scaledDF <- left_join(dataDF,metaDF,by=c("snclq","starttime"))
      scaledDF <- mutate(scaledDF, value=value/scale)

      dataList[['metric_DF']] <- scaledDF  

    } else {
      dataList[['metric_DF']] <- dataDF
    }

    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,station,'',currentSeismicChannels,starttime,endtime,metricName)      


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
    result <- try(dataDF <- getGeneralValueMetrics(iris,network,'',location,channel,starttime,endtime,metricName))
    if ( "try-error" %in% class(result) ) {
           stop(geterrmessage())
    }
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

