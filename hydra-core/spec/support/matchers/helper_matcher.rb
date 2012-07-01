RSpec::Matchers.define :be_html_safe do 
  match do |actual|
    actual.html_safe?
  end
  failure_message_for_should do |actual|
    "Expected that #{actual.inspect} would be marked as html safe"
  end

  failure_message_for_should_not do |actual|
    "Expected that #{actual.inspect} would not be marked as html safe"
  end
end


