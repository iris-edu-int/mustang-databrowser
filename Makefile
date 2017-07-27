################################################################################
# Makefile for a Mazama Science Databrowser.
#
# Jonathan Callahan @ mazamascience.com
#
# July 2014

# The following make variables are defined in Makefile_vars.mk:
 
# Server specific locations
#
# SERVER                      -- DNS name of the server
# OWNERSHIP                   -- argument to chown, allows web server to create files
# CGI_PATH                    -- absolute path of the CGI directory
# DATABROWSER_PATH            -- absolute path of the databrowser directory
# DATABROWSER                 -- name of databrowser
# DATA_DIR                    -- name of subdirectory containing data accessed by the databrowser (will be soft linked --> data/)
# OUTPUT_DIR                  -- name of subdirectory containing databrowser products
# CACHE_SIZE                  -- size of cache in megabytes
#
# PYTHON_SED_SCRIPT           -- sed script for the location of Python
# URL_PATH_SED_SCRIPT         -- sed script for full databrowser URLs
# DATABROWSER_PATH_SED_SCRIPT -- sed script for full databrowser path
# OUTPUT_DIR_SED_SCRIPT       -- sed script for the output directory
# ATTRIBUTION_SED_SCRIPT      -- sed script for the text at the bottom of plots
# DATABROWSER_SED_SCRIPT      -- sed script for the databrowser name
# CACHE_SIZE_SED_SCRIPT       -- sed script for the cache size


################################################################################
# Invoke this Makefile with a specific location argument:
#   make install location=test
#   -OR-
#   make install location=production 
#   -OR-
#   make install location=osx10 
# 
# The config/Makefile_vars_~ file associated with the location must exist.

include config/Makefile_vars_$(location)


################################################################################
# Targets related to databrowser installation

###install: install_UI install_data install_cache install_packages
install: install_UI install_data install_cache


reboot: install_UI install_data


reboot_clear_cache: install_UI install_data clear_cache


install_UI: FORCE
	# copy files and directories into installation directory
	mkdir -p $(DATABROWSER_PATH)
	cp html/*.html $(DATABROWSER_PATH)
	cp -r R style images $(DATABROWSER_PATH)
	rm -rf $(DATABROWSER_PATH)/R/packages
	# remove subversion directories
	-find $(DATABROWSER_PATH) -depth -name .svn -exec rm -rf {} \;
	# configure __Databrowser.R
	sed $(DATABROWSER_PATH_SED_SCRIPT) R/__Databrowser.R | \
		sed $(OUTPUT_DIR_SED_SCRIPT) | \
                sed $(DATABROWSER_SED_SCRIPT) | \
                sed $(ATTRIBUTION_SED_SCRIPT) > $(DATABROWSER_PATH)/$(DATABROWSER).R
	rm $(DATABROWSER_PATH)/R/__Databrowser.R
	cp $(DATABROWSER_PATH)/$(DATABROWSER).R ./DEBUG_$(DATABROWSER).R
	# configure __MUSTANGDatabrowser.cgi.R
	sed $(PYTHON_SED_SCRIPT) __Databrowser.cgi.R | \
		sed $(URL_PATH_SED_SCRIPT) | \
		sed $(DATABROWSER_PATH_SED_SCRIPT) | \
                sed $(OUTPUT_DIR_SED_SCRIPT) | \
                sed $(DATABROWSER_SED_SCRIPT) | \
                sed $(CACHE_SIZE_SED_SCRIPT) >  $(CGI_PATH)/$(DATABROWSER).cgi
	-chown $(OWNERSHIP) $(CGI_PATH)/$(DATABROWSER).cgi
	-chmod 755 $(CGI_PATH)/$(DATABROWSER).cgi
	cp $(CGI_PATH)/$(DATABROWSER).cgi ./DEBUG_$(DATABROWSER).cgi.R
	# copy in javascript files
	cp -r behavior $(DATABROWSER_PATH)
	sed $(DATABROWSER_SED_SCRIPT) behavior/__Mazama_databrowser.js > $(DATABROWSER_PATH)/behavior/Mazama_databrowser.js
	rm $(DATABROWSER_PATH)/behavior/__*
	# make debugging files
	touch $(DATABROWSER_PATH)/ERROR.log
	touch $(DATABROWSER_PATH)/INFO.log
	touch $(DATABROWSER_PATH)/DEBUG.log
	-chown $(OWNERSHIP) $(DATABROWSER_PATH)/*.log
	-chmod 666 $(DATABROWSER_PATH)/*.log


install_data: FORCE
	# copy in all dierctories and contents
	cp -r data_local $(DATABROWSER_PATH) 
	# soft link installed 'data' directory
	ln -fs $(DATA_DIR) $(DATABROWSER_PATH)/data
	# remove subversion directories
	-find $(DATABROWSER_PATH) -depth -name .svn -exec rm -rf {} \;


uninstall: FORCE
	rm -f $(CGI_PATH)/$(DATABROWSER).cgi
	rm -rf $(DATABROWSER_PATH)


################################################################################
# Targets related to the output cache

install_cache: FORCE
	cp -r output* $(DATABROWSER_PATH)
	-chown -R $(OWNERSHIP) $(DATABROWSER_PATH)/output*
	-chmod 777 $(DATABROWSER_PATH)/output*
	# remove subversion directories
	-find $(DATABROWSER_PATH) -depth -name .svn -exec rm -rf {} \;


uninstall_cache: FORCE
	rm -rf $(DATABROWSER_PATH)/output*


clear_cache: FORCE
	rm -f $(DATABROWSER_PATH)/output*/*


################################################################################
# Targets related to locally installed packages

install_packages: FORCE
	mkdir $(DATABROWSER_PATH)/R/library
	cd R/packages; make install libPath=$(DATABROWSER_PATH)/R/library

uninstall_packages: FORCE
	rm -rf $(DATABROWSER_PATH)/R/library


################################################################################
# Targets related to log files

debug: FORCE
	cat $(DATABROWSER_PATH)/DEBUG.log

info: FORCE
	cat $(DATABROWSER_PATH)/INFO.log

error: FORCE
	cat $(DATABROWSER_PATH)/ERROR.log

clear_logs: FORCE
	rm -f $(DATABROWSER_PATH)/*.log
	touch $(DATABROWSER_PATH)/ERROR.log
	touch $(DATABROWSER_PATH)/INFO.log
	touch $(DATABROWSER_PATH)/DEBUG.log
	-chown $(OWNERSHIP) $(DATABROWSER_PATH)/*.log
	-chmod 666 $(DATABROWSER_PATH)/*.log

################################################################################
# Targets for creating the distribution tarball

dist: FORCE
	cd ..; tar -czf $(DATABROWSER).tgz --exclude=.svn $(DATABROWSER)

dist_from_svn: FORCE
	cd ..; tar -czf GenericDatabrowser.tgz --exclude=.svn --exclude=.R* GenericDatabrowser


FORCE:
