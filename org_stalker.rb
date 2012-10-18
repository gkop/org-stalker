require 'bundler/setup'
Bundler.require
require 'em-synchrony/em-http'

class OrgStalker < Goliath::API
	# render templated files from ./views
	include Goliath::Rack::Templates

  def show(account)
    env['account'] = account
    url = add_auth_params(
            "https://api.github.com/orgs/#{account}/public_members")

    http = logged_api_call(:organization, 1) do
      EM::HttpRequest.new(url).get
    end

    if http.response
      users = JSON.parse(http.response)
      if users.is_a?(Hash) && users["message"]
        return [200, {}, "Github API error: #{users["message"]}"]
      end

      env['users'] = users
      multi = EM::Synchrony::Multi.new
      users.each do |u|
        multi.add("#{u['login']}_events".to_sym,
                  EM::HttpRequest.new(add_auth_params(u['url']+"/events")).aget)
      end
      url = add_auth_params("https://api.github.com/orgs/#{account}/events")
      multi.add(:org_events, EM::HttpRequest.new(url).aget)
      res = logged_api_call(:events, users.size+1) do
        multi.perform
      end
      env['events'] = format_events(multi.responses[:callback])
      return env['events'] if env['events'][0] == 200
      env['statistics'] = get_stat(env['events'])

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
    elsif env['REQUEST_PATH'] == '/app.css'
      # app stylesheet
      [200, {'Content-Type' => 'text/css'}, sass(:app)]
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
    responses.map {|r| JSON.parse(r[1].response)}.flatten.uniq.reject do |e|
      if e.is_a?(Hash) && e["message"]
        return [200, {}, "Github API error: #{e["message"]}"]
      end
      Date.parse(e['created_at']) < Date.today - 30
    end.sort do |x,y|
      y['created_at'] <=> x['created_at']
    end
  end

  def get_stat(events)

    statistics = {}

    events.each do |e|
      key = e['type'].snake_case.sub(/_event\z/, '').to_sym
      statistics[key] = statistics.has_key?(key) ? statistics[key] + 1 : 1
    end

    statistics

  end

  def add_auth_params(url)
    if ENV['GH_CLIENT_ID'] && ENV['GH_CLIENT_SECRET']
      "#{url}?client_id=#{ENV["GH_CLIENT_ID"]}&client_secret=#{ENV["GH_CLIENT_SECRET"]}"
    else
      url
    end
  end

end
