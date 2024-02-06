# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Goddess::CustomQueryContainer do
  let(:klass) do
    Class.new do
      include Goddess::CustomQueryContainer
      def initialize(query_service:)
        @query_service = query_service
      end

      attr_reader :query_service
    end
  end
  let(:query_service) { double("Query Service", services: [service_one, service_two]) }
end
