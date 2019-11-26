#
# plotUtils.R
#
# Various utility functions for use in creating plots for the MUSTANGDatabrowser.

################################################################################
# Quack plot styling for metric timeseries plots
################################################################################

# ----- Adjust starttime endtime and tickCount ---------------------------------

irisTickTimes <- function(starttime, endtime) {

  logger.info("----- irisTickTimes -----")

  DAY <- 24*3600
  dayCount <- as.numeric( difftime(endtime,starttime,units="days") )

  logger.debug("starttime = %s, endtime = %s, dayCount = %d", starttime, endtime, dayCount)

  # NOTE:  The endtime coming in should be the UI requested endtime and should be associated
  # NOTE:  with the day AFTER the last data record. We will create xlim and tickTimes
  # NOTE:  to get the best possible annotation for each time period.

  # NOTE:  If you don't specify the timezone "GMT" in the format line you will get formatting
  # NOTE:  for whatever the local timezone is for the machine running this code!!!

  if (dayCount == 1) {                           # one day with ticks on days before and after

    # Leave the endtime as the day after and create an additional day before so 
    # that our one point is in the middle
    starttime <- starttime - 24*3600
    tickTimes <- seq(starttime,endtime,by="day")
    tickLabels <- format(tickTimes,"%d-%b",tz="GMT")
    xlim <- c(starttime,endtime)

  } else if (dayCount > 1 && dayCount < 14) {     # < 2 weeks with ticks on days

    endtime <- endtime - 24*3600
    tickTimes <- seq(starttime,endtime,by="day")
    tickLabels <- format(tickTimes,"%d-%b",tz="GMT")
    xlim <- c(starttime,endtime)

  } else if (dayCount >= 14 && dayCount < 42) {   # < 1 month with ticks every week

    #endtime <- endtime - 24*3600
    tickTimes <- seq(starttime,endtime,by="week")
    tickLabels <- format(tickTimes,"%d-%b",tz="GMT")
    xlim <- c(starttime,endtime)

  } else if (dayCount >= 42 && dayCount < 95) {   # < 3 months with ticks every 2-weeks

    #endtime <- endtime - 24*3600
    tickTimes <- seq(starttime,endtime,by="2 weeks")
    tickLabels <- format(tickTimes,"%d-%b",tz="GMT")
    xlim <- c(starttime,endtime)

  } else if (dayCount >= 96 && dayCount < 366) { # six months with ticks on ~ month boundaries

    #endtime <- endtime - 24*3600
    tickTimes <- seq(starttime,endtime,by="month")
    tickLabels <- format(tickTimes,"%b-%Y",tz="GMT")
    xlim <- c(starttime,endtime)

  } else if (dayCount >= 366 && dayCount < 740) { # < 2 years with ticks on ~ quarters

    #endtime <- endtime - 24*3600
    tickTimes <- seq(starttime,endtime,by="3 months")
    tickLabels <- format(tickTimes,"%b-%Y",tz="GMT")
    xlim <- c(starttime,endtime)

  } else {                                       # default with ticks every 1/8

    #endtime <- endtime - 24*3600
    tickTimes <- seq(starttime,endtime,length.out=9)
    tickLabels <- format(tickTimes,"%b-%Y",tz="GMT")
    xlim <- c(starttime,endtime)

  }  
    
  return(list(xlim=xlim,
              tickTimes=tickTimes,
              tickLabels=tickLabels))
}


# ----- Basic timeseries plot --------------------------------------------------

