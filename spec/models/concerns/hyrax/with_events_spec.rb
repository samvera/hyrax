# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::WithEvents do
  subject(:eventable) { model_with_events.new }
  let(:action) { 'FAKE EVENT ACTION' }
  let(:event) { Hyrax::Event.create_now(action) }

  let(:model_with_events) do
    module Hyrax
      module Test
        module WithEvents
          class Model
            extend ActiveModel::Naming
            include Hyrax::WithEvents
          end
        end
      end
    end
  end

  after { Hyrax::Test.send(:remove_const, :WithEvents) }

  describe '#events' do
    context 'when there are no events' do
      it 'is empty' do
        expect(eventable.events).to be_empty
      end
    end

    context 'with many events' do
      before do
        12.times { eventable.log_event(event) }
      end

      it 'lists all events' do
        expect(eventable.events.count).to eq 12
      end

      it 'accepts an argument to list most recent events' do
        eventable.log_event(Hyrax::Event.create_now('NEW ACTION'))
        expect(eventable.events(0))
          .to contain_exactly(action: 'NEW ACTION', timestamp: an_instance_of(String))
      end
    end
  end

  describe '#log_event' do
    it 'appends the event to the log' do
      expect { eventable.log_event(event) }
        .to change { eventable.events }
        .to contain_exactly(action: action, timestamp: an_instance_of(String))
    end
  end
end
