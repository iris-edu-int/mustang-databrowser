# This script uses the miniCRAN package to create a local CRAN repository
# will all packages source required to build the MUSTANG Databrowser.

VERSION = "0.0.1"

library(miniCRAN)      # to create a local CRAN repository

# Create a new miniCRAN directory
if ( !file.exists("miniCRAN") ) {
  dir.create("miniCRAN")
}

pkgs <- c("IRISMustangMetrics",
          "futile.logger",           # for MazamaWebUtils
          "webutils")                # for MazamaWebUtils
repos <- c(CRAN="http://cran.microsoft.com")
Rversion <- R.version  # opportunity to override system default

# localRepo is a path in the source tree that will contain all of the package source code
localRepo <- normalizePath("./miniCRAN")

# deployedLib is a path available to the deployed mustang databrowser that will contain 
# coompiled versions of all the packages.
deployedLib <- normalizePath("./R_Libraries")


# ----- Create a miniCRAN repository ------------------------------------------

# Find all dependencies
allPackages <- pkgDep(pkg=pkgs,
                      repos=repos,
                      Rversion=Rversion,
                      suggests=FALSE)

# Createa the miniCRAN repo
pkgSource <- makeRepo(allPackages,
                      path=localRepo,
                      type="source",
                      Rversion=Rversion)

# Add MazamaWebUtils from Jon's desktop machine
addLocalPackage(pkg="MazamaWebUtils", pkgPath="~/Projects/MazamaScience", path=localRepo, build=TRUE)


# ----- Install to the deployed directory -------------------------------------

# Install with:
for ( package in allPackages ) {
  install.packages(package, lib=deployedLib, repos=paste0("file:///",localRepo), type="source")
}
