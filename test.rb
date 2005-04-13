#!/usr/bin/env ruby

$:.unshift "lib"
require 'cmdparse'
require 'ostruct'


class TestCommand < CommandParser::Command
  def initialize
    super('test')
    @internal = OpenStruct.new
    @internal.function = nil
    @internal.audible = false
    options.separator "Options:"
    options.on("-t", "--test FUNCTION", "Test only FUNCTION") do |func|
      @internal.function = func
    end
    options.on("-a", "--[no-]audible", "Run audible") { |@internal.audible| }
  end
  def description
    "Executes various tests"
  end
  def execute( commandParser, args )
    puts "Test: "+ args.inspect
    puts @internal.inspect
  end
end

class SubCommand < CommandParser::Command
  def initialize
    super('testing')
    options.on("-s", "tests")
  end
  def description
    "Testing method"
  end
  def execute( commandParser, args )
    puts "Processing command testing with <#{args.join(' ')}>"
  end
end

class SubCommands < CommandParser::Command
  def initialize
    super('other')
    @options = CommandParser.new
    @options.add_command SubCommand.new
    @options.add_command CommandParser::HelpCommand.new
  end
  def description
    "Provides additional commands"
  end
  def execute( commandParser, args )
    puts "Sub command finished: "
  end
end

cmd = CommandParser.new
cmd.options do |opt|
  opt.program_name = "testProgram"
  opt.version = [0, 1, 0]
  opt.release = "1.0"
  opt.separator "Global options:"
  opt.on("-r", "--require TEST",  "Require the TEST")
  opt.on("--delay N", Integer, "Delay test for N seconds before executing")
end
cmd.add_command TestCommand.new, true
cmd.add_command SubCommands.new
cmd.add_command CommandParser::HelpCommand.new
cmd.add_command CommandParser::VersionCommand.new
cmd.parse!( ARGV, false )
cmd.execute
