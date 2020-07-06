require 'dashing'

set :assets_prefix, '/qa-metrics/assets'
map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

configure do
  set :auth_token, 'YOUR_AUTH_TOKEN'

  # See http://www.sinatrarb.com/intro.html > Available Template Languages on
  # how to add additional template languages.
  set :template_languages, %i[html erb]

  helpers do
    def protected!
      # Put any authentication code you want in here.
      # This method is run before accessing any resource.
    end
  end
end

map Sinatra::Application.assets_prefix do
  run Sinatra::Application.sprockets
end

run Rack::URLMap.new('/qa-metrics' => Sinatra::Application)
