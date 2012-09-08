require File.join(File.dirname(__FILE__), "book.rb")
require 'erb'
require 'sinatra'
include Book

get('/'){ erb build }

get('/download'){ build(true); send_file "#{OUTPUT_DIR}/sinatra-book.pdf", :type => 'application/pdf'; }

get('/book.css') { send_file "#{ASSETS_DIR}/book.css", :type => 'text/css' }

get('/download.png') { send_file "#{ASSETS_DIR}/images/download.png", :type => :png }

__END__
@@layout
<html>
  <head>
    <title>Sinatra Book</title>
    <link rel="stylesheet" type="text/css" href="/book.css" />
  </head>
  <body>
    <div id="download">
      <a href="/download">
        <img src="/download.png" alt="Download the Sinatra Book" />
      </a>
    </div>
    <%= yield %>
  </body>
</html>
