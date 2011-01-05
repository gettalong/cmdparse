#
#--
# cmdparse: advanced command line parser supporting commands
# Copyright (C) 2004-2010 Thomas Leitner
#
# This file is part of cmdparse.
#
# cmdparse is free software: you can redistribute it and/or modify it under the terms of the GNU
# Lesser General Public License as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# cmdparse is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
# the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser
# General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along with cmdparse. If
# not, see <http://www.gnu.org/licenses/>.
#
#++
#

#  Namespace module for cmdparse.
module CmdParse

  # The version of this cmdparse implemention
  VERSION = [2, 0, 2]


  # Base class for all cmdparse errors.
  class ParseError < RuntimeError

    # Sets the reason for a subclass.
    def self.reason( reason, has_arguments = true )
      (@@reason ||= {})[self] = [reason, has_arguments]
    end

    # Returns the reason plus the message.
    def message
      data = @@reason[self.class] || ['Unknown error', true]
      data[0] + (data[1] ? ": " + super : '')
    end

  end

  # This error is thrown when an invalid command is encountered.
  class InvalidCommandError < ParseError
    reason 'Invalid command'
  end

  # This error is thrown when an invalid argument is encountered.
  class InvalidArgumentError < ParseError
    reason 'Invalid argument'
  end

  # This error is thrown when an invalid option is encountered.
  class InvalidOptionError < ParseError
    reason 'Invalid option'
  end

  # This error is thrown when no command was given and no default command was specified.
  class NoCommandGivenError < ParseError
    reason 'No command given', false
  end

  # This error is thrown when a command is added to another command which does not support commands.
  class TakesNoCommandError < ParseError
    reason 'This command takes no other commands', false
  end


  # Base class for all parser wrappers.
  class ParserWrapper

    # Returns the parser instance for the object and, if a block is a given, yields the instance.
    def instance
      yield @instance if block_given?
      @instance
    end

    # Parses the arguments in order, i.e. stops at the first non-option argument, and returns all
    # remaining arguments.
    def order( args )
      raise InvalidOptionError.new( args[0] ) if args[0] =~ /^-/
      args
    end

    # Permutes the arguments so that all options anywhere on the command line are parsed and the
    # remaining non-options are returned.
    def permute( args )
      raise InvalidOptionError.new( args[0] ) if args.any? {|a| a =~ /^-/}
      args
    end

    # Returns a summary string of the options.
    def summarize
      ""
    end

  end

  # Require default option parser wrapper
  require 'cmdparse/wrappers/optparse'

  # Command Hash - will return partial key matches as well if there is a single
  # non-ambigous matching key
  class CommandHash < Hash

    def []( cmd_name )
      super or begin
        possible = keys.select {|key| key =~ /^#{cmd_name}.*/ }
        fetch( possible[0] ) if possible.size == 1
      end
    end

  end

  # Base class for the commands. This class implements all needed methods so that it can be used by
  # the +CommandParser+ class.
  class Command

    # The name of the command
    attr_reader :name

    # A short description of the command.
    attr_accessor :short_desc

    # A detailed description of the command
    attr_accessor :description

    # The wrapper for parsing the command line options.
    attr_accessor :options

    # Returns the name of the default command.
    attr_reader :default_command

    # Sets or returns the super command of this command. The super command is either a +Command+
    # instance for normal commands or a +CommandParser+ instance for the root command.
    attr_accessor :super_command

    # Returns the list of commands for this command.
    attr_reader :commands

    # Initializes the command called +name+. The parameter +has_commands+ specifies if this command
    # takes other commands as argument. The optional argument +partial_commands+ specifies, if
    # partial command matching should be used.
    def initialize( name, has_commands, partial_commands = false )
      @name = name
      @options = ParserWrapper.new
      @has_commands = has_commands
      @commands = Hash.new
      @default_command = nil
      use_partial_commands( partial_commands )
    end

    def use_partial_commands( use_partial )
      temp = ( use_partial ? CommandHash.new : Hash.new )
      temp.update( @commands )
      @commands = temp
    end

    # Returns +true+ if this command supports sub commands.
    def has_commands?
      @has_commands
    end

    # Adds a command to the command list if this command takes other commands as argument. If the
    # optional parameter +default+ is true, then this command is used when no command is specified
    # on the command line.
    def add_command( command, default = false )
      raise TakesNoCommandError.new( @name ) if !has_commands?
      @commands[command.name] = command
      @default_command = command.name if default
      command.super_command = self
      command.init
    end

    # For sorting commands by name.
    def <=>( other )
      @name <=> other.name
    end

    # Returns the +CommandParser+ instance for this command or +nil+ if this command was not
    # assigned to a +CommandParser+ instance.
    def commandparser
      cmd = super_command
      cmd = cmd.super_command while !cmd.nil? && !cmd.kind_of?( CommandParser )
      cmd
    end

    # Returns a list of super commands, ie.:
    #   [command, super_command, super_super_command, ...]
    def super_commands
      cmds = []
      cmd = self
      while !cmd.nil? && !cmd.super_command.kind_of?( CommandParser )
        cmds << cmd
        cmd = cmd.super_command
      end
      cmds
    end

    # This method is called when the command is added to a +Command+ instance.
    def init; end

    # Set the given +block+ as execution block. See also: +execute+.
    def set_execution_block( &block )
      @exec_block = block
    end

    # Invokes the block set by +set_execution_block+. This method is called by the +CommandParser+
    # instance if this command was specified on the command line.
    def execute( args )
      @exec_block.call( args )
    end

    # Defines the usage line for the command.
    def usage
      tmp = "Usage: #{commandparser.program_name}"
      tmp << " [options] " if !commandparser.options.instance_of?( ParserWrapper )
      tmp << super_commands.reverse.collect do |c|
        t = c.name
        t << " [options]" if !c.options.instance_of?( ParserWrapper )
        t
      end.join(' ')
      tmp << (has_commands? ? " COMMAND [options] [ARGS]" : " [ARGS]")
    end

    # Default method for showing the help for the command.
    def show_help
      puts "#{@name}: #{short_desc}"
      puts description if description
      puts
      puts usage
      puts
      if has_commands?
        list_commands
        puts
      end
      unless (summary = options.summarize).empty?
        puts summary
        puts
      end
    end

    #######
    private
    #######

    def list_commands( level = 1, command = self )
      puts "Available commands:" if level == 1
      command.commands.sort.each do |name, cmd|
        print "  "*level + name.ljust( 15 ) + cmd.short_desc.to_s
        print " (=default command)" if name == command.default_command
        print "\n"
        list_commands( level + 1, cmd ) if cmd.has_commands?
      end
    end

  end

  # The default help command. It adds the options "-h" and "--help" to the global options of the
  # associated +CommandParser+. When the command is specified on the command line, it can show the
  # main help or individual command help.
  class HelpCommand < Command

    def initialize
      super( 'help', false )
      self.short_desc = 'Provide help for individual commands'
      self.description = 'This command prints the program help if no arguments are given. ' \
      'If one or more command names are given as arguments, these arguments are interpreted ' \
      'as a hierachy of commands and the help for the right most command is show.'
    end

    def init
      case commandparser.main_command.options
      when OptionParserWrapper
        commandparser.main_command.options.instance do |opt|
          opt.on_tail( "-h", "--help", "Show help" ) do
            execute( [] )
          end
        end
      end
    end

    def usage
      "Usage: #{commandparser.program_name} help [COMMAND SUBCOMMAND ...]"
    end

    def execute( args )
      if args.length > 0
        cmd = commandparser.main_command
        arg = args.shift
        while !arg.nil? && cmd.commands[ arg ]
          cmd = cmd.commands[arg]
          arg = args.shift
        end
        if arg.nil?
          cmd.show_help
        else
          raise InvalidArgumentError, args.unshift( arg ).join(' ')
        end
      else
        show_program_help
      end
      exit
    end

    #######
    private
    #######

    def show_program_help
      puts commandparser.banner + "\n" if commandparser.banner
      puts "Usage: #{commandparser.program_name} [options] COMMAND [options] [COMMAND [options] ...] [args]"
      puts ""
      list_commands( 1, commandparser.main_command )
      puts ""
      puts commandparser.main_command.options.summarize
      puts
    end

  end


  # The default version command. It adds the options "-v" and "--version" to the global options of
  # the associated +CommandParser+. When specified on the command line, it shows the version of the
  # program.
  class VersionCommand < Command

    def initialize
      super( 'version', false )
      self.short_desc = "Show the version of the program"
    end

    def init
      case commandparser.main_command.options
      when OptionParserWrapper
        commandparser.main_command.options.instance do |opt|
          opt.on_tail( "--version", "-v", "Show the version of the program" ) do
            execute( [] )
          end
        end
      end
    end

    def usage
      "Usage: #{commandparser.program_name} version"
    end

    def execute( args )
      version = commandparser.program_version
      version = version.join( '.' ) if version.instance_of?( Array )
      puts commandparser.banner + "\n" if commandparser.banner
      puts version
      exit
    end

  end


  # The main class for creating a command based CLI program.
  class CommandParser

    # A standard banner for help & version screens
    attr_accessor :banner

    # The top level command representing the program itself.
    attr_reader :main_command

    # The name of the program.
    attr_accessor :program_name

    # The version of the program.
    attr_accessor :program_version

    # Are Exceptions be handled gracefully? I.e. by printing error message and the help screen?
    attr_reader :handle_exceptions

    # Create a new CommandParser object. The optional argument +handleExceptions+ specifies if the
    # object should handle exceptions gracefully. Set +partial_commands+ to +true+, if you want
    # partial command matching for the top level commands.
    def initialize( handleExceptions = false, partial_commands = false )
      @main_command = Command.new( 'mainCommand', true )
      @main_command.super_command = self
      @main_command.use_partial_commands( partial_commands )
      @program_name = $0
      @program_version = "0.0.0"
      @handle_exceptions = handleExceptions
    end

    # Returns the wrapper for parsing the global options.
    def options
      @main_command.options
    end

    # Sets the wrapper for parsing the global options.
    def options=( wrapper )
      @main_command.options = wrapper
    end

    # Adds a top level command.
    def add_command( *args )
      @main_command.add_command( *args )
    end

    # Parses the command line arguments. If a block is specified, the current hierarchy level and
    # the name of the current command is yielded after the options for the level have been parsed.
    def parse( argv = ARGV ) # :yields: level, commandName
      level = 0
      command = @main_command

      while !command.nil?
        argv = if command.has_commands? || ENV.include?( 'POSIXLY_CORRECT' )
                 command.options.order( argv )
               else
                 command.options.permute( argv )
               end
        yield( level, command.name ) if block_given?

        if command.has_commands?
          cmdName, argv = argv[0], argv[1..-1] || []

          if cmdName.nil?
            if command.default_command.nil?
              raise NoCommandGivenError
            else
              cmdName = command.default_command
            end
          else
            raise InvalidCommandError.new( cmdName ) unless command.commands[ cmdName ]
          end

          command = command.commands[cmdName]
          level += 1
        else
          command.execute( argv )
          command = nil
        end
      end
    rescue ParseError, OptionParser::ParseError => e
      raise if !@handle_exceptions
      puts "Error while parsing command line:\n    " + e.message
      puts
      @main_command.commands['help'].execute( command.super_commands.reverse.collect {|c| c.name} ) if @main_command.commands['help']
      exit
    end

  end

end
