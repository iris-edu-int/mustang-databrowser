# translateErrors.R
#
# Adam Wisch
# November 2013
#
# Error message rationalization for MUSTANGDatabrowser


# Convert programmer error messages into end user error messages
translateErrors <- function(err_msg,infoList) {

  # Log error message for debugging. Helps when we need to add more/better string detection.
  logger.debug("err_msg = %s", err_msg)
  
  metricName <- infoList$metricName
  
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
  if (infoList$plotType == "networkBoxplot") {
    snclName <- paste(infoList$network,'*',location,infoList$channel,sep='.')
  } else if (infoList$plotType == "stationBoxplot") {
    snclName <- paste(infoList$network,infoList$station,'*.*',sep='.')
  } else {
    if (infoList$timeseriesChannelSet) {
      snclName <- paste(infoList$network,'.',infoList$station,'.',location,'.',infoList$channel,'?',sep='')        
    } else {
      snclName <- paste(infoList$network,infoList$station,location,infoList$channel,sep='.')    
    }
  }
  
  if (stringr::str_detect(err_msg,"No targets were found after filtering")) {
    return(paste("No",metricName,"values found for",snclName))
  } else if (stringr::str_detect(err_msg,"cannot open the connection")) {
    # getNetwork could not find a network
    # starttime is too late
    # endtime is too early
    # also this happens if it can't connect to the server and getEvent fails
    # also this happens if it can't connect to the server and getNetwork fails
    return(paste("No",metricName,"values found for",snclName))
    
  } else if (stringr::str_detect(err_msg,"miniseed2Stream: No data found")) {
    
    # dataselect web service failed
    return(paste("Dataselect service returns no data for ",snclName))      
    
  } else if (stringr::str_detect(err_msg,"Could not resolve host:") ||
               stringr::str_detect(err_msg,"unable to resolve")) {
    
    # if it cannot connect to the server
    return("Could not connect to server")

  # NOTE:  Error message is not specific to the function. Here is an example"
  # NOTE:  
  # NOTE:  Error in read.table(file = file, header = header, sep = sep, quote = quote,  : 
  # NOTE:    no lines available in input
                        
  } else if (stringr::str_detect(err_msg,"measurementName : replacement has length zero")) {

    # This happens when measurement service returns with header columns but no data
    return(paste("No",metricName,"values found for",snclName))

  } else if (stringr::str_detect(err_msg,"getEvent.IrisClient: No Data") ||
               stringr::str_detect(err_msg,"No data found")) {
    
    # getEvent could not get any data since minmag is too large
    # also this happens if it can't connect to the server and getEvent fails
    return(paste("No",metricName,"values found for",snclName))

  } else if (stringr::str_detect(err_msg,"unique sampling rates encountered in Stream")) {

    pattern <- "mergeTraces.Stream:.*"
    pattern_match <- regmatches(err_msg, regexec(pattern,err_msg))[[1]][1]
    pattern_match <- gsub(".Stream","",pattern_match,fixed=TRUE)
    pattern_match <- stringr::str_trim(gsub("encountered in Stream.","",pattern_match))
    return(paste("Error in",pattern_match))

  } else if (stringr::str_detect(err_msg,"Operation timed out")) {
    return("Operation timed out")

  } else if (stringr::str_detect(err_msg,"Error allocating memory") || 
             stringr::str_detect(err_msg,"Cannot allocate memory")) {
    return("Error allocating memory")

  } else if (stringr::str_detect(err_msg, "Please select time span")) {
    err_msg_sub <- stringr::str_split(err_msg,"Please")[[1]][2]
    return(paste("Please",err_msg_sub))
    
  } else {
    return(err_msg)
  }

}           







