################################################################################
# The packages/ directory contains source code for packages used by a databrowser.
# These packages can be installed locally with the databrowser to avoid conflict
# with other R code that may depend upon different versions of the packages.
#
# Invoke this Makefile with a specific libPath argument:
#   make install libPath=__LIBRARY_PATH__
#
# NOTE:  If you see "ERROR:  'configure' exists but is not executable" you will
# NOTE:  need the following extra steps.
# NOTE:  (see http://mazamascience.com/WorkingWithData/?p=1185)
# NOTE:
# NOTE:  mkdir ~/tmp
# NOTE:  make install libPath=__LIBRARY_PATH__ TMPDIR=~/tmp

################################################################################
# Targets 

#BH_1.62.0-1.tar.gz
#IRISMustangMetrics_2.0.8.tar.gz
#IRISSeismic_1.4.6.tar.gz
#MASS_7.3-47.tar.gz
#Makefile
#MazamaWebUtils_0.1.2.tar.gz
#PACKAGES.gz
#R6_2.2.2.tar.gz
#RCurl_1.95-4.8.tar.gz
#Rcpp_0.12.12.tar.gz
#XML_3.98-1.9.tar.gz
#assertthat_0.2.0.tar.gz
#bindr_0.1.tar.gz
#bindrcpp_0.2.tar.gz
#bitops_1.0-6.tar.gz
#curl_2.8.1.tar.gz
#dplyr_0.7.2.tar.gz
#futile.logger_1.4.3.tar.gz
#futile.options_1.0.0.tar.gz
#glue_1.1.1.tar.gz
#jsonlite_1.5.tar.gz
#lambda.r_1.1.9.tar.gz
#magrittr_1.5.tar.gz
#pkgconfig_2.0.1.tar.gz
#plogr_0.1-1.tar.gz
#pracma_2.0.7.tar.gz
#quadprog_1.5-5.tar.gz
#rlang_0.1.2.tar.gz
#seismicRoll_1.1.2.tar.gz
#signal_0.7-6.tar.gz
#stringi_1.1.5.tar.gz
#stringr_1.2.0.tar.gz
#tibble_1.3.3.tar.gz
#webutils_0.6.tar.gz


# NOTE:  Installation must occur in dependency order
install: core_packages dplyr_packages rvest_packages Mazama_packages rmarkdown_packages

# Core packages needed by every databrowser
core_packages: digest jsonlite stringr

digest: 
	test -d $(libPath)/digest || R CMD INSTALL --library=$(libPath) digest_0.6.8.tar.gz # independent

jsonlite:
	test -d $(libPath)/jsonlite || R CMD INSTALL --library=$(libPath) jsonlite_0.9.14.tar.gz # independent

stringr:
	test -d $(libPath)/stringr || R CMD INSTALL --library=$(libPath) stringr_0.6.2.tar.gz # independent


# Packages required by 'dplyr'
dplyr_packages: assertthat BH DBI lazyeval magrittr Rcpp R6 dplyr

assertthat:
	test -d $(libPath)/assertthat || R CMD INSTALL --library=$(libPath) assertthat_0.1.tar.gz # independent

BH:
	test -d $(libPath)/BH || R CMD INSTALL --library=$(libPath) BH_1.55.0-3.tar.gz # independent

DBI:
	test -d $(libPath)/DBI || R CMD INSTALL --library=$(libPath) DBI_0.3.1.tar.gz # independent

lazyeval:
	test -d $(libPath)/lazyeval || R CMD INSTALL --library=$(libPath) lazyeval_0.1.10.tar.gz # independent

magrittr:
	test -d $(libPath)/magrittr || R CMD INSTALL --library=$(libPath) magrittr_1.5.tar.gz # independent

Rcpp:
	test -d $(libPath)/Rcpp || R CMD INSTALL --library=$(libPath) Rcpp_0.11.5.tar.gz # independent

R6:
	test -d $(libPath)/R6 || R CMD INSTALL --library=$(libPath) R6_2.0.1.tar.gz # independent

dplyr:
	test -d $(libPath)/dplyr || R CMD INSTALL --library=$(libPath) dplyr_0.4.1.tar.gz


# Packages required by 'rvest'
rvest_packages: bitops mime XML RCurl httr selectr rvest

bitops:
	###test -d $(libPath)/bitops || R CMD INSTALL --library=$(libPath) bitops_1.0-6.tar.gz # independent

mime:
	###test -d $(libPath)/mime || R CMD INSTALL --library=$(libPath) mime_0.2.tar.gz # independent

RCurl:
	###test -d $(libPath)/RCurl || R CMD INSTALL --library=$(libPath) RCurl_1.95-4.5.tar.gz

XML:
	###test -d $(libPath)/XML || R CMD INSTALL --library=$(libPath) XML_3.98-1.1.tar.gz

httr:
	test -d $(libPath)/httr || R CMD INSTALL --library=$(libPath) httr_0.6.1.tar.gz

selectr:
	test -d $(libPath)/selectr || R CMD INSTALL --library=$(libPath) selectr_0.2-3.tar.gz

rvest:
	test -d $(libPath)/rvest || R CMD INSTALL --library=$(libPath) rvest_0.2.0.tar.gz


# Packages required by 'rmarkdown'
rmarkdown_packages: caTools htmltools yaml evaluate formatR highr markdown knitr rmarkdown htmlTable

caTools:
	test -d $(libPath)/caTools || R CMD INSTALL --library=$(libPath) caTools_1.17.1.tar.gz # imports 'bitops'

htmltools:
	test -d $(libPath)/htmltools || R CMD INSTALL --library=$(libPath) htmltools_0.2.6.tar.gz # imports 'digest'

yaml:
	test -d $(libPath)/yaml || R CMD INSTALL --library=$(libPath) yaml_2.1.13.tar.gz # independent

evaluate:
	test -d $(libPath)/evaluate || R CMD INSTALL --library=$(libPath) evaluate_0.5.5.tar.gz # imports 'stringr'

formatR:
	test -d $(libPath)/formatR || R CMD INSTALL --library=$(libPath) formatR_1.0.tar.gz # independent

highr:
	test -d $(libPath)/highr || R CMD INSTALL --library=$(libPath) highr_0.4.tar.gz # independent

markdown:
	test -d $(libPath)/markdown || R CMD INSTALL --library=$(libPath) markdown_0.7.4.tar.gz # imports 'mime'

knitr:
	test -d $(libPath)/knitr || R CMD INSTALL --library=$(libPath) knitr_1.9.tar.gz

rmarkdown:
	test -d $(libPath)/rmarkdown || R CMD INSTALL --library=$(libPath) rmarkdown_0.5.1.tar.gz

htmlTable:
	test -d $(libPath)/htmlTable || R CMD INSTALL --library=$(libPath) htmlTable_1.3.tar.gz


# Packages required by 'BlueSkyUtils

Mazama_packages: MazamaSpatialUtils ncdf4 BlueSkyUtils

MazamaSpatialUtils:
	# MazamaSpatialUtils imports: dplyr, rgdal, rgeos, rvest, sp, stringr
	# NOTE:  assume that rgdal, rgeos and sp are already installed
	###test -d $(libPath)/MazamaSpatialUtils || R CMD INSTALL --library=$(libPath) MazamaSpatialUtils_0.2.3.tar.gz

ncdf4:
	###test -d $(libPath)/ncdf4 || R CMD INSTALL --library=$(libPath) ncdf4_1.13.tar.gz

BlueSkyUtils:
	###test -d $(libPath)/BlueSkyUtils || R CMD INSTALL --library=$(libPath) BlueSkyUtils_0.2.0.tar.gz


