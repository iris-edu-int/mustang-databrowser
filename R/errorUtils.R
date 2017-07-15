# errorUtils.R
#
# Adam Wisch
# November 2013
#
# Error message rationalization for MUSTANGDatabrowser


# Convert programmer error messages into end user error messages
translateErrors <- function(err_msg,infoList) {

  # Print out error message for debugging. Helps when we need to add more/better string detection.
  print(paste("err_msg =",err_msg))
  
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
  
  if (str_detect(err_msg,"No targets were found after filtering")) {
    
    # handles getSingleValueMeasurements problems with parameters.
    return(paste("No",metricName,"data found for",snclName))
    
  } else if (str_detect(err_msg,"cannot open the connection")) {
    
    # getNetwork could not find a network
    # starttime is too late
    # endtime is too early
    # also this happens if it can't connect to the server and getEvent fails
    # also this happens if it can't connect to the server and getNetwork fails
    return(paste("No",metricName,"data found for",snclName))
    
  } else if (str_detect(err_msg,"miniseed2Stream: No data found")) {
    
    # dataselect web service failed
    return(paste("Dataselect service returns no data for ",snclName))      
    
  } else if (str_detect(err_msg,"Could not resolve host:") ||
               str_detect(err_msg,"unable to resolve")) {
    
    # if it cannot connect to the server
    return("Could not connect to server")

  } else if (str_detect(err_msg,"getSingleValueMeasurements.IrisClient: Metric")) {
    
    # if metricname is wrong
    return("Incorrect metric name")
    
  } else if (str_detect(err_msg,"measurementName : replacement has length zero")) {

    # This happens when measurement service returns with header columns but no data
    return(paste("No",metricName,"data found for",snclName))

  } else if (str_detect(err_msg,"getEvent.IrisClient: No Data") ||
               str_detect(err_msg,"No data found")) {
    
    # getEvent could not get any data since minmag is too large
    # also this happens if it can't connect to the server and getEvent fails
    return(paste("No",metricName,"data found for",snclName))
    
  } else {
    
    return(err_msg)
  }

}           







