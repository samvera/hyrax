require "rubygems"
require "nokogiri"
require 'rest_client'

Then /^the page should be HTML5 valid$/ do
  response_is_html_valid?(page.body).should be_true
end

private

def response_is_html_valid?(resp)
  begin
    # http://validator.w3.org/docs/api.html says to sleep for at least 1 second between requests.  Just making sure we don't get throttled.
    sleep(1.0)
    validator_response = RestClient.post("http://validator.w3.org/check",
                                         :output => "soap12",
                                         :doctype => "HTML5",
                                         :fragment => resp)
  rescue SocketError, RestClient::BadGateway #meaning we're either not connected to the internet or we were throttled by the validator.
    puts "WARNING: No connection to W3C validator.  Page may not be HTML5 valid!"
    return true
  end
  
  xml = Nokogiri::XML(validator_response)

  #removing namespaces because we really don't care
  xml.remove_namespaces!

  # "true" or "false"
  valid = xml.xpath("//validity").text
  error_list = xml.xpath("//errors/errorlist/error")
  warning_list = xml.xpath("//warnings/warninglist/warning")

  error_count = xml.xpath("//errors/errorcount").text
  warning_count = xml.xpath("//warnings/warningcount").text

  errors = []
  warnings = []
  error_list.each do |err|
    errors << {:message => err.xpath("./message").text, :source => err.xpath("./source").text, :line => err.xpath("./line").text, :col => err.xpath("./col").text}
  end

  warning_list.each do |warn|
    warnings << warn.xpath("./message").text
  end
  
  if valid == "true"
    return true
  else
    text = "\n#{error_count} HTML5 Validation Error(s):\n"
    errors.each_with_index do |error,i|
      text << "  #{i+1}) Line #{error[:line]}, Column #{error[:col]}: #{error[:message]}\n"
    end
    puts text unless errors == []
    return false
  end
end