# frozen_string_literal: true
# RSpec matchers for API default JSON responses.
# Creates a matcher like respond_forbidden or respond_not_found corresponding to each of the Api::V1.default_responses
# Accepts optional overrides to the expected response body.
# @example Override the description expected in the JSON body of a :forbidden response
#   expect(response).to respond_forbidden(description:"You can't create for that identity")
::Hyrax::API.default_responses.each_pair do |response_type, default_response_body|
  RSpec::Matchers.define "respond_#{response_type}".to_sym do |expectation_options|
    match do |response|
      @expected_response_body = expectation_options.nil? ? default_response_body : default_response_body.merge(expectation_options)
      expect(response.body).not_to be_empty
      json = JSON.parse(response.body)
      expect(response.code).to eq(@expected_response_body[:code].to_s)
      @expected_response_body.each_pair do |key, value|
        expect(json[key.to_s]).to eq(value.as_json)
      end
    end

    failure_message do |actual|
      "expected #{default_response_body[:code]} status code. Got #{actual.code} status code.\n" \
      "expected an Authentication Required response like this:\n" \
      " #{@expected_response_body.to_json} \ngot\n #{actual.body}\n" \
      "To override expectations about the response body, provide a Hash of overrides in " \
      "your call to :respond_#{response_type} "
    end
  end
end
