############################################################
# pdfPlot
############################################################

pdfUrl <- function(channel,infoList) {
     serviceUrl <- 'http://service.iris.edu/mustang/noise-pdf/1/query?'
     serviceParameters <- list(network=infoList$network,
                              station=infoList$station,
                              location=infoList$location,
                              channel=channel,
                              starttime=strftime(infoList$starttime,"%Y-%m-%dT%H:%M:%S", tz="UTC"),
                              endtime=strftime(infoList$endtime,"%Y-%m-%dT%H:%M:%S", tz="UTC"),
                              quality='M',
                              format='text')
     parameterString <- paste0(names(serviceParameters),'=',as.character(serviceParameters),collapse='&')
     bssUrl <- paste0(serviceUrl,parameterString)

     # Now create the plot url which requires some extra parameters
     serviceParameters$format='plot'
     serviceParameters$plot.interpolation='bicubic'
     serviceParameters$plot.power.min='-225'
     serviceParameters$plot.power.max='-50'
     serviceParameters$plot.height='475'
     serviceParameters$plot.width='600'
     parameterString <- paste0(names(serviceParameters),'=',as.character(serviceParameters),collapse='&')
     return(paste0(serviceUrl,parameterString))
}

pdfModeUrl <- function(channel,infoList) {
    serviceUrl <- 'http://service.iris.edu/mustang/noise-mode-timeseries/1/query?'
    serviceParameters <- list(network=infoList$network,
                              station=infoList$station,
                              location=infoList$location,
                              channel=channel,
                              starttime=strftime(infoList$starttime,"%Y-%m-%dT%H:%M:%S", tz="UTC"),
                              endtime=strftime(infoList$endtime,"%Y-%m-%dT%H:%M:%S", tz="UTC"),
                              quality='M',
                              format='text')
    parameterString <- paste0(names(serviceParameters),'=',as.character(serviceParameters),collapse='&')
    bssUrl <- paste0(serviceUrl,parameterString)

    # Now create the plot url which requires some extra parameters
    serviceParameters$format='plot'
    serviceParameters$plot.height='425'
    serviceParameters$plot.width='600'
    serviceParameters$output='power'
    serviceParameters$plot.power.min='-200'
    serviceParameters$plot.power.max='-50'
    serviceParameters$periods='0.1,1,6.5,10,30,100'
    serviceParameters$plot.titlefont.size='18'
    serviceParameters$plot.subtitlefont.size='16'
    serviceParameters$plot.powerlabelfont.size='16'
    serviceParameters$plot.poweraxisfont.size='14'
    serviceParameters$plot.timeaxisfont.size='14'
    serviceParameters$plot.legendfont.size='14'
    serviceParameters$plot.linewidth='1.3'
    serviceParameters$nodata='404'
    parameterString <- paste0(names(serviceParameters),'=',as.character(serviceParameters),collapse='&')
    return(paste0(serviceUrl,parameterString))
}

downloadPngs <- function(dataList,infoList) {

    destfile <- paste0(infoList$outputDir,infoList$outputFileBase,'.png')
   
    if (infoList$plotType == 'noise-mode-timeseries' ) {
        urls <- lapply(dataList,pdfModeUrl,infoList=infoList)
    } else if ( infoList$plotType == 'pdf' ) {
        urls <- lapply(dataList,pdfUrl,infoList=infoList)
    }

    n <- length(urls)
    flg <- 0
    destList <- list()

    if (n==1) {
        x <- download.file(urls[[1]], destfile,quiet=TRUE,mod='wb')
        if(file.exists(destfile)) {
          flg=flg+1
        }
    } else {           
        for ( i in 1:length(urls)) {
           url <- urls[[i]]
           destfile2 <- paste0(infoList$outputDir,i,'.png')
           destList[[i]] <- destfile2
           result <- try(x <- download.file(url,destfile2,quiet=TRUE,mod='wb'),silent=TRUE)

           if(file.exists(destfile2)) {
              flg=flg+1
           }
        } 
    }

    if(flg == 0) {
        stop("No PDF plots downloaded.")
    }

    if (infoList$plotType == 'noise-mode-timeseries' ) {
         cmd1 <- paste0("montage ",paste(destList,collapse=" ")," -geometry 600x425+0+10 -tile 1x ",destfile)
         logger.debug(cmd1);
    } else if ( infoList$plotType == 'pdf' ) {
         cmd1 <- paste("montage ",paste(destList,collapse=" ")," -geometry 600x450+0+10 -tile 1x ",destfile)
         logger.debug(cmd1);
    }

    cmd2 <- paste("rm",paste(destList,collapse=" "))
    system(cmd1)
    system(cmd2)
   
    return(unlist(urls[[1]]))
}


