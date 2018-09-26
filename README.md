# mustang-databrowser

The MUSTANG Databrowser is a web application that provides a means of plotting and viewing MUSTANG
seismic data quality metrics through the use of selector tools.  MUSTANG returns statistical 
information on the quality and character of seismic measurements captured in the IRIS data archive.
The databrowser lets the users view this information in the form of x,y point plots, box plots, and
probability density plots.

This project space is being used for the development of the next phase of the MUSTANG Databrowser,
so none of the contents here are should be assumed to in any working state, nor are these contents
supported by IRIS staff for external use.

## Installation ##

### R Packages ###

The following R packages (and automatic dependencies) must be installed system wide:

 * devtools
 * digest
 * jsonlite
 * maps
 * readr
 * sp
 * stringr
 * MazamaWebUtils ( devtools::install_github('mazamascience/MazamaWebUtils' )
 * seismicRoll
 * IRISSeismic
 * IRISMustangMetrics
 * dplyr
 * tidyr
 * png
 * utf8

### Databrowser ###

The `Makefile` in this directory controls installation of the MUSTANG Databrowser. System-configurable
settings (HTML and CGI paths, cache size, etc.) are specified in `config/Makefile_vars_SYSTEM`. 

After specifying the appropriate configuration settings, the databrowser can be installed or rebooted with:

`make reboot_clear_cache location=SYSTEM`

Log files at different log levels are available and can be seen with:

 * `make debug`
 * `make info`
 * `make error`

