# RSpec matcher to spec delegations.

RSpec::Matchers.define :raise_rescue_response_type do |expected_rescue_response|
  match do |response|
    @expected_rescue_response = expected_rescue_response.to_sym
    @exception = nil

    begin
      @status = response.call.status
    rescue Exception => e
      @exception = e
    end

    if @exception.nil?
      @actual_rescue_response = @status
      @status == Rack::Utils.status_code(@expected_rescue_response)
    else
      response = ActionDispatch::ExceptionWrapper.rescue_responses[@exception.class.name]
      @actual_rescue_response = ActionDispatch::ExceptionWrapper.rescue_responses[@exception.class.name].to_sym
      @actual_rescue_response == @expected_rescue_response
    end
  end

  description do
    "expected to raise an exception with rescue_response #{@expected_rescue_response.inspect}"
  end

  failure_message_for_should do |text|
    text = "expected to raise an exception with rescue_response"
    text << " #{@expected_rescue_response.inspect} instead got #{@actual_rescue_response.inspect}"
    text << " (Exception #{@exception.class}: #{@exception})" if @exception
    text
  end

  failure_message_for_should_not do |text|
    text = "expected to NOT raise an exception with rescue_response"
    text << " #{@expected_rescue_response.inspect} but got #{@actual_rescue_response.inspect}"
    text << " (Exception #{@exception.class}: #{@exception})" if @exception
    text
  end

end
