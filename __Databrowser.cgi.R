#!/usr/local/bin/Rscript
#
# TODO:  use configurable item instead of /usr/local/bin/Rscript
#
# Name:
#       MUSTANGDatabrowser.R
#
# Author:
#       Jonathan Callahan <jonathan@mazamascience.com>
#
# SECURITY: 1) All incoming parameter names and values are validated before being used.
# SECURITY: 2) All commands are run inside try().

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
    returnList <- list(status="ERROR", error_text=err_msg)
    returnJSON <- jsonlite::toJSON(returnList, auto_unbox=TRUE, pretty=FALSE)
    cat(paste0(contentTypeHeader("json"), returnJSON))
    quit(save="no", status=0, runLast=TRUE)
  }
}

# ----- Define success function -----------------------------------------------

stopOnSuccess <- function(rel_base, returnJSON) {
  outerReturnList <- list(status="OK", rel_base=rel_base, return_json=returnJSON)
  outerReturnJSON <- jsonlite::toJSON(outerReturnList, auto_unbox=TRUE, pretty=FALSE)
  cat(paste0(contentTypeHeader("json"), outerReturnJSON))
  quit(save="no", status=0, runLast=TRUE)
}

# ----- Set up Logging --------------------------------------------------------
result <- try({
  logger.setup(debugLog=file.path(DATABROWSER_PATH, "DEBUG.log"),
               infoLog=file.path(DATABROWSER_PATH, "INFO.log"),
               errorLog=file.path(DATABROWSER_PATH, "ERROR.log"))
}, silent=TRUE)

if ( "try-error" %in% class(result) ) {
  # NOTE:  Can't use stopOnError() at this early stage becuase we can't use logging
  err_msg <- paste0("CGI ERROR during logging setup: ", geterrmessage())
  returnList <- list(status="ERROR", error_text=err_msg)
  returnJSON <- jsonlite::toJSON(returnList, auto_unbox=TRUE, pretty=FALSE)
  cat(paste0(contentTypeHeader("json"),returnJSON))
  quit(save="no", status=0, runLast=TRUE)
}

