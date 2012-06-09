#
#--
# cmdparse: advanced command line parser supporting commands
# Copyright (C) 2004-2012 Thomas Leitner
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
  VERSION = [2, 0, 5]


  # Base class for all cmdparse errors.
  class ParseError < RuntimeError

    # Set the reason for a subclass.
    def self.reason(reason, has_arguments = true)
      (@@reason ||= {})[self] = [reason, has_arguments]
    end

    # Return the reason plus the message.
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

    # Return the parser instance for the object and, if a block is a given, yield the instance.
    def instance
      yield @instance if block_given?
      @instance
    end

    # Parse the arguments in order, i.e. stops at the first non-option argument, and returns all
    # remaining arguments.
    def order(args)
      raise InvalidOptionError.new(args[0]) if args[0] =~ /^-/
      args
    end

    # Permute the arguments so that all options anywhere on the command line are parsed and the
    # remaining non-options are returned.
    def permute(args)
      raise InvalidOptionError.new(args[0]) if args.any? {|a| a =~ /^-/}
      args
    end

    # Return a summary string of the options.
    def summarize
      ""
    end

  end

  # Require default option parser wrapper
  require 'cmdparse/wrappers/optparse'

  # Command Hash - will return partial key matches as well if there is a single
  # non-ambigous matching key
  class CommandHash < Hash

    def [](cmd_name)
      super or begin
        possible = keys.select {|key| key[0, cmd_name.length] == cmd_name }
        fetch(possible[0]) if possible.size == 1
      end
    end

  end

  # Base class for the commands. This class implements all needed methods so that it can be used by
  # the +CommandParser+ class.
  class Command

    # The name of the command
    attr_reader :name

    # A short description of the command. Should ideally be smaller than 60 characters.
    attr_accessor :short_desc

    # A detailed description of the command. Maybe a single string or an array of strings for
    # multiline description. Each string should ideally be smaller than 76 characters.
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

    # Initialize the command called +name+.
    #
    # Parameters:
    #
    # [has_commands]
    #   Specifies if this command takes other commands as argument.
    # [partial_commands (optional)]
    #   Specifies whether partial command matching should be used.
    # [has_args (optional)]
    #   Specifies whether this command takes arguments
    def initialize(name, has_commands, partial_commands = false, has_args = true)
      @name = name
      @options = ParserWrapper.new
      @has_commands = has_commands
      @has_args = has_args
      @commands = Hash.new
      @default_command = nil
      use_partial_commands(partial_commands)
    end

    # Define whether partial command matching should be used.
    def use_partial_commands(use_partial)
      temp = (use_partial ? CommandHash.new : Hash.new)
      temp.update(@commands)
      @commands = temp
    end

    # Return +true+ if this command supports sub commands.
    def has_commands?
      @has_commands
    end

    # Return +true+ if this command uses arguments.
    def has_args?
      @has_args
    end

    # Add a command to the command list if this command takes other commands as argument.
    #
    # If the optional parameter +default+ is true, then this command is used when no command is
    # specified on the command line.
    def add_command(command, default = false)
      raise TakesNoCommandError.new(@name) if !has_commands?
      @commands[command.name] = command
      @default_command = command.name if default
      command.super_command = self
      command.init
    end

    # For sorting commands by name.
    def <=>(other)
      @name <=> other.name
    end

    # Return the +CommandParser+ instance for this command or +nil+ if this command was not assigned
    # to a +CommandParser+ instance.
    def commandparser
      cmd = super_command
      cmd = cmd.super_command while !cmd.nil? && !cmd.kind_of?(CommandParser)
      cmd
    end

    # Return a list of super commands, ie.:
    #   [command, super_command, super_super_command, ...]
    def super_commands
      cmds = []
      cmd = self
      while !cmd.nil? && !cmd.super_command.kind_of?(CommandParser)
        cmds << cmd
        cmd = cmd.super_command
      end
      cmds
    end

    # This method is called when the command is added to a +Command+ instance.
    def init; end

    # Set the given +block+ as execution block. See also: +execute+.
    def set_execution_block(&block)
      @exec_block = block
    end

    # Invoke the block set by +set_execution_block+.
    #
    # This method is called by the +CommandParser+ instance if this command was specified on the
    # command line.
    def execute(args)
      @exec_block.call(args)
    end

    # Define the usage line for the command.
    def usage
      tmp = "Usage: #{commandparser.program_name}"
      tmp << " [global options]" if !commandparser.options.instance_of?(ParserWrapper)
      tmp << super_commands.reverse.collect do |c|
        t = " #{c.name}"
        t << " [options]" if !c.options.instance_of?(ParserWrapper)
        t
      end.join('')
      tmp << " COMMAND [options]" if has_commands?
      tmp << " [ARGS]" if has_args?
      tmp
    end

    # Default method for showing the help for the command.
    def show_help
      puts commandparser.banner + "\n" if commandparser.banner
      puts usage
      puts
      if short_desc && !short_desc.empty?
        puts short_desc
        puts
      end
      if description && !description.empty?
        puts "    " + [description].flatten.join("\n    ")
        puts
      end
      if has_commands?
        list_commands
        puts
      end
      if !(summary = options.summarize).empty?
        puts summary
        puts
      end
      if self != commandparser.main_command &&
          !(summary = commandparser.main_command.options.summarize).empty?
        puts summary
        puts
      end
    end

    #######
    private
    #######

    def list_commands(command = self)
      puts "Available commands:"
      puts "  " + collect_commands_info(command).join("\n  ")
    end

    def collect_commands_info(command, level = 1)
      command.commands.sort.collect do |name, cmd|
        str =  "  "*level + name
        str = str.ljust(18) + cmd.short_desc.to_s
        str += " (default command)" if name == command.default_command
        [str] + (cmd.has_commands? ? collect_commands_info(cmd, level + 1) : [])
      end.flatten
    end

  end

  # The default help command. It adds the options "-h" and "--help" to the global options of the
  # associated +CommandParser+. When the command is specified on the command line, it can show the
  # main help or individual command help.
  class HelpCommand < Command

    def initialize
      super('help', false)
      self.short_desc = 'Provide help for individual commands'
      self.description = ['This command prints the program help if no arguments are given. If one or',
                          'more command names are given as arguments, these arguments are interpreted',
                          'as a hierachy of commands and the help for the right most command is show.']
    end

    def init
      case commandparser.main_command.options
      when OptionParserWrapper
        commandparser.main_command.options.instance do |opt|
          opt.on_tail("-h", "--help", "Show help") do
            execute([])
          end
        end
      end
    end

    def usage
      "Usage: #{commandparser.program_name} help [COMMAND SUBCOMMAND ...]"
    end

    def execute(args)
      if args.length > 0
        cmd = commandparser.main_command
        arg = args.shift
        while !arg.nil? && cmd.commands[arg]
          cmd = cmd.commands[arg]
          arg = args.shift
        end
        if arg.nil?
          cmd.show_help
        else
          raise InvalidArgumentError, args.unshift(arg).join(' ')
        end
      else
        commandparser.main_command.show_help
      end
      exit
    end

  end


  # The default version command. It adds the options "-v" and "--version" to the global options of
  # the associated +CommandParser+. When specified on the command line, it shows the version of the
  # program.
  class VersionCommand < Command

    def initialize
      super('version', false, false, false)
      self.short_desc = "Show the version of the program"
    end

    def init
      case commandparser.main_command.options
      when OptionParserWrapper
        commandparser.main_command.options.instance do |opt|
          opt.on_tail("--version", "-v", "Show the version of the program") do
            execute([])
          end
        end
      end
    end

    def usage
      "Usage: #{commandparser.program_name} version"
    end

    def execute(args)
      version = commandparser.program_version
      version = version.join('.') if version.instance_of?(Array)
      puts commandparser.banner + "\n" if commandparser.banner
      puts "#{commandparser.program_name} #{version}"
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

    # Should exceptions be handled gracefully? I.e. by printing error message and the help screen?
    attr_reader :handle_exceptions

    # Create a new CommandParser object.
    #
    # [handleExceptions (optional)]
    #   Specifies if the object should handle exceptions gracefully.
    # [partial_commands (optional)]
    #   Specifies if you want partial command matching for the top level commands.
    # [has_args (optional)]
    #   Specifies whether the command parser takes arguments (only used when no sub commands are
    #   defined).
    def initialize(handleExceptions = false, partial_commands = false, has_args = true)
      @main_command = Command.new('mainCommand', true, partial_commands, has_args)
      @main_command.super_command = self
      @program_name = $0
      @program_version = "0.0.0"
      @handle_exceptions = handleExceptions
    end

    # Return the wrapper for parsing the global options.
    def options
      @main_command.options
    end

    # Set the wrapper for parsing the global options.
    def options=(wrapper)
      @main_command.options = wrapper
    end

    # Add a top level command.
    def add_command(*args)
      @main_command.add_command(*args)
    end

    # Parse the command line arguments.
    #
    # If a block is specified, the current hierarchy level and the name of the current command is
    # yielded after the option parsing is done but before a command is executed.
    def parse(argv = ARGV) # :yields: level, commandName
      level = 0
      command = @main_command

      while !command.nil?
        argv = if command.has_commands? || ENV.include?('POSIXLY_CORRECT')
                 command.options.order(argv)
               else
                 command.options.permute(argv)
               end
        yield(level, command.name) if block_given?

        if command.has_commands?
          cmdName, argv = argv[0], argv[1..-1] || []

          if cmdName.nil?
            if command.default_command.nil?
              raise NoCommandGivenError
            else
              cmdName = command.default_command
            end
          else
            raise InvalidCommandError.new(cmdName) unless command.commands[ cmdName ]
          end

          command = command.commands[cmdName]
          level += 1
        else
          command.execute(argv)
          command = nil
        end
      end
    rescue ParseError, OptionParser::ParseError => e
      raise if !@handle_exceptions
      puts "Error while parsing command line:\n    " + e.message
      puts
      @main_command.commands['help'].execute(command.super_commands.reverse.collect {|c| c.name}) if @main_command.commands['help']
      exit
    end

  end

end
