# -*- ruby -*-
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


begin
  require 'rubygems'
  require 'rake/gempackagetask'
rescue Exception
  nil
end

require 'rake/clean'
require 'rake/packagetask'
require 'rake/rdoctask'
require 'rake/testtask'

# General actions  ##############################################################

require 'lib/cmdparse'

PKG_NAME = "cmdparse"
PKG_VERSION = CommandParser::VERSION.join( '.' )
PKG_FULLNAME = PKG_NAME + "-" + PKG_VERSION

SRC_RB = FileList['lib/**/*.rb']

# The default task is run if rake is given no explicit arguments.

desc "Default Task"
task :default => :doc


# End user tasks ################################################################

desc "Prepares for installation"
task :prepare do
  ruby "setup.rb config"
  ruby "setup.rb setup"
end


desc "Installs the package #{PKG_NAME}"
task :install => [:prepare]
task :install do
  ruby "setup.rb install"
end


task :clean do
  ruby "setup.rb clean"
end


CLOBBER << "doc/output"
desc "Builds the documentation"
task :doc => [:rdoc] do
  chdir "doc" do
    sh "webgen"
  end
end

rd = Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/output/rdoc'
  rdoc.title    = PKG_NAME
  rdoc.options << '--line-numbers' << '--inline-source' << '-m README'
  rdoc.rdoc_files.include( 'README' )
  rdoc.rdoc_files.include( 'lib/**/*.rb' )
end


# Developer tasks ##############################################################


PKG_FILES = FileList.new( [
                            'setup.rb',
                            'TODO',
                            'COPYING',
                            'README',
                            'Rakefile',
                            'ChangeLog',
                            'test.rb',
                            'VERSION',
                            'lib/**/*.rb',
                            'doc/**/*'
                          ]) do |fl|
  fl.exclude( /\bsvn\b/ )
  fl.exclude( 'doc/output' )
end

if !defined? Gem
  puts "Package Target requires RubyGEMs"
else
  spec = Gem::Specification.new do |s|

    #### Basic information

    s.name = PKG_NAME
    s.version = PKG_VERSION
    s.summary = "An advanced command line parser using optparse which supports commands"
    s.description = <<-EOF
       cmdparse extends the default option parser 'optparse' by adding
       support for commands. Programs that use such command line interfaces
       are, for example, subversion's 'svn' or Rubygem's 'gem' program.
    EOF

    #### Dependencies, requirements and files

    s.files = PKG_FILES.to_a

    s.require_path = 'lib'
    s.autorequire = nil

    #### Documentation

    s.has_rdoc = true
    s.extra_rdoc_files = rd.rdoc_files.reject do |fn| fn =~ /\.rb$/ end.to_a
    s.rdoc_options = ['--line-numbers', '-m README']

    #### Author and project details

    s.author = "Thomas Leitner"
    s.email = "t_leitner@gmx.at"
    s.homepage = "cmdparse.rubyforge.org"
    s.rubyforge_project = "cmdparse"
  end

  task :package => [:generateFiles]
  task :generateFiles do |t|
    sh "svn log -r HEAD:1 -v > ChangeLog"
    File.open('VERSION', 'w+') do |file| file.write( PKG_VERSION + "\n" ) end
  end

  CLOBBER << "ChangeLog" << "VERSION"

  Rake::GemPackageTask.new( spec ) do |pkg|
    pkg.need_zip = true
    pkg.need_tar = true
  end

end

desc "Upload documentation to homepage"
task :uploaddoc => [:doc] do
  Dir.chdir('doc/output')
  sh "scp -r * gettalong@rubyforge.org:/var/www/gforge-projects/cmdparse/"
end


# Misc tasks ###################################################################


def count_lines( filename )
  lines = 0
  codelines = 0
  open( filename ) do |f|
    f.each do |line|
      lines += 1
      next if line =~ /^\s*$/
      next if line =~ /^\s*#/
      codelines += 1
    end
  end
  [lines, codelines]
end


def show_line( msg, lines, loc )
  printf "%6s %6s   %s\n", lines.to_s, loc.to_s, msg
end


desc "Show statistics"
task :statistics do
  total_lines = 0
  total_code = 0
  show_line( "File Name", "Lines", "LOC" )
  SRC_RB.each do |fn|
    lines, codelines = count_lines fn
    show_line( fn, lines, codelines )
    total_lines += lines
    total_code  += codelines
  end
  show_line( "Total", total_lines, total_code )
end
