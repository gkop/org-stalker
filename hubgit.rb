require 'bundler/setup'
Bundler.require
require 'em-synchrony/em-http'

class Hubgit < Goliath::API
	# render templated files from ./views
	include Goliath::Rack::Templates

  def show(account)
    env['account'] = account
    url = "https://api.github.com/orgs/#{account}/members"

    http = logged_api_call(:organization, 1) do
      EM::HttpRequest.new(url).get
    end

    if http.response
      users = JSON.parse(http.response)
      env['users'] = users
      multi = EM::Synchrony::Multi.new

      users.each do |u|
        multi.add("#{u['login']}_events".to_sym,
                  EM::HttpRequest.new(u['url']+"/events").aget)
      end
      url = "https://api.github.com/orgs/#{account}/events"
      multi.add(:org_events, EM::HttpRequest.new(url).aget)
      res = logged_api_call(:users, users.size) do
        multi.perform
      end
      env['events'] = format_events(multi.responses[:callback])
      [200, {}, haml(:show)]
    end
  end

  def response(env)
    if env['REQUEST_PATH'] =~ /\A\/?\z/
      # landing page
      [200, {}, haml(:index)]
    elsif env['REQUEST_PATH'] == '/app.js'
      # app javascript
      [200, {'Content-Type' => 'application/javascript'}, coffee(:app)]
    elsif (r = env['REQUEST_PATH'].match /\A\/([^\/]*)/).size > 1
      # show the org or user
      show(r[1])
    end
  end

  private
  def logged_api_call(name, n)
    t0 = Time.now
    r = yield
    duration = Time.now - t0
    log_api_call(name, n, duration)
    r
  end

  def log_api_call(name, n, duration)
    env['api_calls'] ||= []
    env['api_calls'] << {:name => name, :num_requests => n, :total_time => duration}
  end

  def format_events(responses)
    responses.map {|r| JSON.parse(r[1].response)}.flatten.uniq.sort do |x,y|
      y['created_at'] <=> x['created_at']
    end
  end
end
