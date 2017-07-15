################################################################################
# pdfPlot
#

pdfPlot <- function(dataList, infoList, textList) {

  # TODO:  Remove the creation of an IrisClient in pdfPlot when the seismic
  # TODO:  package includes this in the psdPlot() method.

  # Open a connection to IRIS DMC webservices
  iris <- new("IrisClient",debug=TRUE)
  
  ########################################
  # Pull data out of list 
  ########################################
  
  st <- dataList[['dataselect_DF']]
  
  ########################################
  # Set up style
  ########################################

  ########################################
  # Plot the data
  ########################################

  psdPlot(psdList(st),style='pdf')
  
  ########################################
  # Return values
  ########################################

  return(c(1.0,2.0,3.0,4.0))

}

