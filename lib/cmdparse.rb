#
#--
#
# $Id$
#
# cmdparse: an advanced command line parser using optparse which supports commands
# Copyright (C) 2004 Thomas Leitner
#
# This program is free software; you can redistribute it and/or modify it under the terms of the GNU
# General Public License as published by the Free Software Foundation; either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
# even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with this program; if not,
# write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#++
#
# Look at the +CommandParser+ class for details and an example.
#

require 'optparse'

# Some extension to the standard option parser class
class OptionParser

  Officious.delete( 'version' )
  Officious.delete( 'help' )

  # Returns the <tt>@banner</tt> value. Needed because the method <tt>OptionParser#banner</tt> does
  # not return the internal value of <tt>@banner</tt> but a modified one.
  def get_banner
    @banner
  end

  # Returns the <tt>@program_name</tt> value. Needed because the method
  # <tt>OptionParser#program_name</tt> does not return the internal value of <tt>@program_name</tt>
  # but a modified one.
  def get_program_name
    @program_name
  end

end


# = CommandParser
#
# == Introduction
#
# +CommandParser+ is a class for analyzing the command line of a program. It uses the standard
# +OptionParser+ class internally for parsing the options and additionally allows the
# specification of commands. Programs which use commands as part of their command line interface
# are, for example, Subversion's +svn+ program and Rubygem's +gem+ program.
#
# == Example
#
#   require 'cmdparse'
#   require 'ostruct'
#
#   class TestCommand < CommandParser::Command
#
#     def initialize
#       super('test')
#       @internal = OpenStruct.new
#       @internal.function = nil
#       @internal.audible = false
#       options.separator "Options:"
#       options.on("-t", "--test FUNCTION", "Test only FUNCTION") do |func|
#         @internal.function = func
#       end
#       options.on("-a", "--[no-]audible", "Run audible") { |@internal.audible| }
#     end
#
#     def description
#       "Executes various tests"
#     end
#
#     def execute( commandParser, args )
#       puts "Test: "+ args.inspect
#       puts @internal.inspect
#     end
#
#   end
#
#   cmd = CommandParser.new
#   cmd.options do |opt|
#     opt.program_name = "testProgram"
#     opt.version = [0, 1, 0]
#     opt.release = "1.0"
#     opt.separator "Global options:"
#     opt.on("-r", "--require TEST",  "Require the TEST")
#     opt.on("--delay N", Integer, "Delay test for N seconds before executing")
#   end
#   cmd.add_command TestCommand.new, true # sets this command as default command
#   cmd.add_command CommandParser::HelpCommand.new
#   cmd.add_command CommandParser::VersionCommand.new
#   cmd.parse!( ARGV )
#
class CommandParser

  # The version of the command parser
  VERSION = [1, 0, 3]

  # This error is thrown when an invalid command is encountered.
  class InvalidCommandError < OptionParser::ParseError
    const_set( :Reason, 'invalid command'.freeze )
  end

  # This error is thrown when no command was given and no default command was specified.
  class NoCommandGivenError < OptionParser::ParseError
    const_set( :Reason, 'no command given'.freeze )
  end

  # Base class for the commands. This class implements all needed methods so that it can be used by
  # the +OptionParser+ class.
  class Command

    # The name of the command
    attr_reader :name

    # The command line options, an instance of +OptionParser+.
    attr_reader :options

    # Initializes the command and assignes it a +name+.
    def initialize( name )
      @name = name
      @options = OptionParser.new
    end

    # For sorting commands by name
    def <=>( other )
      @name <=> other.name
    end

    # Should be overridden by specific implementations. This method is called after the command is
    # added to a +CommandParser+ instance.
    def init( commandParser )
    end

    # Default method for showing the help for the command.
    def show_help( commandParser )
      @options.program_name = commandParser.options.program_name if @options.get_program_name.nil?
      puts "#{@name}: #{description}"
      puts usage
      puts ""
      puts options.summarize
    end

    # Should be overridden by specific implementations. Defines the description of the command.
    def description
      '<no description given>'
    end

    # Defines the usage line for the command. Can be overridden if a more specific usage line is needed.
    def usage
      "Usage: #{@options.program_name} [global options] #{@name} [options] args"
    end

    # Must be overridden by specific implementations. This method is called by the +CommandParser+
    # if this command was specified on the command line.
    def execute( commandParser, args )
      raise NotImplementedError
    end

  end


  # The default help command.It adds the options "-h" and "--help" to the global +CommandParser+
  # options. When specified on the command line, it can show the main help or an individual command
  # help.
  class HelpCommand < Command

    def initialize
      super( 'help' )
    end

    def init( commandParser )
      commandParser.options do |opt|
        opt.on_tail( "-h", "--help [command]", "Show help" ) do |cmd|
          execute( commandParser, cmd.nil? ? [] : [cmd] )
        end
      end
    end

    def description
      'Provides help for the individual commands'
    end

    def usage
      "Usage: #{@options.program_name} help COMMAND"
    end

    def execute( commandParser, args )
      if args.length > 0
        if commandParser.commands.include?( args[0] )
          commandParser.commands[args[0]].show_help( commandParser )
        else
          raise OptionParser::InvalidArgument, args[0]
        end
      else
        show_program_help( commandParser )
      end
      exit
    end

    private

    def show_program_help( commandParser )
      if commandParser.options.get_banner.nil?
        puts "Usage: #{commandParser.options.program_name} [global options] <command> [options] [args]"
      else
        puts commandParser.options.banner
      end
      puts ""
      puts "Available commands:"
      width = commandParser.commands.keys.max {|a,b| a.length <=> b.length }.length
      commandParser.commands.sort.each do |name, command|
        print commandParser.options.summary_indent + name.ljust( width + 4 ) + command.description
        print " (=default command)" if name == commandParser.default
        print "\n"
      end
      puts ""
      puts commandParser.options.summarize
    end

  end


  # The default version command. It adds the options "-v" and "--version" to the global
  # +CommandParser+ options. When specified on the command line, it shows the version of the
  # program. The output can be controlled by options.
  class VersionCommand < Command

    def initialize
      super( 'version' )
      @fullversion = false
      options.separator "Options:"
      options.on( "-f", "--full", "Show the full version string" ) { @fullversion = true }
    end

    def init( commandParser )
      commandParser.options do |opt|
        opt.on_tail( "--version", "-v", "Show the version of the program" ) do
          execute( commandParser, [] )
        end
      end
    end

    def description
      "Shows the version of the program"
    end

    def usage
      "Usage: #{@options.program_name} version [options]"
    end

    def execute( commandParser, args )
      if @fullversion
        version = commandParser.options.ver
      else
        version = commandParser.options.version
        version = version.join( '.' ) if version.instance_of? Array
      end
      version = "<NO VERSION SPECIFIED>" if version.nil?
      puts version
      exit
    end

  end

  # Holds the registered commands.
  attr_reader :commands

  # Returns the name of the default command.
  attr_reader :default

  # Are Exceptions be handled gracefully? I.e. by printing error message and help screen?
  attr_reader :handleExceptions

  # Create a new CommandParser object. The optional argument +handleExceptions+ specifies if the
  # object should handle exceptions gracefully.
  def initialize( handleExceptions = false )
    @options = OptionParser.new
    @commands = {}
    @default = nil
    @parsed = {}
    @handleExceptions = handleExceptions
  end

  # If called with a block, this method yields the global options of the +CommandParser+. If no
  # block is specified, it returns the global options.
  def options # :yields: options
    if block_given?
      yield @options
    else
      @options
    end
  end

  # Adds a command to the command list. If the optional parameter +default+ is true, then this
  # command is used when no command is specified on the command line.
  def add_command( command, default = false )
    @commands[command.name] = command
    @default = command.name if default
    command.init( self )
  end

  # Calls +parse+ - implemented to mimic OptionParser
  def permute( args ); parse( args ); end
  # Calls +parse!+ - implemented to mimic OptionParser
  def permute!( args ); parse!( args ); end
  # Calls +parse+ - implemented to mimic OptionParser
  def order( args ); parse( args ); end
  # Calls +parse!+ - implemented to mimic OptionParser
  def order!( args ); parse!( args ); end

  # see CommandParser#parse!
  def parse( args ); parse!( args.dup ); end

  # Parses the given argument. First it tries to parse global arguments if given. After that the
  # command name is analyzied and the options for the specific commands parsed. If +execCommand+
  # is true, the command is executed immediately. If false, the +CommandParser#execute+ has to be
  # called to execute the command.
  def parse!( args, execCommand = true )
    # parse global options
    begin
      @options.order!( args )
      @parsed[:command] = args.shift
      if @parsed[:command].nil?
        if @default.nil?
          raise NoCommandGivenError
        else
          @parsed[:command] = @default
        end
      else
        raise InvalidCommandError.new( @parsed[:command] ) unless commands.include?( @parsed[:command] )
      end
    rescue OptionParser::ParseError => e
      handle_exception( e, :global )
    end

    # parse local options
    begin
      commands[@parsed[:command]].options.permute!( args ) unless commands[@parsed[:command]].options.nil?
    rescue OptionParser::ParseError => e
      handle_exception( e, :local )
    end

    @parsed[:args] = args
    execute if execCommand
  end

  # Executes the command. The method +CommandParser#parse!+ has to be called before this one!
  def execute
    commands[@parsed[:command]].execute( self, @parsed[:args] ) if @parsed[:command]
  end

  private

  def handle_exception( exception, context )
    raise unless @handleExceptions
    s = (context == :global ? "global" : "command specific")
    puts "Error parsing #{s} options:\n    " + exception.message
    puts
    commands['help'].execute( self, (context == :global ? [] : [@parsed[:command]]) ) if commands['help']
    exit
  end

end

