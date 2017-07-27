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
    # Special behavior for transfer funciton 'location'
    if (location == '00')
      location <- '10:00'
    else
      location <- paste(location,'00',sep=':')
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

    ###dataList <- getSingleValueMeasurements(iris,network,station,location,channel,starttime,endtime,metricName)
    dataDF <- getSingleValueMetrics(iris,network,station,location,channel,starttime,endtime,metricName)
    dataList <- split(dataDF, dataDF$metricName)

    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,station,location,channel,starttime,endtime,metricName)      

    
  } else if ( infoList$plotType == 'metricTimeseries' ) {

    if  (infoList$timeseriesChannelSet ) {
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
      ###dataList <- getSingleValueMeasurements(iris,network,station,location,channel,starttime,endtime,metricName)      
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
    dataList <- split(dataDF, dataDF$metricName)
    
    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,station,location,channel,starttime,endtime,actualMetricNames)      

    
  } else if (infoList$plotType == 'networkBoxplot' ) {
    
    # getNetwork returns network description
    dataList[['network_DF']] <- getNetwork(iris,network,'','','',starttime,endtime)

    # loads single values for each station based on whatever metric we ask for
    ######metricList <- getSingleValueMeasurements(iris,network,'',location,channel,starttime,endtime,metricName)
    ###dataList[['metric_DF']] <- metricList[[1]]
    dataDF <- getSingleValueMetrics(iris,network,'',location,channel,starttime,endtime,metricName)
    metricList <- split(dataDF, dataDF$metricName)
    dataList[['metric_DF']] <- metricList[[1]] # just to match the previous code, we could just use dataDF
    
    # transferFunctionCoherenceThreshold should only come in if metricName is one of the transfer metrics
    if (infoList$transferFunctionCoherenceThreshold) {
      dfTemp <- dataList[['metric_DF']]
      dfTemp <- dfTemp[dfTemp$ms_coherence > 0.999,]
      dataList[['metric_DF']] <- dfTemp
    }

    # Return BSS URL
    dataList[['bssUrl']] <- createBssUrl(iris,network,'',location,channel,starttime,endtime,metricName)      


  } else if (infoList$plotType == 'stationBoxplot' ) {
    
    # getNetwork returns station description
    dataList[['station_DF']] <- getStation(iris,network,station,'','',starttime,endtime)

    # loads single values for all seismic channels
    ###allSeismicChannels <- "LH.|LL.|LG.|LM.|LN.|MH.|ML.|MG.|MM.|MN.|BH.|BL.|BG.|BM.|BN.|HH.|HL.|HG.|HM.|HN."
    allSeismicChannels <- "LH?|LL?|LG?|LM?|LN?|MH?|ML?|MG?|MM?|MN?|BH?|BL?|BG?|BM?|BN?|HH?|HL?|HG?|HM?|HN?"
    ###metricList <- getSingleValueMeasurements(iris,network,station,'',allSeismicChannels,starttime,endtime,metricName)
    ###dataList[['metric_DF']] <- metricList[[1]]
    dataDF <- getSingleValueMetrics(iris,network,station,'',allSeismicChannels,starttime,endtime,metricName)
    metricList <- split(dataDF, dataDF$metricName)
    dataList[['metric_DF']] <- metricList[[1]] # just to match the previous code, we could just use dataDF
    
    # transferFunctionCoherenceThreshold should only come in if metricName is one of the transfer metrics
    if (infoList$transferFunctionCoherenceThreshold) {
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
    ###print(paste(round(elapsed,4),"seconds to load getNetwork"))
    logger.debug("%f seconds to load getNetwork", round(elapsed,4))
    
    dataList[['station_DF']] <- getStation(iris,network,'','','',starttime,endtime)
    
    elapsed <- ( (proc.time())[3] - timepoint )
    timepoint <- (proc.time())[3]
    ###print(paste(round(elapsed,4),"seconds to load getStation"))
    logger.debug("%f seconds to load getStation", round(elapsed,4))
    
    if (showEvents) {
      dataList[['event_DF']] <- getEvent(iris,starttime,endtime,minmag)
    } else {
      dataList[['event_DF']] <- NA
    }
    
    elapsed <- ( (proc.time())[3] - timepoint )
    timepoint <- (proc.time())[3]
    ###print(paste(round(elapsed,4),"seconds to load getEvent"))
    logger.debug("%f seconds to load getEvent", round(elapsed,4))
    
    # Loading world_countries dataframe for use in generating maps
    library(sp)
    load(paste(infoList$databrowserDir,'/data_local/simpleMap.RData',sep=""))
    dataList[['world_countries_DF']] <- world_countries
    
    elapsed <- ( (proc.time())[3] - timepoint )
    timepoint <- (proc.time())[3]
    ###print(paste(round(elapsed,4),"seconds to load simpleMap.RData"))    
    logger.debug("%f seconds to load simplemap.RData", round(elapsed,4))
    
    # get individual station measurements
    ###metricList <- getSingleValueMeasurements(iris,network,'',location,channel,starttime,endtime,metricName)
    ###dataList[['metric_DF']] <- metricList[[1]]
    dataDF <- getSingleValueMetrics(iris,network,'',location,channel,starttime,endtime,metricName)
    metricList <- split(dataDF, dataDF$metricName)
    dataList[['metric_DF']] <- metricList[[1]] # just to match the previous code, we could just use dataDF
    
    elapsed <- ( (proc.time())[3] - timepoint )
    timepoint <- (proc.time())[3]
    ###print(paste(round(elapsed,4),"seconds to load getSingleValueMeasurements"))
    logger.debug("%f seconds to load getSingleValueMetrics", round(elapsed,4))
    
    total_elapsed <- ( (proc.time())[3] - start )
    ###print(paste("Total elapsed =",round(total_elapsed,4),"seconds"))
    logger.debug("Total elapsed = %f seconds to load getSingleValueMetrics", round(elapsed,4))
    
    # Return BSS URL
    dataList[['bssUrl']] <- ''


  } else if (infoList$plotType == 'pdf' ) {
  
    url <- "http://service.iris.edu/mustangbeta/noise/pdf/1/query?"
    url <- paste(url,"network=",infoList$network,sep="")
    url <- paste(url,"&station=",infoList$station,sep="")
    # TODO:  Do I need to convert location="" to location="--"?
    url <- paste(url,"&location=",infoList$location,sep="")
    url <- paste(url,"&channel=",infoList$channel,sep="")
    url <- paste(url,"&quality=M",sep="")
    url <- paste(url,"&startday=",infoList$startdate,sep="")
    url <- paste(url,"&endday=",infoList$enddate,sep="")
    
    print(paste("pdf url = ",url))  
          
    # Get data from pdf webservice
    df <- read.csv(url,header=FALSE,skip=9,col.names=c("freq","power","count"),colClasses=c("numeric","integer","integer"))

    # Check for no data
    if (nrow(df) == 0) {
      stop("No data found.", call.=FALSE)
    }
    
    # TODO:  Remove power level check in data from pdf web service?
    # Retain only rows with power levels <= -50 db (bug in web service as of 2013-11-25)
    df <- df[df$power <= -50,]
    
    # TODO:  Some older PSDs in the database have a slightly offset set of frequencies.
    # TODO:  To be usable, we need to put the counts in a uniform set of bins.
    
    # Add variables with the row and column indices
    # i=row, j=column
    df$i <- 201 + df$power
    df$j <- as.numeric(as.factor(df$freq))
    
    freq <- sort(unique(df$freq))
    power <- seq(-200,-50,1)
      
#     # Sanity check until rebinning is in place
#     if (length(freq) > 100) {
#       stop(paste("Found",length(freq),"frequencies -- indicative of misaligned PSDs"))      
#     }
    
    # Create the pdfMatrix
    pdfMatrix <- matrix(data=0,nrow=length(power),ncol=length(freq))
    
    for (k in seq(nrow(df))) {
      pdfMatrix[df$i[k],df$j[k]] <- df$count[k]     
    }
    
    
    dataList[['pdfMatrix']] <- pdfMatrix
    dataList[['pdfFreq']] <- freq
    dataList[['pdfPower']] <- power

    # Return BSS URL
    dataList[['bssUrl']] <- url


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

