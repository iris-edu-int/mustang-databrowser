# Adam Wisch & Jonathan Callahan
# October 2013
#
# Plots network on world map
# Colors stations based on different metrics (default is percent_availability)
# Option to plot text of each station identifier
# Option to change the start and end times and will remove stations that do not fall in the range
# 
################################################################################
# TODO: uncomment ability to post station names and give user option to do so
# TODO: give user ability to change start and end times so stations do not show up based on user input
# TODO: give user ability to plot events
# TODO: give user ability to change event min/max magnitudes OR other variables (complicated)
################################################################################

networkMapPlot <- function(dataList,infoList,textList) {
  
  ########################################
  # Extract local variables from the infoList
  ########################################
  
  # metricName specifies which metric we want from the MUSTANG database
  metricName  <- infoList$metricName 
  
  # Extract elements for use in web service requests
  network  <- infoList$network
  station  <- infoList$station
  location <- infoList$location
  channel  <- infoList$channel
  quality  <- infoList$quality
  starttime <- infoList$starttime
  endtime <- infoList$endtime
  
  # Additional flags for network maps
  showEvents  <- as.logical(ifelse(is.null(infoList$showEvents),'FALSE',infoList$showEvents))
  
  
  ########################################
  # Extract dataframes from dataList
  ########################################
  
  networkDesc <- dataList[['network_DF']]
  stations <- dataList[['station_DF']]
  # TODO:  Filter the stations based on epoch?  We might be requesting data that crosses epoch boundaries.
  stations <- stations[!duplicated(stations$station),]  # remove duplicates representing different 'epochs'
  events <- dataList[['event_DF']]
  world_countries <- dataList[['world_countries_DF']] 
  metricValues <- dataList[['metric_DF']]

  stationCount <- nrow(stations)
  
  
  ########################################
  # Style
  ########################################
  
  # Save current par settings so we can restore them at the end
  oldPar <- par()
  
  # Add some more space on the bottom to accommodate the legend
  par(mar=c(7,4,4,2))
  
  col_station <- 'black'
  pch_station <- 1
  cex_station <- 1.8
  lwd_station <- 1.0
  
  # NOTE:  metric colors will be obtained from a column in the stations dataframe (see below)
  # col_metric <- 'black'
  pch_metric <- 16
  cex_metric <- 1.6
  lwd_metric <- 1.0
  
  # Plot background colors
  oceanColor <- "#C7E6FA" 
  landColor <- "#F3F1ED"
  
  # NOTE:  Choosing indicator colors is very personal. We need to get ready to support our choices.
  # NOTE:  The USFS fire danger indicator is widely known and I belive they have done their homework
  # NOTE:  with regard to color blindness and color psychology.
  
  # Colors from fire danger indicator at http://www.fs.usda.gov/detail/angeles/news-events/?cid=STELPRDB5327618
  USFS_low <- "#238D65"       # greenish
  USFS_moderate <- "#2A9ED9"  # blueish
  USFS_high <- "#FEE71F"      # yellowish
  USFS_very_high <- "#F6A553" # orangeish
  USFS_extreme <- "#EF4246"   # reddish
  USFS_critical <- "#373536"  # blackish
  
  # Metric values colors for Low-Medium-High
  greenish <- USFS_low
  yellowish <- USFS_high
  redish <- USFS_extreme  
  
  ########################################
  # Attach mean values from metricValues to individual stations
  ########################################
  
  # Add the metricName as another column in the stations dataframe
  stations[[metricName]] <- NA
  
  # For every row in the stations dataframe
  #   1) create a sncl using that station name
  #   2) create a subset of metricValues containing only rows where sncl is found within metricValues$snclq
  #   3) store the mean of metricName in the subset as metricName in the row of stations associated with this station
  for (i in seq(stationCount)) {
    # NOTE:  A BLANK location is "--" for all web services except the measurement
    # NOTE:  web service. We need to convert here in order to use grepl.
    blankLocation <- str_replace(location,"--","")
    sncl <- paste(network, stations$station[i], blankLocation, channel, sep='.')
    dfSubset <- subset(metricValues, grepl(sncl,snclq))
    # TODO:  Should we be averaging every metric including "sample_max" or do we want max or min of some metrics?
    stations[i,metricName] <- mean(dfSubset[[metricName]], na.rm=TRUE)
  } 
  
  # Create 3 quantiles based on the values of metricName stored in the stations dataframe
  if (metricName == 'percent_availability') {
    breaks <- c(0,50,95,100)
    binColors <- c(redish, yellowish, greenish)
    legendColors <- c("black",binColors)
    legendLabels <- c("missing","<50%","50-95%",">95%")
    legendSymbols <- c(1,rep(16,3))
    numberCol <- 4
    
    # special percent value
  } else if (metricName == 'timing_quality') {
    breaks <- c(0,90,99,100)
    binColors <- c(redish, yellowish, greenish)
    legendColors <- c("black",binColors)
    legendLabels <- c("missing","<90%","90 - 99%",">99%")
    legendSymbols <- c(1,rep(16,3))
    numberCol <- 4
    
    # metrics that have values of 0 for all
  } else if (metricName == 'amplifier_saturation' ||
               metricName == 'calibration_signal' ||
               metricName == 'digitizer_clipping' ||
               metricName == 'event_begin' ||
               metricName == 'event_end' ||
               metricName == 'glitches' ||
               metricName == 'missing_padded_data' ||
               metricName == 'spikes' ||
               metricName == 'telemetry_sync_error' ||
               metricName == 'timing_correction') {
    breaks <- 0
    binColors <- c("black")
    legendColors <- binColors
    legendLabels <- "This metric has values of zero everywhere"
    legendSymbols <- c(1)
    numberCol <- 1
    
    # latency else if statement ( millisecond values)
  } else if (metricName == 'data_latency' ||
               metricName == 'feed_latency') {
    breaks <- c(0,200,1000,10e30)
    binColors <- c(greenish, yellowish, redish)
    legendColors <- c("black",binColors)
    legendLabels <- c("missing","<200 ms","200 - 1000 ms","> 1000 ms")
    legendSymbols <- c(1,rep(16,3))
    numberCol <- 4
    
    # metrics that are close to logarithmic with emphasis on 0 or a low value
  } else if(metricName == "sample_rms" ||
              metricName == "digital_filter_charging" ||
              metricName == "event_in_progress" ||
              metricName == "max_stalta" ||
              metricName == "num_gaps" ||
              metricName == "sample_snr" ||
              metricName == "total_latency") {
    breaks <- quantile(stations[[metricName]], probs=c(0,0.95,0.99,1.0), na.rm=TRUE, names=FALSE)
    binColors <- c(greenish, yellowish, redish)
    legendColors <- c("black",binColors)
    legendLabels <- c("missing","0 - 95th percentile","95th to 99th percentile","99th percentile")
    legendSymbols <- c(1,rep(16,3))
    numberCol <- 4
    
    # quantile breaks of 0,33%,66%,100%
    # Metrics that fall through to here:
    # clock_locked
    # max_gap
    # max_overlap
    # num_overlaps  # re-examine above for only one that had a value, question what the true meaning of it is
    # num_spikes
    # sample_max
    # sample_mean
    # sample_median
    # sample_min
    # suspect_time_tag
    # timing_quality
  } else {
    breaks <- quantile(stations[[metricName]], probs=c(0,0.33,0.67,1.0), na.rm=TRUE, names=FALSE)
    binColors <- c(greenish, yellowish, redish)
    legendColors <- c("black",binColors)
    legendLabels <- c("missing","low","medium","high")
    legendSymbols <- c(1,rep(16,3))
    numberCol <- 4
  }
  
  # NOTE:  Some stations will have no metric value and will generate a bincode of NA.
  # NOTE:  This is good as stations$color for these will also be NA and these stations
  # NOTE:  will not appear when metric values are plotted.
  
  # Create a numeric vector of quantile # in the stations dataframe
  bincode <- .bincode(stations[[metricName]], breaks=breaks, include.lowest=TRUE)
    
  # Create another column of color values in the stations dataframe to be used when plotting points
  stations$color <- binColors[bincode]
  
  
  ########################################
  # Determine bounds of map
  ########################################
  
  minLon <- min(stations$longitude)
  maxLon <- max(stations$longitude)
  
  minLat <- min(stations$latitude)
  maxLat <- max(stations$latitude)
  
  if(abs(minLon - maxLon) < 1) {
    
    # Very small regions needs large expansion
    xlim <- c(minLon - 8, maxLon + 8)
    ylim <- c(minLat - 8, maxLat + 8)
    
  } else if(abs(minLon - maxLon) < 6 & !(stationCount > 20)) {
    
    # Medium expansion
    xlim <- c(minLon - 5, maxLon + 5)
    ylim <- c(minLat - 5, maxLat + 5)
    
  } else if(abs(minLon - maxLon) < 180) {
    
    # Small expansion
    xlim <- c(minLon - 1, maxLon + 1)
    ylim <- c(minLat - 1, maxLat + 1)
    
  } else {
    
    # No expansion
    xlim <- c(minLon - 0, maxLon + 0)
    ylim <- c(minLat - 0, maxLat + 0)
    
  }
  
  
  ########################################
  # Plotting        
  ########################################

  # Base map
  plot(world_countries, axes=TRUE, bg=oceanColor, col=landColor,
       xlim=xlim, ylim=ylim,
       las=1, lwd=.15)
  
  # Overlay the box in case any polygons have covered over part of it
  box()
  
  # Overlaly US states
  map(database="state", lwd=.1, add=TRUE)
  
  # Add station mean values where they exist
  points(stations$longitude, stations$latitude,
         pch=pch_metric, cex=cex_metric, col=stations$color, lwd=lwd_metric)

  # All stations
  points(stations$longitude, stations$latitude,
         pch=pch_station, cex=cex_station, col=col_station, lwd=lwd_station)
    

  ########################################
  # Add station labels
  # TODO: Uncoment text() line to get station labels on map if desired
  # TODO: Give user option to add labels (Maybe do this)
  ########################################
  
  #text(stations$longitude,stations$latitude,labels=stations$station,adj=c(1,0),pos=4,offset=0.45,cex=0.6)
  
  ########################################
  # Plot large seismic events
  # Default is to not plot since it takes a long time to load data in
  ########################################
  if(showEvents) {
    points(events$longitude,events$latitude,col='purple',pch=1,cex=3)
  }
  
  ########################################
  # Add Legend, Title, Station description
  ########################################
  
  # TODO:  Create nice legend text
  legend("bottom", inset=-.31, bg='white', ncol=numberCol, xpd=NA, bty='n',
         title=metricName, legend=legendLabels, 
         col=legendColors, pch=legendSymbols, pt.cex=cex_metric, pt.lwd=lwd_metric)
  
  # Add the starttime and endtime to the top
  netStartTime <- format(networkDesc$starttime, format='%Y',tz="GMT")
  netEndTime   <- format(networkDesc$endtime, format='%Y',tz="GMT")
  
  # Add number of stations plotted and network identifier
  if(stationCount == 1) {
    title(cex=0.8, main=paste(network," Network (",netStartTime,' - ', netEndTime,') ', stationCount, " Station", sep=''), xpd=NA, bty="n")
  } else {
    title(cex=0.8, main=paste(network," Network (",netStartTime,' - ', netEndTime,') ', stationCount, " Stations", sep=''), xpd=NA, bty="n")
  }
  
  # Add description of network in italic under the title
  mtext(text = networkDesc$description, font=4, cex=1, line=0.3 )
  

  # Restore old par() settings
  par(oldPar)
   
  return(c(1.0,2.0,3.0,4.0))
  
}