timeseriesPlot <- function(time,
                           metric,
                           style='matlab',
                           xlim="",
                           yStyle='zeroScaled',
                           yRange="",
                           ...) {
  
  logger.info("----- timeseriesPlot -----")
  
  logger.debug("style = %s, yStyle = %s", style, yStyle)
  logger.debug(paste("yRange", yRange))
  
  # ----- Style ------------------------

  
  # Style dependent graphical parameters
  if (style == 'minimalA') {    

    # The 'minimalA' style reduces the annotations
    pch <- 15; col <- 'red'; cex <- 0.8
    las <- 1
    par(cex=1.0)
    showXAxis <- FALSE
    showYAxis <- TRUE
    showXGrid <- TRUE
    showYGrid <- FALSE
    showBox <- FALSE

  } else { # style = 'matlab'

    # Default setting mimics MATLAB style plots found in Quack
    pch <- 15; col <- 'red'; cex <- 1.0
    las <- 1
    par(cex=1.0)
    showXAxis <- TRUE
    showYAxis <- TRUE
    showXGrid <- TRUE
    showYGrid <- TRUE
    showBox <- TRUE

  }

  # ----- Set up xlim and x-axis -------

  ITT <- irisTickTimes(xlim[1],xlim[2])
  xlim <- ITT$xlim
  xAxTicks <- ITT$tickTimes
  xAxLabels <- ITT$tickLabels
  
  # ----- Set up ylim and y-axis -------

  if ( yRange == "") {
     ylo <- min(metric, na.rm=TRUE)
     yhi <- max(metric, na.rm=TRUE)
  } else {
     ylo <- yRange[1]
     yhi <- yRange[2]
  }

  if (yStyle == 'zeroScaled') { # 0:10 or 0:max, whichever is larger
    ylo <- 0
    yhi <- max(10,yhi)
    yrange <- yhi-ylo
    if (style == 'minimalA') {
      ylim <- c(ylo-0.2*yrange, yhi+0.4*yrange) # More room at the top for the label
      ##yAxTicks <- c(ylo,yhi)
      ##yAxLabels <- format(yAxTicks,nsmall=0)
      yAxTicks <- NULL
      yAxLabels <- NULL
    } else {
      ###ylim <- c(ylo-0.2*yrange, yhi+0.2*yrange)
      ylim <- c(ylo,yhi)
      yAxTicks <- NULL
      yAxLabels <- NULL
    }
    horizLine <- 0
  } else if (yStyle == 'zeroScaled1') { # 0:1 or 0:max, whichever is larger
    ylo <- 0
    yhi <- max(1,yhi)
    yrange <- yhi-ylo
    if (style == 'minimalA') {
      ylim <- c(ylo-0.2*yrange, yhi+0.4*yrange) # More room at the top for the label
      #yAxTicks <- c(ylo,yhi)
      #yAxLabels <- format(yAxTicks,nsmall=0)
      yAxTicks <- NULL
      yAxLabels <- NULL
    } else {
      ###ylim <- c(ylo-0.2*yrange, yhi+0.2*yrange)
      ylim <- c(ylo,yhi)
      yAxTicks <- NULL
      yAxLabels <- NULL
    }
    horizLine <- 0
  } else if (yStyle == 'zeroOrOne') { # 0:1
    ylo <- 0
    yhi <- 1
    yrange <- yhi-ylo
    if (style == 'minimalA') {
      ylim <- c(ylo-0.2*yrange, yhi+0.4*yrange) # More room at the top for the label
      #yAxTicks <- c(ylo,yhi)
      #yAxLabels <- c("FALSE","TRUE")
      yAxTicks <- NULL
      yAxLabels <- NULL
    } else {
      ###ylim <- c(ylo-0.2*yrange, yhi+0.2*yrange)
      ylim <- c(ylo,yhi)
      yAxTicks <- c(ylo,yhi)
      yAxLabels <- c("FALSE","TRUE")
    }
    horizLine <- 0
  } else if (yStyle == 'zeroCentered1') { # -1:1
    ylo <- -1
    yhi <- 1
    yrange <- yhi-ylo
    if (style == 'minimalA') {
      ylim <- c(ylo-0.2*yrange, yhi+0.4*yrange) # More room at the top for the label
      #yAxTicks <- c(ylo,yhi)
      #yAxLabels <- format(yAxTicks,nsmall=0)
      yAxTicks <- NULL
      yAxLabels <- NULL
    } else {
      ## <- ylim <- c(ylo-0.2*yrange, yhi+0.2*yrange)
      ylim=c(ylo,yhi)
      yAxTicks <- NULL
      yAxLabels <- NULL
    }
    horizLine <- 0
  } else if (yStyle == 'percent') { # 0:100
    ylo <- 0
    yhi <- 100
    yrange <- yhi-ylo
    if (style == 'minimalA') {
      ylim <- c(ylo-0.2*yrange, yhi+0.4*yrange) # More room at the top for the label
      #yAxTicks <- c(ylo,yhi)
      #yAxLabels <- format(yAxTicks,nsmall=0)
      yAxTicks <- NULL
      yAxLabels <- NULL
    } else {
      ###ylim <- c(ylo-0.2*yrange, yhi+0.2*yrange)
      ylim <- c(ylo,yhi)
      yAxTicks <- NULL
      yAxLabels <- NULL
    }
    horizLine <- 0
  } else if (yStyle == 'float') { # min:max
    yrange <- yhi-ylo
    if (style == 'minimalA') {
      ylim <- c(ylo-0.2*yrange, yhi+0.4*yrange) # More room at the top for the label
      #yAxTicks <- c(ylo,yhi)
      #yAxLabels <- format(yAxTicks,scientific=TRUE,digits=2)  
      yAxTicks <- NULL
      yAxLabels <- NULL
    } else {
      ###ylim <- c(ylo-0.2*yrange, yhi+0.2*yrange)
      ylim <- c(ylo,yhi)
      yAxTicks <- NULL
      yAxLabels <- NULL
    }
    horizLine <- NA
  } else { # min:max
    yrange <- yhi-ylo
    if (style == 'minimalA') {
      ylim <- c(ylo-0.2*yrange, yhi+0.4*yrange) # More room at the top for the label
      #yAxTicks <- c(ylo,yhi)
      #yAxLabels <- format(yAxTicks,scientific=TRUE,digits=2) 
      yAxTicks <- NULL
      yAxLabels <- NULL
    } else {
      ###ylim <- c(ylo-0.2*yrange, yhi+0.2*yrange)
      ylim <- c(ylo,yhi)
      yAxTicks <- NULL
      yAxLabels <- NULL
    }
    horizLine <- NA
  }

  # ----- Plotting --------------------

  plot(time, metric, 
       panel.first=rect(par("usr")[1],par("usr")[3],par("usr")[2],par("usr")[4], col="white"),
       xlim=xlim, ylim=ylim, bty='n',
       pch=pch, col=col, cex=cex,
       axes=FALSE, xlab="", ylab="",
       ...)

  # Create ticks and labels if they aren't already defined
  if (is.null(yAxTicks)) {
    yAxTicks <- axTicks(2)
    if (max(abs(yAxTicks)) >= 1e7) {
      ###yAxLabels <- format(yAxTicks,scientific=TRUE,digits=2)
      yAxLabels <- formatC(yAxTicks, digits=2, format="e")
    } else {
      yAxLabels <- yAxTicks
    }
  }

  if (showBox) { box() }

  abline(h=horizLine)

  # Make sure points are on top of any horizontal line
  points(time, metric,
         pch=pch, col=col, cex=cex,
         ...)
  
  # X axis and grid
  if (showXAxis) {
    axis.POSIXct(1, at=xAxTicks, labels=xAxLabels, line=0)
  }
  if (showXGrid) {
    abline(v=xAxTicks, col="lightgray", lty="dotted", lwd=par("lwd"))
  }
  
  # Y axis and grid
  if (showYAxis) {
    axis(side=2, las=1, at=yAxTicks, labels=yAxLabels)
  }
  if (showYGrid) {
    abline(h=yAxTicks, col="lightgray", lty="dotted", lwd=par("lwd"))
  }
  
}

