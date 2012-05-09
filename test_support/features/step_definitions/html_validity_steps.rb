require "rubygems"
require "nokogiri"
require 'rest_client'

Then /^the page should be HTML5 valid$/ do
  response_is_html_valid?(page.source).should be_true
end

class Html5Validator
  BASE_URI = 'http://html5.validator.nu'
  HEADERS = { 'Content-Type' => 'text/html; charset=utf-8', 'Content-Encoding' => 'UTF-8' }

  def initialize(text)
    @text = text

  end

  def valid?
    errors.empty?
  end

  def errors
    validation['messages'].select { |msg| msg['type'] == 'error' }
  end

  def validation
    @validation ||= validate!
  end

  def inspect
    str = "\n#{validator.errors.length} HTML5 Validation Error(s):\n"
    errors.each_with_index do |error,i|
      str << "  #{i+1}) #{ error['message'] }\n"
    end

    str
  end

  private
  def validate!
    response = RestClient.post "#{BASE_URI}/?out=json", @text, HEADERS
    JSON.parse(response.body)
  end
end

private

def response_is_html_valid?(resp)
  begin
    # http://validator.w3.org/docs/api.html says to sleep for at least 1 second between requests.  Just making sure we don't get throttled.
    sleep(1.0)
    validator = Html5Validator.new(resp)
    return true if validator.valid?
  rescue SocketError, RestClient::BadGateway #meaning we're either not connected to the internet or we were throttled by the validator.
    puts "WARNING: No connection to W3C validator.  Page may not be HTML5 valid!"
    return true
  rescue RestClient::RequestTimeout
    puts "WARNING: Timeout connecting to W3C validator.  Page may not be HTML5 valid!"
    return true
  end

  puts validator.inspect
  return false
end
