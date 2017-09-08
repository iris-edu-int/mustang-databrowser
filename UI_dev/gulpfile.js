// // BASED ON TUTORIAL AT:
// // https://travismaynard.com/writing/getting-started-with-gulp
// 
// // Include gulp
// var gulp = require('gulp'); 
// 
// // Include Our Plugins
// var jshint = require('gulp-jshint');
// var concat = require('gulp-concat');
// var uglify = require('gulp-uglify');
// var rename = require('gulp-rename');
// var replace = require('gulp-replace');
// var sass = require('gulp-sass');
// 
// var servicePath = "mazama-databrowser/dev";
// 
// // Concat and Minify JS dependencies
// gulp.task('script-dependencies', function() {
//   return gulp.src(['bower_components/angular/angular.min.js',
//       'bower_components/angular-bootstrap/ui-bootstrap.js',
//       'bower_components/angular-ui-router/release/angular-ui-router.min.js',
//       'bower_components/ng-maps/dist/ng-maps.js',
//       'bower_components/angular-slider/dist/slider.js'],
//       {base: 'bower_components/'})
//     .pipe(concat('dependencies.js'))
//     .pipe(gulp.dest('../UI/dist'))
//     .pipe(rename('dependencies.min.js'))
//     .pipe(uglify())
//     .pipe(gulp.dest('../UI/dist'));
// });
// 
// // Concat and Minify CSS dependencies
// gulp.task('css-dependencies', function() {
//   return gulp.src(['bower_components/bootstrap/dist/css/bootstrap.min.css',
//       'bower_components/angular-slider/dist/slider.css'],
//       {base: 'bower_components/'})
//     .pipe(concat('dependencies.css'))
//     .pipe(gulp.dest('../UI/dist'));
// });
// 
// // Lint Task
// gulp.task('lint', function() {
//   return gulp.src('app/js/**/*.js')
//     .pipe(jshint())
//     .pipe(jshint.reporter('default'));
// });
// 
// // Concatenate & Minify JS
// gulp.task('dev_scripts', function() {
//   return gulp.src('app/js/**/*.js')
//     // NOTE:  To run from RStudio in 'development mode', replace __SERVICE_PATH__
//     .pipe(replace("__SERVICE_PATH__", servicePath))
//     .pipe(concat('dist.js'))
//     .pipe(gulp.dest('../UI/dist'))
//     .pipe(rename('dist.min.js'))
//     .pipe(uglify())
//     .pipe(gulp.dest('../UI/dist'));
// });
// 
// // Concatenate & Minify JS
// gulp.task('scripts', function() {
//   return gulp.src('app/js/**/*.js')
//     // NOTE:  the deployed version will leave __SERVICE_PATH__ for the Makefile to replace
//     //.pipe(replace("__SERVICE_PATH__", servicePath))
//     .pipe(concat('__dist.js'))
//     .pipe(gulp.dest('../UI/dist'))
//     .pipe(rename('__dist.min.js'))
//     .pipe(uglify())
//     .pipe(gulp.dest('../UI/dist'));
// });
// 
// // Concat and Minify SCSS files
// gulp.task('css', function() {
//   return gulp.src('app/css/*.scss')
//     .pipe(concat('dist.css'))
//     .pipe(sass().on('error', sass.logError))
//     .pipe(gulp.dest('../UI/dist'));
// });
// 
// // Copy html files
// gulp.task('html', function() {
//   return gulp.src('app/html/*.html')
//     .pipe(gulp.dest('../UI'));
// });
// 
// // Copy image directoroy
// gulp.task('images', function() {
//   return gulp.src('app/images/*.*')
//     .pipe(gulp.dest('../UI/images'));
// });
// 
// // Copy __index.html file, replacing __SERVICE_PATH__
// gulp.task('dev_index', function() {
//   return gulp.src('app/__index.html')
//     // NOTE:  To run from RStudio in 'development mode', replace __SERVICE_PATH__
//     .pipe(replace("__SERVICE_PATH__", servicePath))
//     .pipe(rename('index.html'))
//     .pipe(gulp.dest('../UI'));
// });
// 
// // Copy __index.html file, replacing __SERVICE_PATH__
// gulp.task('index', function() {
//   return gulp.src('app/__index.html')
//     // NOTE:  the deployed version will leave __SERVICE_PATH__ for the Makefile to replace
//     //.pipe(replace("__SERVICE_PATH__", servicePath))
//     .pipe(rename('__index.html'))
//     .pipe(gulp.dest('../UI'));
// });
// 
// // Default Task
// gulp.task('default', ['script-dependencies', 'css-dependencies', 'lint', 'css', 'dev_scripts', 'scripts', 'html', 'images', 'dev_index', 'index']);