# ----- Parse Request ---------------------------------------------------------
result <- try({
  req <- cgiRequest()
  request <- req$params
  
  # # TODO:  Change starttime override
  # request$starttime <- "2017-07-01"

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
  abs_rdata <- paste0(abs_base,'_request.RData')
  
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

if ( fromCache ) {
  
  result <- try({
    logger.debug("Retrieving %s from cache", abs_file)
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
  script <- file.path(DATABROWSER_PATH,'__DATABROWSER__.R')
  source(script)
}, silent=TRUE)
stopOnError(result, "CGI ERROR sourcing the main script: ")

result <- try({
  logger.debug("Saving %s", abs_rdata)
  save(request, file=abs_rdata)
}, silent=TRUE)
stopOnError(result, "CGI ERROR saving request as .RData: ")

# ----- Generate a new result -------------------------------------------------

result <- try({
  bop <- capture.output(returnList <- __DATABROWSER__(request))
  returnJSON <- jsonlite::toJSON(returnList, auto_unbox=TRUE, pretty=FALSE)
  cat(paste0(contentTypeHeader("json"),returnJSON,"\n"))
  quit(save="no", status=0, runLast=TRUE)
}, silent=TRUE)
stopOnError(result, "R ERROR: ")

stopOnSuccess(rel_base, returnJSON)


# JUST IN CASE:
cat(paste0(contentTypeHeader("json"),"Ran to the end of the script (which should never happen)"))

#         # END Cache management -----------------------------------------------------
#     
#     
#         # Need to generate a new plot
#         try:
#             import rpy2.robjects as robjects
#             r = robjects.r
#         except Exception, e:
#             status = 'ERROR'
#             error_text = str(e)
# 
#         elapsed = time.time() - timepoint
#         debug_text += "\n# %07.4f seconds to import the rpy module\n" % elapsed
#         timepoint = time.time()
# 
#         script = DATABROWSER_PATH + '/__DATABROWSER__.R'
# 
#         #### Create debugging output to appear in the transcript
#         ###r_commands = "\n# NOTE:  Next lines are for interactive debugging in R.\n\n"
# 
#         ###r_commands += "\nsource('" + script + "')\n\n"
#         ###r_commands += "__DATABROWSER__(jsonArgs='" + json.dumps(request) + "')\n"
# 
#         # Create debugging output to appear in the transcript
#         r_commands = "\n# NOTE:  Next lines are for interactive debugging in R.\n\n"
#         
#         r_commands += "#Switch to databrowser WD to load packages and lists\n"
#         r_commands += "savedwd <- getwd()\n"
#         r_commands += "setwd('" + DATABROWSER_PATH + "')\n"
#         r_commands += "source('" + script + "')\n\n"
# 
#         r_commands += "#Switch back to original WD and add JSON to datalist\n"
#         r_commands += "setwd(savedwd)\n"
#         r_commands += "jsonArgs='" + json.dumps(request) + "'\n"
#         r_commands += "infoList <- createInfoList(jsonArgs)\n"
#         r_commands += "infoList$scriptDir <- './R/'\n"
#         r_commands += "infoList$dataDir <- './Databrowser/data_local/'\n"
#         r_commands += "textListScript <- './R/createTextList_en.R'\n" 
#         r_commands += "infoList$outputDir <- '.'\n"
# 
# 
#         # Run the R commands using the rpy2 module 
#         try:
# 
#             # We convert the incoming request dictionary into a JSON string and
#             # pass this string to the databrowser function where it is converted
#             # into the infoList.
#             r_command = "__DATABROWSER__(jsonArgs='" + json.dumps(request) + "')"
#             
#             # The R script will always return a JSON string
#             # rpy2 will interpret this as a string vector so we need to pull out the first element
#             dir = robjects.r.dir(DATABROWSER_PATH) # Not used, would like to pass to script as arg
#             r.source(script, chdir=True)  # chdir=TRUE allows use to access package dir without RJSON
#             return_json = r(r_command)[0]
#             debug_text += "\n# return_json = ::%s::\n" % return_json
# 
#             # Profiling point
#             elapsed = time.time() - timepoint
#             debug_text += "\n# %07.4f seconds to run the R commands\n" % elapsed
#             debug_text += r_commands
#             timepoint = time.time()
# 
#             elapsed = time.time() - start
#             debug_text += "\n# %07.4f seconds from start to finish\n" % elapsed
# 
#             print(debug_text)
# 
#         except Exception, e:
#             status = 'ERROR'
#             error_text = str(e)
#             try:
#                 debug_file = DATABROWSER_PATH + "/DEBUG.txt"
#                 dbg = open(debug_file,'a')
#                 dbg.write("\n\nR ERROR on " + str(time.ctime()) + ":\n")
#                 dbg.write(error_text)
#                 dbg.write("R COMMANDS:\n" + r_commands + "\n")
#                 dbg.close()
#             except Exception, e:
#                 error_text = str(e)
#                 print("\nAn error occurred writing the debug file: " + error_text)
# 
# 
# ################################################################################
# # END generation of result. BEGIN response.
# ################################################################################
# 
# # Restore stdout
# if transcript_was_used:
#     sys.stdout.close()
#     sys.stdout=sys.__stdout__
# 
# ########################################
# # JSON response
# ########################################
# if request['responseType'] == 'json':
#     
#     # Set up the response object
#     response = {}
#     if status == 'OK':
#         if from_cache:
#             # Read the json response object if it had been stored previously so that return_json can be retrieved
#             try:
#                 f = open(abs_json,'r')
#                 response = json.loads(f.read())
#                 f.close()
#             except Exception, e:
#                 status = 'ERROR'
#                 error_text = 'CGI ERROR: cannot read cached json file: ' + str(e)
#                 response = {'status':status, 'error_text':error_text}
#         else:
#             # Otherwise, create and store the json response object
#             response = {'status':status,
#                         'rel_base':rel_base,
#                         'return_json':return_json}
#             try:
#                 f = open(abs_json,'w')
#                 f.write(json.dumps(response))
#                 f.close()
#             except:
#                 status = 'ERROR'
#                 error_text = 'CGI ERROR: cannot write json file to cache: ' + str(e)
#                 response = {'status':status, 'error_text':error_text}
#     
#     elif status == 'ERROR':
#         response = {'status':status, 'error_text':error_text }
#     
#     else:
#         response = {'status':status, 'error_text':'CGI ERROR: An unknown error occurred.' }
#     
#     # Write out the JSON response for AJAX
#     if request['debug'] == 'none':
#         sys.stdout.write("Content-type: application/json\n\n")
#         sys.stdout.write(json.dumps(response))
#     
#     # Write out the JSON response for humans
#     elif request['debug'] == 'transcript':
#         sys.stdout.write("Content-type: text/plain\n\n")
#         sys.stdout.write("TRANSCRIPT:\n")
#         sys.stdout.write(debug_text + "\n")
#         sys.stdout.write(json.dumps(response, sort_keys=True, indent=4)) # pretty
#         sys.stdout.write("\n")
#         sys.stdout.write("\nEND OF TRANSCRIPT\n")
#     
# 
# ################################################################################
# # END response. All done!
# ################################################################################
# 
# 
# # If this is being run from the command line, add another blank line
# if FS.keys() == []:
#     print("\n")
# 

