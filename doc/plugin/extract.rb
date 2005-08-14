module CmdparsePlugins

  class ExtractTag < Tags::DefaultTag

    summary "Extracts lines from a file"
    depends_on 'Tags'
    add_param 'file', nil, 'the file from which to read the lines'
    add_param 'lines', nil, 'the lines which should be read (Range)'
    set_mandatory 'file'
    set_mandatory 'lines'

    def initialize
      super
      @processOutput = false
      register_tag( 'extract' )
    end

    def process_tag( tag, node, refNode )
      data = File.readlines( get_param( 'file' ) ).unshift( 'empty null line' )[get_param( 'lines' )]
      out = '<table class="cmdparse-example"><tr>'
      out << '<td><pre>' << get_param( 'lines' ).collect {|n| "#{n}<br />" }.to_s << '</pre></td>'
      out << '<td><pre>' << data.collect {|line| "#{CGI::escapeHTML(line)}" }.to_s << '</pre></td>'
      out << '</tr></table>'
      out
    end

  end

end
