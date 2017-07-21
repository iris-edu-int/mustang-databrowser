################################################################################
# webservicePdfPlot
#
# Creates a PDF plot using data from the PDF web service.
#

webservicePdfPlot <- function(dataList, infoList, textList) {
  
  ########################################
  # Pull data out of list 
  ########################################
  
  pdfMatrix <- dataList[['pdfMatrix']]
  freq <- dataList[['pdfFreq']]
  power <- dataList[['pdfPower']]
  
  ########################################
  # Set up style
  ########################################

  ########################################
  # Plot the data
  ########################################

  # Choose appropriate limits for period
  period <- 1/freq
#   if (stringr::str_detect(channel,"^B")) {
#     xlim <- c(0.1,100)
#     verticalLines <- c(seq(.1,1,length.out=10),
#                        seq(1,10,length.out=10),
#                        seq(10,100,length.out=10))
#   } else {
    xlim <- c(min(period),max(period))
    verticalLines <- c(seq(.1,1,length.out=10),
                       seq(1,10,length.out=10),
                       seq(10,100,length.out=10))
#   }
  
  # Choose appropriate limits for dB
  ylo <- -200
  yhi <- -50
  ylim <- c(ylo,yhi)
  horizontalLines <- seq(ylo,yhi,10)
  
  
  # Set up colors and breaks
  cols <- c('grey90', rev(rainbow(30))[4:30])
  breaks <- c(0,seq(0.001,max(pdfMatrix),length.out=length(cols)))
  
  # NOTE:  To get image() to plot with the same axes as the data displayed as a table you
  # NOTE:  have to transpose and reverse the order of the columns.  This means we also have
  # NOTE:  to reverse the order of the X-axis locations associated with the columns.
  
  # Initial plot
  image(t(pdfMatrix)[ncol(pdfMatrix):1,],
        x=rev(period),
        y=seq(ylo,yhi),
        breaks=breaks,
        col=cols,
        las=1, log="x",
        xlab="Period (Sec)", ylab="Power dB",
        main="")
  
  # Add grid lines
  abline(h=horizontalLines, v=verticalLines, col='gray50', lty='dotted')
  
  # Add noise model lines
  NM <- noiseModels(freq)
  points(period, NM$nlnm, type='l', col='gray50', lwd=2)
  points(period, NM$nhnm, type='l', col='gray50', lwd=2)
  
  
  
  # ----- Annnotation ----------------------------------------------------------
  
  # add title and x-axis on bottom plot
  text <- paste("PDF plot for ",textList$snclName)
  title(text,line=2.5)
  title(textList$dataRange,line=0.5)
  
  
  ########################################
  # Return values
  ########################################

  return(c(1.0,2.0,3.0,4.0))

}

