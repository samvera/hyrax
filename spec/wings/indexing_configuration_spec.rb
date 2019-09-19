# frozen_string_literal: true
require 'spec_helper'
require 'wings/indexing_configuration'

RSpec.describe ActiveFedora::Indexing::Map::IndexObject do
  describe '.as' do
    let(:hash) { {} }
    let(:args) { [:discoverable, :stored_searchable] }

    subject { described_class.new hash }

    it 'is deprecated' do
      expect(Deprecation).to receive(:warn)
      subject.as(*args)
    end
  end
end
