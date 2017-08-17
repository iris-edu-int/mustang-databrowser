#!/usr/local/bin/Rscript
#
# TODO:  use configurable item instead of /usr/local/bin/Rscript
#
# Name:
#       MUSTANGDatabrowser.cgi.R
#
# Author:
#       Jonathan Callahan <jonathan@mazamascience.com>
#

library(methods)              # always included for Rscripts
library(MazamaWebUtils)       # logging, cache management and cgi support

# Specficic packages and scripts for this service -----------------------------

# Specify global (configurable) variables -------------------------------------

VERSION <- "1.0.0"

# Variables configured with config/Makefile_vars_~
URL_PATH <- '__URL_PATH__'
DATABROWSER_PATH <- '__DATABROWSER_PATH__'
OUTPUT_DIR <- '__OUTPUT_DIR__'
CACHE_SIZE <- as.numeric('__CACHE_SIZE__')

# Directories
URL_OUT <- file.path(URL_PATH, OUTPUT_DIR)
ABS_OUT <- file.path(DATABROWSER_PATH, OUTPUT_DIR)

# Silence warning messages
options(warn=-1) # -1=ignore, 0=save/print, 1=print, 2=error

# ----- Define finalizer function ---------------------------------------------

.Last <- function() {
  graphics.off() # close devices before printing
  cat("\n")
}

# ----- Define error function -------------------------------------------------

stopOnError <- function(result, errorPrefix="", useErrorMessage=TRUE, contentType="json") {
  if ( "try-error" %in% class(result) ) {
    err_msg <- ifelse(useErrorMessage, paste0(errorPrefix, geterrmessage()), errorPrefix)
    logger.error(err_msg)
    # NOTE:  The UI uses the modal alert() alert function to displaly error messages >80
    # NOTE:  characters long. To avoid this modal UI we simply truncate at this point.
    if ( stringr::str_count(err_msg) > 80 ) {
      err_msg <- paste0(stringr::str_sub(err_msg,1,76),'...')
    }
    returnList <- list(status="ERROR", error_text=err_msg)
    returnJSON <- jsonlite::toJSON(returnList, auto_unbox=TRUE, pretty=FALSE)
    cat(paste0(httpResponse.header("json"), returnJSON))
    quit(save="no", status=0, runLast=TRUE)
  }
}

# ----- Define success function -----------------------------------------------

stopOnSuccess <- function(rel_base, returnJSON) {
  outerReturnList <- list(status="OK", rel_base=rel_base, return_json=returnJSON)
  outerReturnJSON <- jsonlite::toJSON(outerReturnList, auto_unbox=TRUE, pretty=FALSE)
  logger.info("returnJSON = %s", outerReturnJSON)
  cat(paste0(httpResponse.header("json"), outerReturnJSON))
  quit(save="no", status=0, runLast=TRUE)
}

# ----- Set up Logging --------------------------------------------------------
result <- try({
  # Set up logging
  debugFilePath <- file.path(DATABROWSER_PATH, "DEBUG.log")
  infoFilePath <- file.path(DATABROWSER_PATH, "INFO.log")
  errorFilePath <- file.path(DATABROWSER_PATH, "ERROR.log")
  # Start with a new DEBUG log every time
  dummy <- file.create(debugFilePath, showWarnings=FALSE)
  logger.setup(debugLog=debugFilePath,
               infoLog=infoFilePath,
               errorLog=errorFilePath)
}, silent=TRUE)

if ( "try-error" %in% class(result) ) {
  # NOTE:  Can't use stopOnError() at this early stage becuase we can't use logging
  err_msg <- paste0("CGI ERROR during logging setup: ", geterrmessage())
  returnList <- list(status="ERROR", error_text=err_msg)
  returnJSON <- jsonlite::toJSON(returnList, auto_unbox=TRUE, pretty=FALSE)
  cat(paste0(httpResponse.header("json"),returnJSON))
  quit(save="no", status=0, runLast=TRUE)
}

