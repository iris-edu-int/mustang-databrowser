# Adam Wisch & Jonathan Callahan
# October 2013
#
# Plot of ordered boxplots.
# 

stationBoxplotPlot <- function(dataList,infoList,textList) {
  
  logger.info("----- stationBoxplotPlot -----")
  
  # Configurable setting
  infoList$boxplotOrder <- "medianLoHi"

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
  
  ########################################
  # Extract dataframes from dataList
  ########################################
  
  station_DF <- dataList[['station_DF']]
  metric_DF <- dataList[['metric_DF']]

  # Need to remove missing values for boxplot to work properly (seiscode bug #630)
  missingMask <- is.na(metric_DF$value)
  metric_DF <- metric_DF[!missingMask,]

  ########################################
  # Data Manipulation for plotting
  ########################################

  metricValues <- metric_DF$value
  snclq <- metric_DF$snclq
  sncl <- stringr::str_replace(snclq,"..$","")  # remove last two characters
  
  # NOTE:  Support for different plot orders:
  # NOTE:  atValue passes a numbered order that tells boxplot in what order to plot the boxes/snclq values
  # NOTE:  tapply applies the 3rd argument as a function to the first argument,
  # NOTE:  so in the first case here it would apply the mean to the first argument, metricvalues.
  # NOTE:  The second argument keeps an index of the values to their corresponding snclq strings.
  # NOTE:  Rank is then applied to this, returning the ranks of the values in the vector. 
   
  if (infoList$boxplotOrder == "meanLoHi") {
    atValue <- rank(tapply(metricValues, sncl, mean), ties.method = "first")
  } else if (infoList$boxplotOrder == "meanHiLo") {
    atValue <- rank(tapply(-metricValues, sncl, mean), ties.method = "first")
    
  } else if (infoList$boxplotOrder == "medianLoHi") {
    atValue <- rank(tapply(metricValues, sncl, median), ties.method = "first")
  } else if (infoList$boxplotOrder == "medianHiLo") {
    atValue <- rank(tapply(-metricValues, sncl, median), ties.method = "first")
    
  } else if (infoList$boxplotOrder == "sd") {
    atValue <- rank(tapply(metricValues, sncl, sd), ties.method = "first")
  
  } else if (infoList$boxplotOrder == "minLoHi") {
    atValue <- rank(tapply(metricValues, sncl, min), ties.method = "first")
  } else if (infoList$boxplotOrder == "minHiLo") {
    atValue <- rank(tapply(-metricValues, sncl, max), ties.method = "first")
    
  } else if (infoList$boxplotOrder == "maxLoHi") {
    atValue <- rank(tapply(metricValues, sncl, max), ties.method = "first")
  } else if (infoList$boxplotOrder == "maxHiLo") {
    atValue <- rank(tapply(-metricValues, sncl, min), ties.method = "first")
    
  } else if (infoList$boxplotOrder == "alphaLoHi") {
    atValue <- seq(length(unique(sncl)),1)
  # aplhaHiLo last
  } else {
    atValue <- seq(1,length(unique(sncl)))
  }
  
  ########################################
  # Plotting        
  ########################################
  
  if (metricName == "percent_availability") {
    ylim <- c(0,100)
  } else {
    ylim <- NULL
  }
  
  # Save current par settings so we can restore them at the end
  oldPar <- par()

  par(mar=c(5,11,7,2)+.1, las=1)
  
  plotMetrics <- boxplot(metricValues ~ sncl, ylim=ylim,
                         outline=infoList$boxplotShowOutliers,
                         horizontal=TRUE, at=atValue,
                         xlab="")
  
  axis(3)
  
  # TODO:  All annotations should be created in createTextList_en.R
  
  title(textList$stationTitle, line=5)
  mtext(textList$metricTitle, side=3, line=2.5, cex=1.2)
  mtext(textList$dataRange, side=1, line=2.5, cex=1.2)

  # TODO:  Add date range description
  
  # Restore old par() settings
  par(oldPar)
   
  return(c(1.0,2.0,3.0,4.0))
  
}

