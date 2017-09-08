# UI_dev #

This directory contains developer tools for building the  databrowser User Interface (UI).

It is designed to be built on the development machine, after which
the databrowser top level Makefile will copy the distribution
version of the code to the appropriate directories in the docker
image.

***

## Prerequisites ##

 * NodeJS -- http://nodejs.org
 * Bower -- http://bower.io
 * Gulp -- https://gulpjs.com

Install each of these by following the instructions at each website.

## Installing Dependency Packages ##

Set up the front end development environment in this manner:

1) Install Node dependencies (listed in package.json)

`npm install`

2) Install Bower Components (listed in bower.json)

`bower install`

You need to run the install commands because the node_modules and bower_components
directories are not written to our code repository as they are large and not required
for deployment.

## Rebuilding the UI ##

Once all dependencies have been installed you can rebuild the UI with:

`gulp`

This will perform a variety of actions, ultimately copying distribution ready files
to the appropriate directories.


***


***

## Details ##

Additional tools needed for development include the *Node.js* runtime environment
as well as the *bower* package managment system and the *gulp* build system.

 * https://nodejs.org
 * http://bower.io
 * http://gulpjs.com

As an automated build tool we are using gulp. We use gulp to perform the following
actions on our javascript code:

 * *lint* the code -- throw errors when any of the JS code has syntax errors
 * concat and minify our JS code
 * concat our CSS files
 * concat and minify all of our bower dependencies into one file
 * copy files into the deployment directory `../UI`
 
For a great tutorial on gulp, go here:
https://travismaynard.com/writing/getting-started-with-gulp


### Installing the development environment ### 

#### Node.js

Node.js and *npm*, the Node Package Manger, are required for this app's
development.  Node can be installed from https://nodejs.org/en/download/ and
npm is inclued in that installation.

#### package.json

The `package.json` file in this directory contains metadata about the databrowser
UI including dependencies on specific versions of other node packages. Running
the following command (sudo permission may be required) will install the *bower*
and *gulp* components needed for development.

  `sudo npm install`

This will create a `node_modules/` directory and install all of the dependencies
specified in packages.json.

#### bower.json

After using npm to install packages needed for development (bower and gulp), we
switch to the bower package manager for installation of components required by
the databrowser user interface. These dependencies are specified in `bower.json`.
Dependencies are installed with:

  `bower install`

This will add a `bower_components/` directory and install all of the dependencies
required by the user interface.

### Automated build with Gulp ###

The `gulp` command and `gulpfile.js` file are the equivalent of `make` and
'Makefile' on UNIX systems.  The tutorial at:
https://travismaynard.com/writing/getting-started-with-gulp
is definitely the place to learn.

After making any changes to any files in the `app/` directory, running

  `gulp --gulpfile gulpfile-test.js`
  
or 

  `gulp --gulpfile gulpfile.js`
  
will perform various tasks and place deployable files in the `../UI` directory
which is where they will be loaded from when the UI is installed.

### Debugging with Chrome ###

To debug the javascript code that runs the interface you will want to make sure
that `app/__index.html` has the following line:

  `<script src="dist/datastream.js"></script>`
  
and does not use `datastream.min.js`.
 
The *Chrome* browser has developer tools that let you  set breakpoints and walk
through the javascript code.

### Additional Reading ###

Further reading will be required to fully understand the software tools and
frameworks used to build the UI. The following links give some background on the
primary components in the development stack
*Node.js*, *bower*, *gulp*, *AngularJS*, *Bootstrap*  and *d3*. 

A Guide to the Why and How of Full-Stack JavaScript:

 * http://www.toptal.com/javascript/guide-to-full-stack-javascript-initjs

Why Use Node.js:

 * http://www.toptal.com/nodejs/why-the-hell-would-i-use-node-js

> Node.js is a platform built on Chrome's JavaScript runtime for
> easily building fast and scalable network applications. Node.js
> uses an event-driven, non-blocking I/O model that makes it
> lightweight and efficient, perfect for data-intensive real-time
> applications that run across distributed devices.

Getting Started with Bower Package Manger

 * https://www.codementor.io/bower/tutorial/beginner-tutorial-getting-started-bower-package-manager

> Web sites are made of lots of things — frameworks, libraries, assets, utilities, and
> rainbows. Bower manages all these things for you.
>
> Bower works by fetching and installing packages from all over, taking care of
> hunting, finding, downloading, and saving the stuff you’re looking for.

Introduction to Gulp.js with practical examples

 * http://julienrenaux.fr/2014/05/25/introduction-to-gulp-js-with-practical-examples/

> Gulp.js is what we call a JavaScript Task Runner, it is Open Source and 
> available on GitHub. It helps you automate repetitive tasks such as 
> minification, compilation, unit testing, linting, etc. Gulp.js does not 
> revolutionize automation but simplifies it tremendously.


***
***