# ----- Parse Request ---------------------------------------------------------
result <- try({
  
  # NOTE:  So that we can debug from RStudio by defining "debugArgs" or at the command line by passing an argument.
  # NOTE:  Either debugArgs or the first argument should be the path of the request JSON copied form the log file.
  if ( exists("debugArgs") ) {
    args <- debugArgs
  } else {
    args = commandArgs(trailingOnly=TRUE)
  }
  
  # Get request from command CGI environment or command line argument
  if ( length(args) == 0 ) {
    req <- cgiRequest()
    request <- req$params
  } else {
    # Must be a json formatted file with request parameters
    requestJSON <- paste0(readr::read_lines(args[1]), collapse='')
    request <- jsonlite::fromJSON(requestJSON)
  }

  # Defaults
  request$responseType <- ifelse(is.null(request$responseType), 'json', request$responseType)
  
  # Create uniqueID from the request
  uniqueID <- digest::digest(request, algo="md5")
  
  # Set up filenames to be used
  abs_base <- paste0(ABS_OUT,'/',uniqueID)
  rel_base <- paste0(OUTPUT_DIR,'/',uniqueID)
  abs_png <- paste0(abs_base,'.png')
  abs_json <- paste0(abs_base,'.json')
  abs_file <- paste0(abs_base,'.',request$responseType)
  abs_requestJSON <- paste0(abs_base,'_request.json')
  
  # modify the request
  request$outputFileBase <- uniqueID
  
  logger.debug("Environment:\n%s", paste(capture.output(print(Sys.getenv())),collapse="\n"))
  logger.info("Request parameters:\n%s", paste(capture.output(str(request)),collapse="\n"))
}, silent=TRUE)

stopOnError(result, "CGI ERROR during request parsing: ")

# ----- Manage Cache ----------------------------------------------------------
if ( request$responseType == 'json' ) {
  fromCache <- file.exists(abs_png) && file.exists(abs_json)
} else {
  fromCache <- file.exists(abs_file)
}

# NOTE:  Bypass the cache if we're debugging
if ( length(args) > 0 ) fromCache <- FALSE

if ( fromCache ) {
  
  result <- try({
    logger.info("Retrieving %s from cache", abs_file)
    lines <- readr::read_lines(abs_file)
    returnJSON <- paste0(lines, collapse='\n')
    stopOnSuccess(rel_base, returnJSON)
  }, silent=TRUE)
  stopOnError(result, "CGI ERROR reading cached json file: ")
  
} else {
  
  result <- try({
    deletedCount <- manageCache(OUTPUT_DIR, extensions=c("json","png","RData"), maxCacheSize=CACHE_SIZE)
    logger.debug("Removed %d files from cache to keep the size at %d MB", deletedCount, CACHE_SIZE)
  }, silent=TRUE)
  stopOnError(result, "CGI ERROR deleting files from cache: ")
  
}

# NOTE:  If we get this far, we need to generate a new result

result <- try({
  logger.debug("Saving %s", abs_requestJSON)
  requestJSON <- jsonlite::toJSON(request, auto_unbox=TRUE, pretty=TRUE)
  readr::write_lines(as.character(requestJSON), path=abs_requestJSON)
}, silent=TRUE)
stopOnError(result, "CGI ERROR saving request as .json: ")

result <- try({
  script <- file.path(DATABROWSER_PATH,'__DATABROWSER__.R')
  source(script)
}, silent=TRUE)
stopOnError(result, "CGI ERROR sourcing the main script: ")

# ----- Generate a new result -------------------------------------------------

result <- try({
  returnList <- __DATABROWSER__(request)
  returnJSON <- jsonlite::toJSON(returnList, auto_unbox=TRUE, pretty=FALSE)
}, silent=TRUE)
stopOnError(result, "R ERROR: ")

result <- try({
  logger.debug("Saving %s", abs_json)
  readr::write_lines(as.character(returnJSON), path=abs_json)
}, silent=TRUE)
stopOnError(result, "CGI ERROR saving returnJSON")

stopOnSuccess(rel_base, returnJSON)


# ----- THE END ---------------------------------------------------------------

