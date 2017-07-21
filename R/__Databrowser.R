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

source("__DATABROWSER_PATH__/R/errorUtils.R")

# Plotting functions
source("__DATABROWSER_PATH__/R/plotUtils.R")
source("__DATABROWSER_PATH__/R/metricTimeseriesPlot.R")
source("__DATABROWSER_PATH__/R/channelSetTimeseriesPlot.R")
source("__DATABROWSER_PATH__/R/stackedMetricTimeseriesPlot.R")
source("__DATABROWSER_PATH__/R/tracePlot.R")
source("__DATABROWSER_PATH__/R/pdfPlot.R")
source("__DATABROWSER_PATH__/R/webservicePdfPlot.R")
source("__DATABROWSER_PATH__/R/networkBoxplotPlot.R")
source("__DATABROWSER_PATH__/R/networkMapPlot.R")
source("__DATABROWSER_PATH__/R/stationBoxplotPlot.R")

# Temporary metric testing scripts
source("__DATABROWSER_PATH__/R/dailyDCOffsetDevelopmentPlot.R")

# Global variables
###G_DEBUG <- TRUE

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

  ###if (G_DEBUG) cat(str(infoList))

  # ----- Read in the data ----------------------------------------------------

  result <- try( dataList <- createDataList(infoList),
                 silent=TRUE)

  # Handle error response
  if (class(result) == "try-error" ) {
    err_msg <- translateErrors(geterrmessage(),infoList)
    stop(err_msg, call.=FALSE)
  }
  
  # Extract 'bssUrl' and remove it from dataList so it doesn't interfere with plotting functions
  bssUrl <- dataList[['bssUrl']]
  dataList[['bssUrl']] <- NULL

  loadSecs <- elapsed <- ( (proc.time())[3] - timepoint )
  timepoint <- (proc.time())[3]
  ###print(paste(round(elapsed,4),"seconds to load the data"))

  ###if (G_DEBUG) cat(str(dataList))

  # ----- Create textList with language dependent strings for plot annotation --

  # NOTE:  The textList is not currently used in lower level plotting scripts
  # NOTE:  but must still exist as it is a part of many function calls.

  logger.info("----- createTextList -----")
  
  textListScript = paste('__DATABROWSER_PATH__/R/createTextList_',
                         infoList$language, '.R', sep="")
  source(textListScript)
  textList = createTextList(dataList, infoList)

  ###if (G_DEBUG) cat(str(textList))

  # ----- Create the png file --------------------------------------------------

  absPlotPDF <- paste(infoList$outputDir,infoList$outputFileBase,'.pdf',sep="")
  absPlotPNG <- paste(infoList$outputDir,infoList$outputFileBase,'.png',sep="")

  # ----- Adjust height in special cases -------------------

  logger.debug("----- adjust height in special cases -----")

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

  logger.debug("----- create appropriate plot device -----")
  
  if (infoList$plotDevice == "pdf") {

    width <- 8
    height <- width * infoList$plotHeight/infoList$plotWidth
    pdf(file=absPlotPDF, width=width, height=height, bg='white')
    print(paste("Working on",absPlotPDF))

  } else if (infoList$plotDevice == "cairo") {

    library(Cairo) # CairoPNG is part of the Cairo package
    CairoPNG(filename=absPlotPNG, 
             width=infoList$plotWidth, height=infoList$plotHeight, 
             units='px', bg='white')
    print(paste("Working on", absPlotPNG))

  } else if (infoList$plotDevice == "png") {

    png(filename=absPlotPNG, 
        width=infoList$plotWidth, height=infoList$plotHeight, 
        units='px', bg='white')
    ###print(paste("Working on",absPlotPNG))

  }


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

  } else if (infoList$plotType == 'pdf') {

    ###returnValues <- pdfPlot(dataList,infoList,textList)
    returnValues <- webservicePdfPlot(dataList,infoList,textList)

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
  ###print(paste(round(elapsed,4),"seconds to plot the data"))


  # ----- Cleanup -------------------------------------------------------------

  totalSecs <- total_elapsed <- ( (proc.time())[3] - start )
  ###print(paste("Total elapsed =",round(total_elapsed,4),"seconds"))

  if (infoList$plotDevice != '') {
    dev.off()
  }


  # ----- Convert PDF file to PNG file using ImageMagick ----------------------

  if (infoList$plotDevice == "pdf") {

    gs_cmd <- paste("gs -dSAFTER -dBATCH -dNOPAUSE -sDEVICE=png16m ",
                    "-dGraphicsAlphaBits=4 -dTextAlphaBits=4 -r300 ",
                    "-dBackgroundColor='16#ffffff' ",
                    "-sOutputFile=",absPlotPNG," ",absPlotPDF," > /dev/null",
                    sep="")
    result <- system(gs_cmd)

    # ImageMagick version of mogrify
    mogrify_cmd <- paste("mogrify -resize ", infoList$plotWidth, "x",
                         infoList$plotHeight, " ", absPlotPNG,
                         " > /dev/null", sep="")

    # GraphicsMagick version of mogrify
    #mogrify_cmd <- paste("gm mogrify -resize ", infoList$plotWidth, "x",
    #                     infoList$plotHeight, " ", absPlotPNG,
    #                     " > /dev/null", sep="")

    result <- system(mogrify_cmd)

    elapsed <- ( (proc.time())[3] - timepoint )
    timepoint <- (proc.time())[3]
    ###print(paste(round(elapsed,4),"seconds to convert PDF to PNG"))

  }


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
  # returnJSON <- toJSON(returnValues, collapse="", .escapeEscapes=FALSE)
  # 
  # return(returnJSON)

}

################################################################################
# END
################################################################################
