# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Hyrax::Flexibility' do
  subject(:flexibility_class) { Hyrax::Test::Flexibility::TestWork }
  let(:schema) { Hyrax::FlexibleSchema.create(profile: profile.deep_merge(test_work_profile)) }
  let(:profile) { YAML.safe_load_file(Hyrax::Engine.root.join('spec', 'fixtures', 'files', 'm3_profile.yaml')) }
  let(:test_work_profile) do
    YAML.safe_load(<<-YAML)
      classes:
        Hyrax::Test::Flexibility::TestWork:
          display_label: Test Work
      properties:
        title:
          available_on:
            class:
            - Hyrax::Test::Flexibility::TestWork
    YAML
  end

  before do
    allow(Hyrax.config).to receive(:flexible?).and_return(true)
    allow(Hyrax::FlexibleSchema).to receive(:find).and_return(schema)

    module Hyrax::Test::Flexibility
      class TestWork < Hyrax::Resource
        include Hyrax::Flexibility if Hyrax.config.flexible?
      end
    end
  end

  after do
    Hyrax::Test::Flexibility.send(:remove_const, :TestWork)
    allow(Hyrax.config).to receive(:flexible?).and_return(false)
  end

  its(:included_modules) { is_expected.to include(Hyrax::Flexibility) }

  describe '#schema_version' do
    let(:flexibility_instance) { flexibility_class.new }

    it 'responds to #schema_version' do
      expect(flexibility_instance).to respond_to(:schema_version)
    end
  end

  describe '.attributes' do
    let(:flexibility_instance) { flexibility_class.new }

    it 'defines the attribute setter methods' do
      expect(flexibility_instance).to respond_to(:title=)
    end
  end

  describe '.new' do
    context 'when attributes is a Struct' do
      it 'creates a new instance with attributes converted to a hash' do
        new_instance = flexibility_class.new(Struct.new(:title).new(['Test Title']))
        expect(new_instance.title).to eq(['Test Title'])
      end
    end

    context 'when attributes is a hash' do
      it 'loads the attributes' do
        instance = flexibility_class.new(title: ['Test Title'])
        expect(instance.title).to eq(['Test Title'])
      end
    end
  end
end
