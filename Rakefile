# -*- ruby -*-
#
#--
# cmdparse: advanced command line parser supporting commands
# Copyright (C) 2004-2014 Thomas Leitner
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

begin
  require 'rubygems'
  require 'rubygems/package_task'
rescue Exception
  nil
end

begin
  require 'webgen/page'
rescue LoadError
end

require 'rake/clean'
require 'rake/packagetask'
require 'rake/testtask'
require 'rdoc/task'

# General actions  ##############################################################

$:.unshift 'lib'
require 'cmdparse'

PKG_NAME = "cmdparse"
PKG_VERSION = CmdParse::VERSION.join('.')
PKG_FULLNAME = PKG_NAME + "-" + PKG_VERSION

# End user tasks ################################################################

# The default task is run if rake is given no explicit arguments.

desc "Default Task (does testing)"
task :default => :test

desc "Installs the package #{PKG_NAME} using setup.rb"
task :install do
  ruby "setup.rb config"
  ruby "setup.rb setup"
  ruby "setup.rb install"
end

task :clean do
  ruby "setup.rb clean"
end

Rake::TestTask.new do |test|
  test.test_files = FileList['test/tc_*.rb']
end

if defined?(Webgen)
  CLOBBER << "htmldoc"
  CLOBBER << "webgen-tmp"
  desc "Builds the documentation"
  task :htmldoc do
    sh "webgen"
  end
end

if defined? RDoc::Task
  RDoc::Task.new do |rdoc|
    rdoc.rdoc_dir = 'htmldoc/rdoc'
    rdoc.title = PKG_NAME
    rdoc.main = 'CmdParse::CommandParser'
    rdoc.options << '--line-numbers'
    rdoc.rdoc_files.include('lib')
  end
end

if defined?(Webgen) && defined?(RDoc::Task)
  desc "Build the whole user documentation"
  task :doc => [:rdoc, :htmldoc]
end

# Developer tasks ##############################################################

namespace :dev do

  PKG_FILES = FileList.new( [
                             'setup.rb',
                             'COPYING',
                             'COPYING.LESSER',
                             'README.md',
                             'Rakefile',
                             'net.rb',
                             'VERSION',
                             'lib/**/*.rb',
                             'doc/**/*',
                             'test/*'
                            ])

  CLOBBER << "VERSION"
  file 'VERSION' do
    puts "Generating VERSION file"
    File.open('VERSION', 'w+') {|file| file.write(PKG_VERSION + "\n")}
  end

  Rake::PackageTask.new('cmdparse', PKG_VERSION) do |pkg|
    pkg.need_tar = true
    pkg.need_zip = true
    pkg.package_files = PKG_FILES
  end

  if defined? Gem
    spec = Gem::Specification.new do |s|

      #### Basic information
      s.name = PKG_NAME
      s.version = PKG_VERSION
      s.summary = "Advanced command line parser supporting commands"
      s.description = <<-EOF
       cmdparse provides classes for parsing commands on the command line; command line options
       are parsed using optparse or any other option parser implementation. Programs that use
       such command line interfaces are, for example, subversion's 'svn' or Rubygem's 'gem' program.
      EOF
      s.license = 'LGPLv3'

      #### Dependencies, requirements and files
      s.files = PKG_FILES.to_a
      s.require_path = 'lib'
      s.autorequire = 'cmdparse'

      #### Documentation
      s.has_rdoc = true
      s.rdoc_options = ['--line-numbers', '--main', 'CmdParse::CommandParser']

      #### Author and project details
      s.author = "Thomas Leitner"
      s.email = "t_leitner@gmx.at"
      s.homepage = "http://cmdparse.gettalong.org"
    end

    Gem::PackageTask.new(spec) do |pkg|
      pkg.need_zip = true
      pkg.need_tar = true
    end

  end

  if defined?(Gem)
    desc "Upload the release to Rubygems"
    task :publish_files => [:package] do
      sh "gem push pkg/cmdparse-#{PKG_VERSION}.gem"
      puts 'done'
    end
  end

  if defined?(Webgen) && defined?(Gem) && defined?(Rake::RDocTask)
    desc "Release cmdparse version " + PKG_VERSION
    task :release => [:clobber, :package, :publish_files]
  end

end

task :clobber => ['dev:clobber']
