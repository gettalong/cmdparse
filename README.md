**cmdparse** - an advanced command line parser using optparse which has support for commands

Copyright (C) 2004-2014 Thomas Leitner

## Description

Some programs use a "command style" command line. Examples for such programs are the "svn" program
from Subversion and the "gem" program from Rubygems. The standard Ruby distribution has no library
to create programs that use such a command line interface.

This library, cmdparse, can be used to create such a command line interface. Internally it uses
optparse or any other option parser library to parse options and it provides a nice API for
specifying commands.

## License

GNU LGPLv3 - see COPYING.LESSER for the LGPL and COPYING for the GPL

## Dependencies

none

## Installation

The preferred way of installing cmdparse is via RubyGems:

    $ gem install cmdparse

If you do not have RubyGems installed, but Rake, you can use the following command:

    $ rake install

If you have neither RubyGems nor Rake, use these commands:

    $ ruby setup.rb config
    $ ruby setup.rb setup
    $ ruby setup.rb install

## Documentation

You can build the documentation by invoking

    $ rake doc

This builds the API and the additional documentation. The additional documentation needs webgen >=1.0.0
(http://webgen.gettalong.org) for building.


## Example

There is an example of how to use cmdparse in the `net.rb` file.


## Contact

Author: Thomas Leitner

* Web: <http://cmdparse.gettalong.org>
* e-Mail: <mailto:t_leitner@gmx.at>
