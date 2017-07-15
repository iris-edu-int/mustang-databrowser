################################################################################
# dailyDCOffsetDevelopmentPlot.R

dailyDCOffsetDevelopmentPlot <- function(dataList, infoList, textList) {

  library(zoo)  # for rollapply
  
  ########################################
  # Pull data out of list 
  ########################################
  
  df <- dataList[[1]]

  metricName <- infoList$metricName
  metricTitle <- textList$metricTitle
  
  ########################################
  # Calculate metric
  ########################################

  offsetDuration <- 5
  
  # Replace outliers with rolling median values
  outliers <- findOutliers(df[[metricName]],7,thresholdMin=6.0,selectivity=0.1)
  cleanMetricValues <- df[[metricName]]
  cleanMetricValues[outliers] <- roll_median(df[[metricName]],7)[outliers]
  
  DD <- list()
  metric <- rep(1.0,length(cleanMetricValues))
  for (i in seq(offsetDuration)) {
    # Create a daily metric from the lagged data with NA's at the beginning.  Each date has the difference
    # at that date from the value 'i' days earlier.
    dailyDiff <- c(rep(NA,i),abs(diff(cleanMetricValues,lag=i))) 
    DD[[i]] <- dailyDiff
    # Multiplying them together reduces theh importance of spikes and weights those shifts that last for N days.
    metric <- metric * dailyDiff 
  }
  exponent <- 1/offsetDuration
  metric <- metric^exponent
  # TODO:  Scale the metric by the median of the offsetDuration rolling sd
  roll_sd <- c(rep(NA,3),rollapply(cleanMetricValues,offsetDuration,sd),rep(NA,3))
  scaling <- quantile(roll_sd,0.5,na.rm=TRUE)
  metric <- metric / scaling
  
  ########################################
  # Set up style
  ########################################

  oldPar <- par()
  par(cex=1.5)

  ########################################
  # Plot the data
  ########################################
  
  layout(matrix(seq(4)))

  plot(df$starttime,df[[metricName]],pch=15,col='red',
       ylab="", las=1,
       cex.main=1.5, main=paste("Raw",metricTitle))
  
  plot(df$starttime,cleanMetricValues,pch=15,col='red',
       ylab="", las=1,
       cex.main=1.5, main=paste("Outlier-replaced",metricTitle))
  
  col <- adjustcolor('black',0.2)
  plot(df$starttime,DD[[1]],pch=16,col=col,
       ylab="", las=1,
       cex.main=1.5, main=paste("Using",offsetDuration,"wighting factors per day  (overlapping values are darker)"))
  for (i in seq(2,offsetDuration)) {
    points(df$starttime,DD[[i]],pch=15,col=col)
  }
  
  plot(df$starttime,metric,ylim=c(0,50),type='s',
       ylab="", las=1,
       cex.main=1.5, main=paste("Metric value and DC Offset detection threshold for offsets of",offsetDuration,"days"))
  abline(h=10,col='red')

  par(oldPar)
  
  ########################################
  # Return values
  ########################################

  return(c(1.0,2.0,3.0,4.0))

}

