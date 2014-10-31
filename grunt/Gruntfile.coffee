module.exports = (grunt) ->
  grunt.initConfig

    #Compile coffeescript files
    coffee:
      sourceMap: true
      app:
        src: [ "../coffee/**.coffee" ]
        dest: "../js/station.js"

    #Concatenate all javascript libfiles into a single slug
    #Assumes individual files are already minified (no further uglification/minification)
    concat:
      options:
        separator: ';'
        stripBanners: true
      dist:
        src: [ "../js/lib/**.js" ]
        dest: "../js/lib.js"

    # Watch relevant source files and perform tasks when they change
    watch:
      appScripts:
        files: [ "../coffee/**.coffee" ]
        tasks: [ "coffee:app" ]

      # appStyle:
      #   files: [ "./static-src/s[ac]ss/**.s[ac]ss" ]
      #   tasks: [ "sass:app" , "sass:dist"]

      libScripts:
        files: [ "../js/lib/**.js" ]
        tasks: [ "concat:dist" ]


  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-watch"
  # grunt.loadNpmTasks "grunt-contrib-uglify"
  # grunt.loadNpmTasks "grunt-contrib-sass"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.registerTask "default", ['coffee:app', 
  # 'sass:app', 'sass:dist', 'uglify:app', 
  'concat:dist']
