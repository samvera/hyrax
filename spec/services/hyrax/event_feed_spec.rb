# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::EventFeed do
  subject(:feed) { described_class.new(model: resource) }
  let(:resource) { FactoryBot.valkyrie_create(:hyrax_resource) }

  describe '#events' do
    it 'logs the event with a specific namespace' do
      require 'pry'; binding.pry
    end
  end

  describe '#log_event' do
    it 'logs the event with a specific namespace' do
      require 'pry'; binding.pry
    end
  end
end
