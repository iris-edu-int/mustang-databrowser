#!/usr/bin/env Rscript

# This script uses the miniCRAN package to create a local CRAN repository
# will all packages source required to build the MUSTANG Databrowser.

VERSION = "0.0.1"

library(methods)       # always included for Rscripts
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

# Find all dependencies
allPackages <- pkgDep(pkg=pkgs,
                      repos=repos,
                      Rversion=Rversion,
                      suggests=FALSE)

# Createa the miniCRAN repo
pkgSource <- makeRepo(allPackages,
                      path="./miniCRAN",
                      type="source",
                      Rversion=Rversion)

# Add MazamaWebUtils
addLocalPackage(pkg="MazamaWebUtils", pkgPath="~/Projects/MazamaScience", path="./miniCRAN", build=TRUE)
