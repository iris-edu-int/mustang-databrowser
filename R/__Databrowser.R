################################################################################
# __DATABROWSER__.R
#
# Author: Jonathan Callahan
################################################################################

# Required R packages
suppressPackageStartupMessages(library(seismicRoll))
suppressPackageStartupMessages(library(IRISSeismic))
suppressPackageStartupMessages(library(IRISMustangMetrics))

# Creation of textList and dataList
source("__DATABROWSER_PATH__/R/createInfoList.R")
source("__DATABROWSER_PATH__/R/createTextList_en.R")
source("__DATABROWSER_PATH__/R/createDataList.R")

# Help normalizing errors
source("__DATABROWSER_PATH__/R/translateErrors.R")

# Plotting functions
source("__DATABROWSER_PATH__/R/plotUtils.R")
source("__DATABROWSER_PATH__/R/metricTimeseriesPlot.R")
source("__DATABROWSER_PATH__/R/channelSetTimeseriesPlot.R")
source("__DATABROWSER_PATH__/R/stackedMetricTimeseriesPlot.R")
source("__DATABROWSER_PATH__/R/tracePlot.R")
source("__DATABROWSER_PATH__/R/networkBoxplotPlot.R")
###source("__DATABROWSER_PATH__/R/networkMapPlot.R")
source("__DATABROWSER_PATH__/R/stationBoxplotPlot.R")

# Temporary metric testing scripts
source("__DATABROWSER_PATH__/R/dailyDCOffsetDevelopmentPlot.R")

################################################################################
# Databrowser function

