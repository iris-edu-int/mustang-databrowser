# gapDurationPlot.R
#
# Create 4 plots based on a gap duration list:
# Date vs Gap Duration
# Time of Day vs Gap Duration
# Histogram
# Date vs Gap Count
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
  xlim2 <- as.Date(xlim)  #
  options(scipen=5)

  df <- dataList[['gapListDF']]
  df2 <- dataList[['numGapDF']]
  ylo <- min(df2$value, na.rm=TRUE)
  yhi <- max(df2$value, na.rm=TRUE)
  yhi <- max(10,yhi)

  # ----- Style ----------------------------------------------------------------
  
  # Save current par() settings
  oldPar <- par()
  par(bg='gray95', mar=c(4,3,3,4), oma=c(4,4,4,0))
  las <- 1
  par(cex=1.0)

  ylim <- c(1,10^ceiling(log10(max(df$gapLength, na.rm=TRUE))))

  lseqBy <- function(from=1, to=100000, by=1, length.out=log10(to/from)+1) {  #from stackOverflow
     tmp <- exp(seq(log(from), log(to), length.out = length.out))
     tmp[seq(1, length(tmp), by)]  
  }

  yAxTicks <- lseqBy(ylim[1],ylim[2],by=1)
  yAxLabels <- NULL
  
  # ----- Plotting -------------------------------------------------------------
  
  plotCount <- 4
  #plotCount <- 3
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

  #plot(df$gapStart,df$gapLength, 
  plot(as.POSIXct(df$calendar,tz="GMT"),df$gapLength,
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


  xlim2 <- c(0,86400)
  xAxTicks2 <- seq(0,86400,14400)
  plot(df$timeOfDay,df$gapLength, 
       panel.first=rect(par('usr')[1],10^par('usr')[3],par('usr')[2],10^par('usr')[4], col='white'),
       log='y', pch=15, col=rgb(red=1,green=0,blue=0,alpha=trns),
       axes=FALSE, ylim=ylim,cex=1.5,cex.axis=1.5,xlim=xlim2,xlab="",ylab="")

  box()
  line <- par('oma')[2] + 1.5
  mtext(textList$metricYlab, side=2, line=line, cex=1.0)
  line <- par('oma')[1] - 1
  mtext("Time of Day (UTC)",side=1,line=line,cex=1.0)

  axis(side=1,at=xAxTicks2,labels=c("00:00","04:00","08:00","12:00","16:00","20:00","24:00"),cex.axis=1.5)
  abline(v=xAxTicks2, col="lightgray", lty="dotted", lwd=par("lwd"))
  axis(side=2, at=yAxTicks, las=1,cex.axis=1.5)
  abline(h=yAxTicks, col="lightgray", lty="dotted", lwd=par("lwd"))

  h <- hist(df$gapLength,plot=FALSE)
  hyhi <- max(5,h$counts)
  hylim <- c(0,hyhi)

  # Rice's rule for histogram breaks: cubed root of the number of obervations times 2
  # https://www.statisticshowto.datasciencecentral.com/choose-bin-sizes-statistics/
  # but also set minimum number of breaks at 5 
  breaks <- 2*(length(df$gapLength)^(1/3))

  # can also try the square root rule
  #breaks <- sqrt(length(df$gapLength))

  if (breaks < 5) {
      breaks <- 5
  }

  hist(df$gapLength,breaks=breaks,ylim=hylim,xlab="",col="lightblue",main="",cex.axis=1.5,
       panel.first=rect(par('usr')[1],par('usr')[3],par('usr')[2],par('usr')[4], col='white'))

  box()
  line <- par('oma')[2] + 1.5
  mtext("frequency", side=2, line=line, cex=1.0)
  line <- par('oma')[1] - 1
  mtext("Gap Length (seconds)",side=1,line=line,cex=1.0)

  #yStyle <- 'zeroScaled'
  #style <- 'matlab'
  #timeseriesPlot(df2$starttime, df2$value, style, xlim=xlim, ystyle=yStyle)

  ylim <- c(ylo,yhi)
  
  plot(df2$starttime, df2$value,
       panel.first=rect(par('usr')[1],par('usr')[3],par('usr')[2],par('usr')[4], col='white'),
       pch=15, col=rgb(red=1,green=0,blue=0,alpha=1),
       xlim=xlim, ylim=ylim, cex=1.5,cex.axis=1.5,ylab="",xlab="",axes=FALSE)

  box()
  line <- par('oma')[2] + 1.5
  mtext("gap count (number of occurences)", side=2, line=line, cex=1.0)

  line <- par('oma')[1] - 1
  mtext("Date",side=1,line=line,cex=1.0)

  yAxTicks <- axTicks(2)
  if (max(abs(yAxTicks)) >= 1e7) {
      yAxLabels <- formatC(yAxTicks, digits=2, format="e")
  } else {
      yAxLabels <- yAxTicks
  }

  axis.POSIXct(1, at=xAxTicks, labels=xAxLabels, line=0,cex.axis=1.5)
  abline(v=xAxTicks, col="lightgray", lty="dotted", lwd=par("lwd"))
  axis(side=2, at=yAxTicks, las=1,cex.axis=1.5)
  abline(h=yAxTicks, col="lightgray", lty="dotted", lwd=par("lwd"))
  
  

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
