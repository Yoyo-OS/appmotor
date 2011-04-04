#!/usr/bin/ruby
# Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
# All rights reserved.
# Contact: Nokia Corporation (directui@nokia.com)
#
# This file is part of applauncherd.
#
# If you have questions regarding the use of this file, please contact
# Nokia at directui@nokia.com.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation
# and appearing in the file LICENSE.LGPL included in the packaging
# of this file.
#
#  * Description: Performance Test for applauncherd 
#   
#  * Objectives: test the startup time for applications
#    

#require 'tdriver'
require 'date'
require 'test/unit'
require 'optparse'

class TC_PerformanceTests < Test::Unit::TestCase
  COUNT = 3
  PIXELCHANGED_BINARY= '/usr/bin/fala_pixelchanged' 
  TEST_SCRIPT_LOCATION = '/usr/share/applauncherd-testscripts'
  GET_COORDINATES_SCRIPT="#{TEST_SCRIPT_LOCATION}/get-coordinates.rb"
  PIXELCHANGED_LOG = '/tmp/fala_pixelchanged.log'
  FALA_GETTIME_BINARY = '/usr/bin/fala_gettime_ms'
  MATTI_LOCATION='/usr/lib/qt4/plugins/testability/libtestability.so'
  TEMPORARY_MATTI_LOCATION='/root/libtestability.so'
  

  @start_time = 0
  @end_time = 0
  @app_from_cache = 0
  @win_from_cache = 0
  @pos = 0
  @options = {}  
  

  $path = string = `echo $PATH `
  def print_debug(msg)
    message = "[INFO]  #{msg}\n"
    puts message
  end

  
  # method called before any test case
  def setup

    optparse = OptionParser.new do|opts|
      options = {}  
      # Set a banner, displayed at the top
      # of the help screen.
      opts.banner = "Usage: get-coordinates.rb [options] "
      
      options[:application] = nil
      opts.on( '-a', '--application APP', 'Application name in application grid' ) do|app|
        options[:application] = app
      end

      options[:binary] = nil
      opts.on( '-b', '--binary BINARY', 'Name of the application binary which is used when killing the application' ) do|binary|
        options[:binary] = binary
      end

      options[:command] = nil
      opts.on( '-c', '--command_line COMMAND', 'Start application from witc COMMAND from command line instead of grid.' ) do|command|
        options[:command] = command
      end

      options[:startup] = nil
      opts.on( '-s', '--startup MILLISECONDS', 'Time limit in milliseconds. Slower startup will make test to fail.' ) do|milliseconds|
        options[:startup] = milliseconds.to_i
        print_debug("The Startup limit is : #{options[:startup]}")
      end

      options[:appCache] = nil
      opts.on( '-t', '--appCache MILLISECONDS', 'Time limit in milliseconds for application from cache.' ) do|milliseconds|
        options[:appCache] = milliseconds.to_i
        print_debug("The limit for MApplication from cache is : #{options[:appCache]}")
      end

      options[:winCache] = nil
      opts.on( '-w', '--winCache MILLISECONDS', 'Time limit in milliseconds for window from cache.' ) do|milliseconds|
        options[:winCache] = milliseconds.to_i
        print_debug("The limit for MApplicationWindow from cache is : #{options[:winCache]}")
      end

      options[:logFile] = nil
      opts.on( '-f', '--logFile LOG_FILE', 'Log file which stores the timestamps' ) do|logFile|
        options[:logFile] = logFile
      end
      
      options[:pre_step] = nil
      opts.on( '-p', '--pre_step PRE_STEP', 'Command to be executed everytime before starting the application' ) do|pre_step|
        options[:pre_step] = pre_step
      end

      opts.on( '-h', '--help', 'Display this screen' ) do
        puts opts
        exit 0
      end
      @options=options
    end

    optparse.parse!

    if @options[:application] == nil &&  @options[:command] == nil
      print_debug ("Application not defined!")
      exit 1
    end

    if @options[:binary] == nil
      print_debug ("Binary of the application not defined!")
      exit 1
    end

    if @options[:logFile] != nil
      print_debug ("The logFile is: #{@options[:logFile]}")
    end

    if @options[:command] != nil
      print_debug ("The command to launch is #{@options[:command]}")
    end

    if @options[:pre_step] != nil
      print_debug ("The Pre-steps is :#{@options[:pre_step]}" )
    end

    if $path.include?("scratchbox")
      print_debug ("Inside SB, Do Nothing to unlock")
    else
      print_debug("Unlocking device")
      system "mcetool --set-tklock-mode=unlocked"
      system "mcetool --set-inhibit-mode=stay-on"
    end        

    print_debug("restart mthome")
    system("initctl restart xsession/mthome")

    print_debug("move #{MATTI_LOCATION} to #{TEMPORARY_MATTI_LOCATION}")
    system "mv #{MATTI_LOCATION} #{TEMPORARY_MATTI_LOCATION}"

    print_debug("restart applauncherd")
    system("initctl restart xsession/applauncherd")
    sleep(10)
  end
  

  
  # method called after any test case for cleanup purposes
  def teardown
    print_debug ("exit from teardown")
    print_debug("move #{TEMPORARY_MATTI_LOCATION} to #{MATTI_LOCATION}")
    system "mv #{TEMPORARY_MATTI_LOCATION} #{MATTI_LOCATION}"

    if @options[:application] != nil     
      print_debug("restart mthome")
      system("initctl restart xsession/mthome")
      sleep(10)
    end
  end
  


  def open_Apps(appName)
    # Remove the log files if they exist
    if FileTest.exists?(PIXELCHANGED_LOG)
      print_debug("remove #{PIXELCHANGED_LOG}")
      system "rm #{PIXELCHANGED_LOG}"
    end

    if FileTest.exists?(@options[:logFile])
      print_debug("remove #{@options[:logFile]}")
      system "rm #{@options[:logFile]}"
    end

    # Kill the binary if alive
    print_debug("Kill #{@options[:binary]}")
    system "pkill #{@options[:binary]}"
    sleep(2)

    # execute the optional command if available
    if @options[:pre_step] != nil 
      print_debug ("pre_step: #{@options[:pre_step]}")
      system "#{@options[:pre_step]}"
    end

    if @options[:command] != nil
      # Check that the average system load is under 0.3
      print_debug("Check the avarage system load is under 0.3")
      system "/usr/bin/waitloadavg.rb -l 0.3 -p 1.0 -t 100 -d"

      start_command ="`#{PIXELCHANGED_BINARY} -t 20x20 -t 840x466 -q >> #{PIXELCHANGED_LOG} &`; #{FALA_GETTIME_BINARY} \"Started from command line\" >>  #{PIXELCHANGED_LOG}; #{@options[:command]} &"
      print_debug ("start command: #{start_command}")
      system start_command

      sleep (4)
    else
      @pos = `#{GET_COORDINATES_SCRIPT} -a #{@options[:application]}`
      @pos = @pos.split("\n")[-1]
      print_debug ("Co-ordinates: #{@pos}")
      
      print_debug("Check the avarage system load is under 0.3")
      system "/usr/bin/waitloadavg.rb -l 0.3 -p 1.0 -t 50 -d"

      cmd = "#{PIXELCHANGED_BINARY} -c #{@pos} -t 20x20 -t 840x466 -f #{PIXELCHANGED_LOG} -q"
      print_debug("pixel changed command is : #{cmd}")
      system cmd

      sleep (4)

      # Raise meegotouchhome to the top.
      #Workaround for keeping the window stack in shape.
      print_debug("#{GET_COORDINATES_SCRIPT} -g")
      system "#{GET_COORDINATES_SCRIPT} -g"
    end

    print_debug("pkill :#{@options[:binary]}")
    system "pkill #{@options[:binary]}"
  end
  


  def read_file(appName)
    def get_matching_lines(lines, re)
      # return a list of lines that match re
      lines.collect { |x| if x[1] =~ re; x; else; nil; end }.compact
    end

    # read times from pixelchanged log
    lines = File.open(PIXELCHANGED_LOG).readlines().collect { |x| x.split()[0].to_i }

    # read stuff from application log, split lines to 2 parts
    lines_app = File.open(@options[:logFile]).readlines().collect { |x| x.split(nil, 2) }

    app_cache_lines = get_matching_lines(lines_app, /app from cache/)
    win_cache_lines = get_matching_lines(lines_app, /win from cache/)

    # check app cache time only if timeout specified
    if @options[:appCache] != nil
      assert(app_cache_lines.size > 0, "No 'app from cache' line found from logs!")

      @app_from_cache = app_cache_lines[0][0].to_i - lines_app[0][0].to_i

      print_debug("app from cache #{@app_from_cache}")
    end

    # check win cache time only if timeout specified (this needs the app cache line too)
    if @options[:winCache] != nil
      assert(app_cache_lines.size > 0, "no 'app from cache' line found from logs!")
      assert(win_cache_lines.size > 0, "no 'win from cache' line found from logs!")

      @win_from_cache = win_cache_lines[0][0].to_i - app_cache_lines[0][0].to_i

      print_debug("win from cache #{@win_from_cache}")
    end

    # when the button was released
    @start_time = lines[0]

    # when the first pixel was changed
    @end_time = lines[1]

    print_debug("started at: #{@start_time}")
    print_debug("pixel changed: #{@end_time}")
  end
  
  

  def test_performance
    start_time_sum = 0
    app_cache_sum = 0
    win_cache_sum = 0 

    # run application and measure the times
    for i in 1..COUNT
      print_debug ("Now Launching  #{@options[:application]} #{i} times" )

      print_debug("Kill #{PIXELCHANGED_BINARY} if any before launching ")
      system("pkill #{PIXELCHANGED_BINARY}")

      open_Apps(@options[:application])

      sleep (5)

      read_file(@options[:application])
      
      if @options[:appCache] != nil
        app_cache_sum += @app_from_cache
      end

      if @options[:winCache] != nil
        win_cache_sum += @win_from_cache
      end

      start_time_sum += @end_time - @start_time
    end
    
    print_debug ("Startup time in milliseconds\n")
    print_debug ("Application: #{@options[:application]} \n")
    
    print_debug ("Average Startup : #{start_time_sum/COUNT}")

    print_debug("MApplication from cache: #{app_cache_sum/COUNT}") if @options[:appCache] != nil
    print_debug("MApplicationWindow from cache #{win_cache_sum/COUNT}") if @options[:winCache] != nil

    if @options[:startup] != nil
      print_debug("Check that startup time is less than #{@options[:startup]} ms")
      assert((start_time_sum/COUNT) < @options[:startup], "Application: #{@options[:application]} avarage startup was slower than #{@options[:startup]} ms")
    end

    if @options[:appCache] != nil
      print_debug("Check that MApplication from cache takes less than #{@options[:appCache]} ms")
      assert((app_cache_sum/COUNT) < @options[:appCache], "Application: #{@options[:application]} avarage app-cache was slower than #{@options[:appCache]} ms")
    end

    if @options[:winCache] != nil
      print_debug("Check that MApplicationWindow from cache takes less than #{@options[:winCache]} ms")
      assert((win_cache_sum/COUNT) < @options[:winCache], "Application: #{@options[:application]} avarage window-cache was slower than #{@options[:winCache]} ms")
    end
    
  end
end