__DATABROWSER__ <- function(request) {

  logger.info("----- __DATABROWSER__ -----")
  
  start <- (proc.time())[3]
  timepoint <- (proc.time())[3]

  # ----- Create the infoList -------------------------------------------------

  infoList <- createInfoList(request)
  
  # Add directories determined from Makefile settings
  infoList$databrowserDir <- "__DATABROWSER_PATH__/"
  infoList$scriptDir <- "__DATABROWSER_PATH__/R/"
  infoList$dataDir <- "__DATABROWSER_PATH__/data/"
  infoList$outputDir <- "__DATABROWSER_PATH__/__OUTPUT_DIR__/"

  # ----- PDF plots use a web service ----------------------------------------
  
  if ( infoList$plotType == 'pdf' ) {
    
    # First create the text response for the bssUrl
    pdfServiceUrl <- 'http://service.iris.edu/mustang/noise-pdf/1/query?'
    serviceParameters <- list(network=infoList$network,
                              station=infoList$station,
                              location=infoList$location,
                              channel=infoList$channel,
                              starttime=strftime(infoList$starttime,"%Y-%m-%dT%H:%M:%S", tz="UTC"),
                              endtime=strftime(infoList$endtime,"%Y-%m-%dT%H:%M:%S", tz="UTC"),
                              quality='M',
                              format='text')
    parameterString <- paste0(names(serviceParameters),'=',as.character(serviceParameters),collapse='&')
    bssUrl <- paste0(pdfServiceUrl,parameterString)
    
    # Now create the plot url which requires some extra parameters
    serviceParameters$format='plot'
    serviceParameters$plot.interpolation='bicubic'
    serviceParameters$plot.power.min='-200'
    serviceParameters$plot.power.max='-50'
    parameterString <- paste0(names(serviceParameters),'=',as.character(serviceParameters),collapse='&')
    plotUrl <- paste0(pdfServiceUrl,parameterString)
    
    destfile <- paste0(infoList$outputDir,infoList$outputFileBase,'.png')

    result <- try( download.file(plotUrl, destfile, quiet=TRUE, method='cur', mode='wb'),
                   silent=TRUE )
    
    if ( "try-error" %in% class(result) ) {
      err_msg <- geterrmessage()
      logger.error(err_msg)
      stop(err_msg, call.=FALSE)
    }

    totalSecs <- total_elapsed <- ( (proc.time())[3] - start )
    logger.info("Total elapsed = %f seconds", round(total_elapsed,4))

    returnValues <- c(0.0,0.0,0.0,0.0) # Dummy values. returnValues is required by the UI
    
    returnList <- list(loadSecs=as.numeric(totalSecs),
                       plotSecs=as.numeric(0),
                       totalSecs=as.numeric(totalSecs),
                       returnValues=returnValues,
                       bssUrl=bssUrl)
    
    return(returnList)  
    
  }

    
  # If we made it to here, we need to generate a plot in R
  

  # ----- Read in the data ----------------------------------------------------

  result <- try( dataList <- createDataList(infoList),
                 silent=TRUE)

  # Handle error response
  if (class(result) == "try-error" ) {
    err_msg <- translateErrors(geterrmessage(),infoList)
    if ( stringr::str_detect(err_msg, "no lines available in input") ) stop("No metric values found.", call.=FALSE)
    else stop(err_msg, call.=FALSE)
  }
  
  # Extract 'bssUrl' and remove it from dataList so it doesn't interfere with plotting functions
  bssUrl <- dataList[['bssUrl']]
  dataList[['bssUrl']] <- NULL

  loadSecs <- elapsed <- ( (proc.time())[3] - timepoint )
  timepoint <- (proc.time())[3]
  logger.debug("%f seconds to load the data", round(elapsed,4))
  
  # ----- Create textList with language dependent strings for plot annotation --

  # NOTE:  The textList is not currently used in lower level plotting scripts
  # NOTE:  but must still exist as it is a part of many function calls.

  textListScript = paste('__DATABROWSER_PATH__/R/createTextList_',
                         infoList$language, '.R', sep="")
  source(textListScript)
  textList = createTextList(dataList, infoList)

  # ----- Create the png file --------------------------------------------------

  absPlotPDF <- paste(infoList$outputDir,infoList$outputFileBase,'.pdf',sep="")
  absPlotPNG <- paste(infoList$outputDir,infoList$outputFileBase,'.png',sep="")

  # ----- Adjust height in special cases -------------------

  logger.debug("adjust height in special cases")
  
  if (infoList$plotType == 'networkBoxplot' ||
      infoList$plotType == 'stationBoxplot') {    
    # heightScale is based on number of SNCLs in metric_DF
    snclq <- dataList[['metric_DF']]$snclq
    sncl <- stringr::str_replace(snclq,'..$','')      # remove last two characters
    heightScale <- 0.4 + length(unique(sncl)) * 0.04   # 40% margins for just a few stations
    heightScale <- max(0.6, heightScale)
    infoList$plotHeight <- infoList$plotWidth * heightScale
  }
  
  # ----- Create appropriate plot device -------------------

  logger.debug("creating %s", absPlotPNG)
  
  png(filename=absPlotPNG, 
      width=infoList$plotWidth, height=infoList$plotHeight, 
      units='px', bg='white')
  
  # ----- Subset the data -----------------------------------------------------


  # ----- Harmonize the data --------------------------------------------------


  # ----- Create the desired output -------------------------------------------

  returnValues <- c(0.0,0.0,0.0,0.0)

  if (infoList$plotType == 'metricTimeseries') {

    if (infoList$timeseriesChannelSet) {
      returnValues <- channelSetTimeseriesPlot(dataList, infoList, textList)
    } else {
      returnValues <- metricTimeseriesPlot(dataList, infoList, textList)
    }

  } else if (infoList$plotType == 'metricTest') {

    returnValues <- dailyDCOffsetDevelopmentPlot(dataList, infoList, textList)

  } else if (infoList$plotType == 'stackedMetricTimeseries') {

    returnValues <- stackedMetricTimeseriesPlot(dataList, infoList, textList)

  } else if (infoList$plotType == 'trace') {

    returnValues <- tracePlot(dataList,infoList,textList)

  } else if (infoList$plotType == 'networkBoxplot') {

    returnValues <- networkBoxplotPlot(dataList,infoList,textList)

  } else if (infoList$plotType == 'stationBoxplot') {

    returnValues <- stationBoxplotPlot(dataList,infoList,textList)

  } else if (infoList$plotType == 'networkMap') {

    suppressPackageStartupMessages(library(sp))    # to load world_countries dataframe from simpleMap.RData
    suppressPackageStartupMessages(library(maps))  # to overlay state boundaries
    returnValues <- networkMapPlot(dataList,infoList,textList)

  } else {
    
    stop(paste("plotType '",infoList$plotType,"' is not recognized.",sep=""), call.=FALSE)

  }

  plotSecs <- elapsed <- ( (proc.time())[3] - timepoint )
  timepoint <- (proc.time())[3]
  logger.info("%f seconds to plot the data", round(elapsed,4))


  # ----- Cleanup -------------------------------------------------------------

  totalSecs <- total_elapsed <- ( (proc.time())[3] - start )
  logger.info("Total elapsed = %f seconds", round(total_elapsed,4))

  dev.off()


  # ----- Return ---------------------------------------------------------------

  # NOTE:  An object of any type may be returned.
  # NOTE:  This object will be serialized to JSON and will be passed back to the
  # NOTE:  user interface. The javascript code in __Mazama_databrowser.js must
  # NOTE:  then interpret and use the JSON object.

  returnList <- list(loadSecs=as.numeric(loadSecs),
                     plotSecs=as.numeric(plotSecs),
                     totalSecs=as.numeric(totalSecs),
                     returnValues=returnValues,
                     bssUrl=bssUrl)

  return(returnList)  

}

################################################################################
# END
################################################################################
