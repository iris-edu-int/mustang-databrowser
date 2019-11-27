# gapDurationPlot.R
#
# Create 3 plots based on a gap duration list:
# Date vs Gap Duration
# Time of Day vs Gap Duration
# Histogram
#
# Author: Gillian Sharer
#         
########################################################################


gapDurationPlot <- function(dataList, infoList, textList, ...) {
 
  
  # Get items from infoList 
  metricName<- infoList$metricName 
  starttime <- infoList$starttime
  endtime <- infoList$endtime
  xlim <- c(starttime,endtime)
  #xlim <- c(as.Date(starttime),as.Date(endtime))
  options(scipen=5)

  df <- dataList[['gapList_DF']]
  ylo <- min(df$gapLength, na.rm=TRUE)
  yhi <- max(df$gapLength, na.rm=TRUE)

  logger.debug("gapDurationPlot here")
  logger.debug("snclName")
  logger.debug(textList$snclName)
  logger.debug("Title")
  logger.debug(textList$metricTitle)
  logger.debug("gapDurationPlot here2")

  # ----- Style ----------------------------------------------------------------
  
  # Save current par() settings
  oldPar <- par()
  par(bg='gray95', mar=c(4,3,3,4), oma=c(4,4,4,0))
  las <- 1
  par(cex=1.0)

  ylo <- 1
  yhi <- max(10,yhi)
  yrange <- yhi-ylo

  ylim <- c(1,10^ceiling(log10(max(df$gapLength, na.rm=TRUE))))

  lseqBy <- function(from=1, to=100000, by=1, length.out=log10(to/from)+1) {  #from stackOverflow
     tmp <- exp(seq(log(from), log(to), length.out = length.out))
     tmp[seq(1, length(tmp), by)]  
  }

  yAxTicks <- lseqBy(ylim[1],ylim[2],by=1)
  yAxLabels <- NULL
  
  # ----- Plotting -------------------------------------------------------------
  
  plotCount <- 3
  mat <- matrix(c(seq(1,plotCount)), plotCount, 1)
  layout(mat)

  ITT <- irisTickTimes(xlim[1],xlim[2])
  xlim <- ITT$xlim
  xAxTicks <- ITT$tickTimes
  xAxLabels <- ITT$tickLabels

  if (nrow(df) >= 1000) {
    trns <- 0.5
  } else if (nrow(df) >= 500) {
    trns <- 0.7
  } else {
    trns <- 1
  }

  plot(df$gapStart,df$gapLength, 
       panel.first=rect(par('usr')[1],10^par('usr')[3],par('usr')[2],10^par('usr')[4], col='white'),
       log='y', pch=15, col=rgb(red=1,green=0,blue=0,alpha=trns),
       xlim=xlim, ylim=ylim,cex=1.5,cex.axis=1.5,ylab="",xlab="",axes=FALSE)
  
  box()
  line <- par('oma')[2] + 1.5
  mtext(textList$metricYlab, side=2, line=line, cex=1.0)

  line <- par('oma')[1] - 1
  mtext("Date",side=1,line=line,cex=1.0)

  axis.POSIXct(1, at=xAxTicks, labels=xAxLabels, line=0,cex.axis=1.5)
  abline(v=xAxTicks, col="lightgray", lty="dotted", lwd=par("lwd"))
  axis(side=2, at=yAxTicks, las=1,cex.axis=1.5)
  abline(h=yAxTicks, col="lightgray", lty="dotted", lwd=par("lwd"))


  xlim <- c(0,86400)
  xAxTicks <- seq(0,86400,14400)
  plot(df$timeOfDay,df$gapLength, 
       panel.first=rect(par('usr')[1],10^par('usr')[3],par('usr')[2],10^par('usr')[4], col='white'),
       log='y', pch=15, col=rgb(red=1,green=0,blue=0,alpha=trns),
       axes=FALSE, ylim=ylim,cex=1.5,cex.axis=1.5,xlim=xlim,xlab="",ylab="")

  box()
  line <- par('oma')[2] + 1.5
  mtext(textList$metricYlab, side=2, line=line, cex=1.0)
  line <- par('oma')[1] - 1
  mtext("Time of Day (UTC)",side=1,line=line,cex=1.0)

  axis(side=1,at=xAxTicks,labels=c("00:00","04:00","08:00","12:00","16:00","20:00","24:00"),cex.axis=1.5)
  abline(v=xAxTicks, col="lightgray", lty="dotted", lwd=par("lwd"))
  axis(side=2, at=yAxTicks, las=1,cex.axis=1.5)
  abline(h=yAxTicks, col="lightgray", lty="dotted", lwd=par("lwd"))

  hist(df$gapLength,breaks=5,xlab="",col="lightblue",main="",cex.axis=1.5)
  box()
  line <- par('oma')[2] + 1.5
  mtext("frequency", side=2, line=line, cex=1.0)
  line <- par('oma')[1] - 1
  mtext("Gap Length (seconds)",side=1,line=line,cex=1.0)

  # ----- Annotations ----------------------------------------------------------

  # Annotations are created in createTextList_en.R
  
  # Title at the top
  text <- paste(textList$snclName,'--',textList$metricTitle,"\n(number of gaps=",nrow(df),")")
  title(text, outer=TRUE,cex.main=1.8)

  # Dates of available data at the bottom
  line <- par('oma')[1] + 2
  mtext(textList$dataRange, side=1, line=line, cex=1.3)

  # Restore old par() settings
  par(oldPar)

  return(c(1.0,2.0,3.0,4.0))
  
}
