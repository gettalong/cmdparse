#!/usr/bin/env ruby
# if something is changed here -> change line numbers in doc/src/documentation.page

$:.unshift "lib"
require 'cmdparse'
require 'ostruct'
require 'yaml'

class NetStatCommand < CmdParse::Command

  def initialize
    super('stat', false)
    self.short_desc = "Show network statistics"
    self.description = "This command shows very useful network statistics - eye catching!!!"
  end

  def execute(args)
    puts "Showing network statistics" if $verbose
    puts
    puts "Yeah, I will do something now..."
    puts
    1.upto(10) do |row|
      puts " "*(20-row) + "#"*(row*2 - 1)
    end
    puts
  end

end

cmd = CmdParse::CommandParser.new(true, true)
cmd.program_name = "net"
cmd.program_version = [0, 1, 1]
cmd.options = CmdParse::OptionParserWrapper.new do |opt|
  opt.separator "Global options:"
  opt.on("--verbose", "Be verbose when outputting info") {|t| $verbose = true }
end
cmd.add_command(CmdParse::HelpCommand.new)
cmd.add_command(CmdParse::VersionCommand.new)
cmd.add_command(NetStatCommand.new)

# ipaddr
ipaddr = CmdParse::Command.new('ipaddr', true, true)
ipaddr.short_desc = "Manage IP addresses"
cmd.add_command(ipaddr)

# ipaddr add
add = CmdParse::Command.new('add', false)
add.short_desc = "Add an IP address"
add.set_execution_block do |args|
  puts "Adding ip addresses: #{args.join(', ')}" if $verbose
  $ipaddrs += args
end
ipaddr.add_command(add)

# ipaddr del
del = CmdParse::Command.new('del', false)
del.short_desc = "Delete an IP address"
del.options = CmdParse::OptionParserWrapper.new do |opt|
  opt.on('-a', '--all', 'Delete all IP addresses') { $deleteAll = true }
end
del.set_execution_block do |args|
  if $deleteAll
    $ipaddrs = []
  else
    puts "Deleting ip addresses: #{args.join(', ')}" if $verbose
    args.each {|ip| $ipaddrs.delete(ip) }
  end
end
ipaddr.add_command(del)

# ipaddr list
list = CmdParse::Command.new('list', false)
list.short_desc = "Lists all IP addresses"
list.set_execution_block do |args|
  puts "Listing ip addresses:" if $verbose
  puts $ipaddrs.to_yaml
end
ipaddr.add_command(list, true)

if File.exists?('dumpnet')
  $ipaddrs = Marshal.load(File.read('dumpnet'))
else
  $ipaddrs = []
end

cmd.parse

File.open('dumpnet', 'w+') {|f| f.write(Marshal.dump($ipaddrs)) }
