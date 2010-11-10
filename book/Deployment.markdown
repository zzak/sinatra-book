Deployment
==========

Heroku
------

This is the easiest configuration + deployment option.  [Heroku] has full support for Sinatra applications.   Deploying to Heroku is simply a matter of pushing to a remote git repository.

Steps to deploy to Heroku:

* Create an [account](http://heroku.com/signup) if you don't have one
* `gem install heroku`
* Make a config.ru in the root-directory
* Create the app on heroku
* Push to it

1. Here is an example config.ru file that does two things.  First, it requires
   your main app file, whatever it's called. In the example, it will look for
   `myapp.rb`.  Second, run your application.  If you're subclassing, use the
   subclass's name, otherwise use Sinatra::Application.

        require "myapp"

        run Sinatra::Application

2. Create the app and push to it

       From the root-directory of the application

       $ heroku create <app-name>  # This will add heroku as a remote
       $ git push heroku master

For more details see [this](http://github.com/sinatra/heroku-sinatra-app)

[Heroku]: http://www.heroku.com

Lighttpd Proxied to Thin        {#deployment_lighttpd}
------------------------

This will cover how to deploy Sinatra to a load balanced reverse
proxy setup using Lighttpd and Thin.

1. Install Lighttpd and Thin

       # Figure out lighttpd yourself, it should be handled by your 
       # linux distro's package manager
        
       # For thin:
       gem install thin

2. Create your rackup file -- the `require 'app'` line should require the actual 
   Sinatra app you have written.

       ## This is not needed for Thin > 1.0.0
       ENV['RACK_ENV'] = "production"

       require 'app'
       
       run Sinatra::Application

3. Setup a config.yml - change the /path/to/my/app path to reflect reality.

       ---
         environment: production
         chdir: /path/to/my/app
         address: 127.0.0.1
         user: root
         group: root
         port: 4567
         pid: /path/to/my/app/thin.pid
         rackup: /path/to/my/app/config.ru
         log: /path/to/my/app/thin.log
         max_conns: 1024
         timeout: 30
         max_persistent_conns: 512
         daemonize: true

4. Setup lighttpd.conf - change mydomain to reflect reality. Also make 
   sure the first port here matches up with the port setting in config.yml.

       $HTTP["host"] =~ "(www\.)?mydomain\.com"  {
               proxy.balance = "fair"
               proxy.server =  ("/" =>
                                       (
                                               ( "host" => "127.0.0.1", "port" => 4567 ),
                                               ( "host" => "127.0.0.1", "port" => 4568 )
                                       )
                               )
       }

5. Start thin and your application. I have a rake script so I can just 
   call "rake start" rather than typing this in. 

       thin -s 2 -C config.yml -R config.ru start

You're done! Go to mydomain.com/ and see the result! Everything should be setup
now, check it out at the domain you setup in your lighttpd.conf file.

*Variation* - nginx via proxy - The same approach to proxying can be applied to
the nginx web server

    upstream www_mydomain_com {
      server 127.0.0.1:5000;
      server 127.0.0.1:5001;
    }
    
    server {
      listen    www.mydomain.com:80
      server_name  www.mydomain.com live;
      access_log /path/to/logfile.log
      
      location / {
        proxy_pass http://www_mydomain_com;
      }
      
    }

*Variation* - More Thin instances - To add more thin instances, change the 
`-s 2` parameter on the thin start command to be how ever many servers you want. 
Then be sure lighttpd proxies to all of them by adding more lines to the proxy 
statements. Then restart lighttpd and everything should come up as expected.


Apache and Passenger (mod rails)           {#deployment_passenger}
------------------------
Hate deployment via FastCGI? You're not alone. But guess what, Passenger
supports Rack; and this book tells you how to get it all going.

You can find additional documentation at the [official modrails
website](http://modrails.com/documentation.html).

The easiest way to get started with Passenger is via the gem.

### Installation

First you will need to have [Apache
installed](http://httpd.apache.org/docs/2.2/install.html), then you can move
onto installing passenger and the apache passenger module.

You have a number of options when [installing phusion
passenger](http://modrails.com/documentation/Users%20guide%20Apache.html#_installing_upgrading_and_uninstalling_phusion_passenger),
however the gem is likely the easiest way to get started.

    gem install passenger

Once you've got that installed you can build the passenger apache module.

    passenger-install-apache2-module

Follow the instructions given by the installer.

### Deploying your app 

Passenger lets you easily deploy Sinatra apps through the Rack interface.

There are some assumptions made about your application, however, particularly
the `tmp` and `public` sub-directories of your application.

In order to fit these prerequisites, simply make sure you have the following
setup:

    mkdir public
    mkdir tmp
    config.ru

The public directory is for serving static files and tmp directory is for the
`restart.txt` application restart mechanism. `config.ru` is where you will
place your rackup configuration.

**Rackup**

Once you have these directories in place, you can setup your applications
rackup file, `config.ru`.

    require 'rubygems'
    require 'sinatra'
    require 'app.rb'

    run Sinatra::Application 

**Virtual Host**

Next thing you'll have to do is setup the [Apache Virtual
Host](http://httpd.apache.org/docs/2.2/vhosts/) for your app.

    <VirtualHost *:80>
        ServerName www.yourapplication.com
        DocumentRoot /path/to/app/public
        <Directory /path/to/app/public>
            Allow from all
            Options -MultiViews
        </Directory>
    </VirtualHost>    

That should just about do it for your basic apache and passenger configuration.
For more specific information please visit the [official modrails
documentation](http://modrails.com/documentation/Users%20guide%20Apache.html).

### A note about restarting the server

Once you've got everything configured it's time to [restart
Apache](http://httpd.apache.org/docs/2.2/stopping.html).

On most debian-based systems you should be able to:

    sudo apache2ctl stop
    # then
    sudo apache2ctl start

To restart Apache. Check the link above for more detailed information.

In order to [restart the Passenger
application](http://www.modrails.com/documentation/Users%20guide%20Apache.html#_redeploying_restarting_the_ruby_on_rails_application),
all you need to do is run this simple command for your application root:

    touch tmp/restart.txt

You should be up and running now with [Phusion Passenger](http://modrails.com/)
and [Apache](http://httpd.apache.org/), if you run into any problems please
consult the official docs.

Dreamhost Deployment via Passenger      {#deployment_dreamhost}
----------------------------------

You can deploy your Sinatra apps to Dreamhost, a shared web hosting service,
via Passenger with relative ease. Here's how.

1. Setting up the account in the Dreamhost interface

       Domains -> Manage Domains -> Edit (web hosting column)
       Enable 'Ruby on Rails Passenger (mod_rails)'
       Add the public directory to the web directory box. So if you were using 'rails.com', it would change to 'rails.com/public'
       Save your changes

2. Creating the directory structure

       domain.com/
       domain.com/tmp
       domain.com/public
       # a vendored version of sinatra - not necessary if you use the gem
       domain.com/sinatra

3. Here is an example config.ru file that does two things.  First, it requires
   your main app file, whatever it's called. In the example, it will look for
   `myapp.rb`.  Second, run your application.  If you're subclassing, use the
   subclass's name, otherwise use Sinatra::Application.

        require "myapp"

        run Sinatra::Application

4. A very simple Sinatra application

       # this is myapp.rb referred to above
        require 'sinatra'
        get '/' do
          "Worked on dreamhost"
        end
         
        get '/foo/:bar' do
          "You asked for foo/#{params[:bar]}"
        end

And that's all there is to it! Once it's all setup, point your browser at your 
domain, and you should see a 'Worked on Dreamhost' page. To restart the 
application after making changes, you need to run `touch tmp/restart.txt`.

Please note that currently passenger 2.0.3 has a bug where it can cause Sinatra to not find
the view directory. In that case, add `:views => '/path/to/views/'` to the Sinatra options
in your Rackup file.

You may encounter the dreaded "Ruby (Rack) application could not be started" 
error with this message "can't activate rack (>= 0.9.1, < 1.0, runtime), 
already activated rack-0.4.0". This happens because DreamHost has version 0.4.0
installed, when recent versions of Sinatra require more recent versions of Rack.
The solution is to explicitly require the rack and sinatra gems in your 
config.ru. Add the following two lines to the start of your config.ru file:
  
       require '/home/USERNAME/.gem/ruby/1.8/gems/rack-VERSION-OF-RACK-GEM-YOU-HAVE-INSTALLELD/lib/rack.rb'
       require '/home/USERNAME/.gem/ruby/1.8/gems/sinatra-VERSION-OF-SINATRA-GEM-YOU-HAVE-INSTALLELD/lib/sinatra.rb'


FastCGI                                        {#deployment_fastcgi}
-------
The standard method for deployment is to use Thin or Mongrel, and have a 
reverse proxy (lighttpd, nginx, or even Apache) point to your bundle of servers.

But that isn't always possible. Cheaper shared hosting (like Dreamhost) won't
let you run Thin or Mongrel, or setup reverse proxies (at least on the default
shared plan).

Luckily, Rack supports various connectors, including CGI and FastCGI. Unluckily
for us, FastCGI doesn't quite work with the current Sinatra release without some tweaking.

### Deployment with Sinatra version 0.9
From version 0.9.0 Sinatra requires Rack 0.9.1, however FastCGI wrapper from
this version seems not working well with Sinatra unless you define your
application as a subclass of Sinatra::Application class and run this
application directly as a Rack application.

Steps to deploy via FastCGI:
* htaccess
* subclass your application as Sinatra::Application
* dispatch.fcgi

1. .htaccess

        RewriteEngine on
        
        AddHandler fastcgi-script .fcgi
        Options +FollowSymLinks +ExecCGI
        
        RewriteRule ^(.*)$ dispatch.fcgi [QSA,L]

2. Subclass your application as Sinatra::Application

        # my_sinatra_app.rb
        class MySinatraApp < Sinatra::Application
          # your sinatra application definitions
        end


3. dispatch.fcgi - Run this application directly as a Rack application

        #!/usr/local/bin/ruby
    
        require 'rubygems'
        require 'rack'
        
        fastcgi_log = File.open("fastcgi.log", "a")
        STDOUT.reopen fastcgi_log
        STDERR.reopen fastcgi_log
        STDOUT.sync = true

        module Rack
          class Request
            def path_info
              @env["REDIRECT_URL"].to_s
            end
            def path_info=(s)
              @env["REDIRECT_URL"] = s.to_s
            end
          end
        end

        load 'my\_sinatra\_app.rb'

        builder = Rack::Builder.new do
          map '/' do
            run MySinatraApp.new
          end
        end

        Rack::Handler::FastCGI.run(builder)


