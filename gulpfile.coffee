#++ general {
# npm i --save-dev gulp gulp-debug gulp-concat gulp-util gulp-cached gulp-plumber lodash
gulp = require('gulp')
debug = require('gulp-debug')
concat = require('gulp-concat')
gutil = require('gulp-util') # seems replaced with gulp-plumber
cached = require('gulp-cached') # will keep copy in memory, and stop the pipe if the copy matches (avoid needless rebuilds)
plumber = require 'gulp-plumber' # handle errors without breaking a `watch` process
plumb =
	handleError: (err)->
		console.log(err)
		@emit('end')
_ = require('lodash')
#++ }

#++ multi languages {
# npm i --save-dev gulp-uglify gulp-sourcemaps gulp-minify-css
uglify = require('gulp-uglify')
sourcemaps = require('gulp-sourcemaps')
#++ }

#++ single {
# npm i --save-dev gulp-stylus gulp-coffee gulp-template-compile gulp-react gulp-cjsx
coffee = require('gulp-coffee')
#++ }


make = {}
make.watch = (name, obj)->
	if name
		watch_name = name+'_w'
		build_watch_name = name+'_bw'
	else
		watch_name = 'watch'
		build_watch_name = 'bw'

	gulp.task watch_name, ()->
		gulp.watch obj.watch, [ name ]
	gulp.task build_watch_name, ()->
		obj.fn()
		gulp.watch obj.watch, [ name ]


#++ coffee {
###
@param	files	{
	< name >: {
			in: [< match >,...]
			out: '' < output dir >
		}
	}
###
make.coffee = (files)->
	return new ()->
		@core_fn = (files_in, files_out) ->
			gulp.src(files_in)
				.pipe(plumber(plumb))
				.pipe(cached()).pipe(debug())
				.pipe(sourcemaps.init())
				.pipe(coffee()).pipe(uglify())
				.pipe(sourcemaps.write('./')).pipe gulp.dest(files_out)


		@watch = _.map files, ((files)-> files.in)
		@watch = @watch.reduce(((prev, cur)-> prev.concat(cur) ),[])
		@fn = =>
			for name, section of files
				@core_fn section.in, section.out
		@



files =
	main:
		in: ['./src/**/*.coffee']
		out: './dist/'
made_coffee = make.coffee(files)

gulp.task 'build', made_coffee.fn
make.watch(false, made_coffee)