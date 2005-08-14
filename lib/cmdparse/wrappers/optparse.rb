#
#--
#
# $Id$
#
# cmdparse: advanced command line parser supporting commands
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
#

require 'optparse'

# Some extension to the standard option parser class
class OptionParser

  if const_defined?( 'Officious' )
    Officious.delete( 'version' )
    Officious.delete( 'help' )
  else
    DefaultList.long.delete( 'version' )
    DefaultList.long.delete( 'help' )
  end

end

module CmdParse

  # Parser wrapper for OptionParser (included in Ruby Standard Library).
  class OptionParserWrapper < ParserWrapper

    # Initializes the wrapper with a default OptionParser instance or the +parser+ parameter and
    # yields this instance.
    def initialize( parser = OptionParser.new, &block )
      @instance = parser
      self.instance( &block )
    end

    def order( args )
      @instance.order( args )
    end

    def permute( args )
      @instance.permute( args )
    end

    def summarize
      @instance.summarize
    end

  end

end