# For safekeeping
#   metricName == 'amplifier_saturation' ||
#     metricName == 'calibration_signal' ||
#     metricName == 'clock_locked' ||
#     metricName == 'correlation_coefficient' ||
#     metricName == 'data_latency' ||
#     metricName == 'dc_offset_times' ||
#     metricName == 'digital_filter_charging' ||
#     metricName == 'digitizer_clipping' ||
#     metricName == 'event_begin' ||
#     metricName == 'event_end' ||
#     metricName == 'event_in_progress' ||
#     metricName == 'feed_latency' ||
#     metricName == 'glitches' ||
#     metricName == 'max_gap' ||
#     metricName == 'max_overlap' ||
#     metricName == 'max_stalta' ||
#     metricName == 'missing_padded_data' ||
#     metricName == 'num_gaps' ||
#     metricName == 'num_overlaps' ||
#     metricName == 'num_spikes' ||
#     metricName == 'percent_availability' ||
#     metricName == 'psd' ||
#     metricName == 'sample_max' ||
#     metricName == 'sample_mean' ||
#     metricName == 'sample_median' ||
#     metricName == 'sample_min' ||
#     metricName == 'sample_rms' ||
#     metricName == 'sample_snr' ||
#     metricName == 'spikes' ||
#     metricName == 'station_completeness' ||
#     metricName == 'station_up_down_times' ||
#     metricName == 'suspect_time_tag' ||
#     metricName == 'telemetry_sync_error' ||
#     metricName == 'timing_correction' ||
#     metricName == 'timing_quality' ||
#     metricName == 'total_latency' ||
#     metricName == 'up_down_times' )

