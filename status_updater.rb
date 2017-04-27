require 'cgi'
require 'json'
require 'httparty'

class Status

  def initialize
    @now = Time.now

    @lunch      = Time.new @now.year, @now.month, @now.day, 13, 0, 0
    @lunch_end  = Time.new @now.year, @now.month, @now.day, 14, 0, 0
    @drinking   = Time.new @now.year, @now.month, @now.day, 16, 30, 0
    @sleeping   = Time.new @now.year, @now.month, @now.day, 23, 0, 0
    @coffee     = Time.new @now.year, @now.month, @now.day, 8, 30, 0
    @coffee_end = Time.new @now.year, @now.month, @now.day, 9, 30, 0
  end

  def current
    return get_current_status.to_json
  end

  def current_encoded
    CGI::escape(current)
  end

  private

  def get_current_status

    if @now.between?(@coffee, @coffee_end)
      return coffee_status
    elsif @now.between?(@coffee_end, @lunch)
      return default_status
    elsif @now.between?(@lunch, @lunch_end)
      return lunch_status
    elsif @now.between?(@lunch_end, @drinking)
      return default_status
    elsif @now.between?(@drinking, @sleeping)
      return drinking_status
    else
      return sleeping_status
    end
  end

  def default_status
    status("Working remotely", ":house_with_garden:")
  end

  def coffee_status
    status("Contemplating life", ":coffee:")
  end

  def lunch_status
    status("Lunch", ":burrito:")
  end

  def drinking_status
    status("Drinking", ":beers:")
  end

  def sleeping_status
    status("Sleeping", ":zzz:")
  end

  def status(text, emoji)
    {"status_text" => text, "status_emoji" => emoji}
  end
end

class SlackStatusUpdater
  include HTTParty
  base_uri 'slack.com/api/users.profile.set'

  def update_status(status)
    token = File.read('token')
    url = "?token=#{token}&profile=#{status}"
    self.class.post(url)
  end
end

status = Status.new
status_poster = SlackStatusUpdater.new
result = status_poster.update_status(status.current_encoded)
puts result.parsed_response if result.code != 200
