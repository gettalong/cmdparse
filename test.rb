#!/usr/bin/env ruby

$: << "lib"
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

cmd = CommandParser.new
cmd.options do |opt|
  opt.program_name = "testProgram"
  opt.version = [0, 1, 0]
  opt.release = "1.0"
  opt.separator "Global options:"
  opt.on("-r", "--require TEST",  "Require the TEST")
  opt.on("--delay N", Integer, "Delay test for N seconds before executing")
end
cmd.add_command TestCommand.new
cmd.add_command CommandParser::HelpCommand.new
cmd.add_command CommandParser::VersionCommand.new
cmd.parse!( ARGV )
