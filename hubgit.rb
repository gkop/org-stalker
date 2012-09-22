require 'bundler/setup'
Bundler.require

class Hubgit < Goliath::API
	# render templated files from ./views
	include Goliath::Rack::Templates

  def response(env)
    if env['REQUEST_PATH'] =~ /\A\/?\z/
      # landing page
      [200, {}, haml(:index)]
    elsif env['REQUEST_PATH'] == '/app.js'
      # app javascript
      [200, {'Content-Type' => 'application/javascript'}, coffee(:app)]
    elsif (r = env['REQUEST_PATH'].match /\A\/([^\/]*)/).size > 1
      # show the org or user
      @account = r[1]
      [200, {}, haml(:show)]
    end
  end
end
