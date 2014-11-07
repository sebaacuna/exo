module.exports = (grunt) ->
  grunt.initConfig

    #Compile coffeescript files
    coffee:
      client:
        src: [ "src/**/*.coffee" ]
        dest: "build/exo.js"

    #Concatenate all javascript libfiles into a single slug
    #Assumes individual files are already minified (no further uglification/minification)
    concat:
      options:
        separator: ';'
        stripBanners: true
      lib:
        src: [ "contrib/**/*.js" ]
        dest: "build/lib.js"

    # Watch relevant source files and perform tasks when they change
    watch:
      client:
        files: [ "src/**/*.coffee" ]
        tasks: [ "coffee:client" ]

      # appStyle:
      #   files: [ "./static-src/s[ac]ss/**.s[ac]ss" ]
      #   tasks: [ "sass:app" , "sass:dist"]

      libScripts:
        files: [ "contrib/**/*.js" ]
        tasks: [ "concat:lib" ]


  grunt.loadNpmTasks "grunt-contrib-coffee"
  grunt.loadNpmTasks "grunt-contrib-watch"
  # grunt.loadNpmTasks "grunt-contrib-uglify"
  # grunt.loadNpmTasks "grunt-contrib-sass"
  grunt.loadNpmTasks "grunt-contrib-concat"
  grunt.registerTask "default", ['coffee:client', 
  # 'sass:app', 'sass:dist', 'uglify:app', 
  'concat:lib']
