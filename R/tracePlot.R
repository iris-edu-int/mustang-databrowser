############################################################
# tracePlot
############################################################

# Large time series reduction for  plot
# from http://iwoaf.com/plot-large-time-series-with-r/

traceReduce <- function(x, n=2^10) {
  if(class(x) != "Trace") { 
    stop('input argument class must be "Trace"')
  }
  p <- length(x)
  L <- floor(p/n)
  if (p<n){
    return(x)
  }else {
    y  <- matrix(as.numeric(x@data[1:(L*n)]),n,L,byrow=TRUE)
    y.min <- apply(y, 1, min)
    y.max <- apply(y, 1, max)
    y.minmax <- matrix(rbind(y.min,y.max),2*n,1,byrow=FALSE)

    x@data <- as.vector(y.minmax)
    x@stats@sampling_rate <- x@stats@sampling_rate*L/2
    x@stats@processing <- "processed by traceReduce for plotting"
    x@stats@npts <- length(x)

    return(x)
  }
}

plot.Stream <- function(x, ...) {

  tr <- mergeTraces(x)
  tr <- traceReduce(tr@traces[[1]])

  plot(tr, ...)
  if (length(x@traces) == 1) {
    graphics::mtext(paste(length(x@traces),"trace"), side=3, line=0.2, adj=0.95)
  } else {
    graphics::mtext(paste(length(x@traces),"traces"), side=3, line=0.2, adj=0.95)
  }

}
setMethod("plot", signature(x="Stream"), function(x, ...) plot.Stream(x, ...))


plot.Trace <- function(x, starttime=x@stats@starttime, endtime=x@stats@endtime,add=FALSE, ylab="raw", ...) {
  x <- traceReduce(x)
  id <- stringr::str_sub(x@id, 1, stringr::str_length(x@id)-2)
  main <- paste("Seismic Trace for ",id,sep="")
  sensorText <- paste("(", x@Sensor, ")")
  # Create array of times
  times <- seq(from=x@stats@starttime, to=x@stats@endtime, length.out=length(x@data))
  xlab <- paste("Dates ",as.Date(x@stats@starttime),"to",as.Date(x@stats@endtime))

  # Plot
  if (difftime(x@stats@endtime,x@stats@starttime,units="days") > "1 day" & difftime(x@stats@endtime,x@stats@starttime,units="days") < "7 days") {
    plot(x@data ~ times, type='l',main=main, xaxt="n",  xlim=c(starttime, endtime), xlab=xlab,ylab=ylab,...)
    graphics::axis.POSIXct(1, at=seq(from=x@stats@starttime, to=x@stats@endtime, by="day"), format="%b %d")

  } else {
    plot(x@data ~ times, type='l', xlim=c(starttime, endtime),main=main,xlab=xlab,ylab=ylab,...)
  }
  # title
  graphics::mtext(sensorText, line=0.2, adj=0.05)
}
setMethod("plot", signature(x="Trace"), function(x, ...) plot.Trace(x, ...))


tracePlot <- function(dataList, infoList, textList) {

  logger.info("----- tracePlot -----")
  
  # Save current par() settings
  oldPar <- par()
  #par(bg='gray95', mar=c(3,3,2,3), oma=c(5,3,4,0))

  plotCount <- length(dataList)
  logger.debug(paste("plot count",plotCount))

  if (plotCount==1) {
     st <- dataList[['dataselect_DF']]
     result <- try(plot(st),silent=TRUE)
     if ( "try-error" %in% class(result) ) {
        err_msg <- translateErrors(geterrmessage(),infoList)
        stop(err_msg, call.=FALSE)
     }

  } else {
     par(mar=c(4.1,4.1,5.1,2.1),cex=0.5,cex.main=1.8,cex.axis=1.2,cex.lab=1.5,cex.sub=1.2)
     mat <- matrix(c(seq(1,plotCount)), plotCount, 1)
     layout(mat)

     if (infoList$timeseriesScale) {
        stMax <- max(unlist(lapply(dataList,max)))
        stMin <- min(unlist(lapply(dataList,min)))
        yRange <- c(stMin,stMax)
        result <- try(lapply(dataList, function(x) plot(x,ylim=yRange)),silent=TRUE)
        if ( "try-error" %in% class(result) ) {
           err_msg <- translateErrors(geterrmessage(),infoList)
           stop(err_msg, call.=FALSE)
        }
     } else {
        result <- try(lapply(dataList,plot),silent=TRUE)
        if ( "try-error" %in% class(result) ) {
           err_msg <- translateErrors(geterrmessage(),infoList)
           stop(err_msg, call.=FALSE)
        }
     }
  }
  

  ########################################
  # Return values
  ########################################

  # Restore old par() settings
  par(oldPar)

  dataList <- list()

  return(c(1.0,2.0,3.0,4.0))

}

