require 'test/unit'
require 'cmdparse'

class CommandHashTest < Test::Unit::TestCase
  def setup
    @cmd = CmdParse::CommandHash.new
  end

  def test_basic
    assert_equal 0, @cmd.size
    assert_nil @cmd['import']
    @cmd['import'] = 1
    assert_equal 1, @cmd['import']
    assert_equal 1, @cmd['i']
    assert_equal 1, @cmd['im']
    assert_equal 1, @cmd['imp']
    assert_equal 1, @cmd['impo']
    assert_equal 1, @cmd['impor']
    assert_nil @cmd['importer']

    @cmd['implode'] = 2
    assert_equal 2, @cmd.size

    assert_equal 1, @cmd['import']
    assert_equal 2, @cmd['implode']
    assert_nil @cmd['impart']

    assert_nil @cmd['i']
    assert_nil @cmd['im']
    assert_nil @cmd['imp']
    assert_equal 1, @cmd['impo']
    assert_equal 1, @cmd['impor']
    assert_equal 1, @cmd['import']
    assert_equal 2, @cmd['implo']
    assert_equal 2, @cmd['implod']
    assert_equal 2, @cmd['implode']
  end

  def test_edge_cases
    @cmd['import'] = 1
    @cmd['important'] = 2

    assert_equal 1, @cmd['import']
    assert_equal 2, @cmd['important']
    assert_nil @cmd['i']
    assert_nil @cmd['im']
    assert_nil @cmd['imp']
    assert_nil @cmd['impo']
    assert_nil @cmd['impor']
    assert_equal 2, @cmd['importa']
    assert_equal 2, @cmd['importan']

    assert_nil @cmd['impart']
  end

  def test_integration
    # define and setup the commands
    cmd = CmdParse::CommandParser.new(handle_exceptions = false)
    cmd.main_command.use_partial_commands( true )
    Object.const_set(:ImportCommand, Class.new(CmdParse::Command) do
      def initialize() super('import', false) end
      def execute(args) raise 'import' end
      def show_help() raise 'import' end
    end)
    Object.const_set(:ImpolodeCommand, Class.new(CmdParse::Command) do
      def initialize() super('implode', false) end
      def execute(args) raise 'implode' end
      def show_help() raise 'implode' end
    end)
    cmd.add_command( ImportCommand.new )
    cmd.add_command( ImpolodeCommand.new )

    # simulate running the program
    assert_raises(RuntimeError, 'import') {cmd.parse(['import'])}
    assert_raises(RuntimeError, 'implode') {cmd.parse(['implode'])}
    assert_raises(CmdParse::InvalidCommandError) {cmd.parse(['impart'])}

    assert_raises(CmdParse::InvalidCommandError) {cmd.parse(['i'])}
    assert_raises(CmdParse::InvalidCommandError) {cmd.parse(['im'])}
    assert_raises(CmdParse::InvalidCommandError) {cmd.parse(['imp'])}
    assert_raises(RuntimeError, 'import') {cmd.parse(['impo'])}
    assert_raises(RuntimeError, 'import') {cmd.parse(['impor'])}
    assert_raises(RuntimeError, 'implode') {cmd.parse(['impl'])}
    assert_raises(RuntimeError, 'implode') {cmd.parse(['implo'])}
    assert_raises(RuntimeError, 'implode') {cmd.parse(['implod'])}

    # simulate the help command
    cmd.add_command( CmdParse::HelpCommand.new )
    assert_raises(RuntimeError, 'import') {cmd.parse(['help', 'import'])}
    assert_raises(RuntimeError, 'implode') {cmd.parse(['help', 'implode'])}

    cmd.main_command.use_partial_commands( false )
    assert_raises(CmdParse::InvalidCommandError, 'import') {cmd.parse(['impo'])}
    assert_raises(CmdParse::InvalidCommandError, 'implode') {cmd.parse(['impl'])}
  end
end
