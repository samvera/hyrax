# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Hyrax::Flexibility' do
  before(:all) do
    module Hyrax::Test::Flexibility
      class TestWork < Hyrax::Resource
      end
    end
  end

  after(:all) do
    Hyrax::Test::Flexibility.send(:remove_const, :TestWork)
  end

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
        participants:
          type: hash
          data_type: array
          available_on:
            class:
            - Hyrax::Test::Flexibility::TestWork
          display_label:
            default: Participants
          view:
            render_as: compound
        participant_name:
          type: string
          name: name
          available_on:
            properties:
            - participants
        participant_role:
          type: string
          name: role
          available_on:
            properties:
            - participants
    YAML
  end

  before do
    allow(Hyrax.config).to receive(:flexible?).and_return(true)
    allow(Hyrax::FlexibleSchema).to receive(:find_by).and_return(schema)

    Hyrax::Test::Flexibility::TestWork.acts_as_flexible_resource
  end

  after do
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

    # Reloading from Postgres can hand .load compound values whose entry
    # hashes were taken apart on the way out of the database (see
    # Hyrax::CompoundNormalization): one entry's hash arrives as loose
    # [key, value] pairs, and a one-field entry arrives as a single flat
    # pair. These examples feed .new exactly those wire shapes and expect
    # whole entries back.
    context 'when a compound value arrives in the database wire shape' do
      it 'repairs one splayed multi-field entry into a single hash' do
        instance = flexibility_class.new(participants: [[:name, 'Ada'], [:role, 'Author']])
        expect(instance.participants).to eq([{ 'name' => 'Ada', 'role' => 'Author' }])
      end

      it 'repairs several one-field entries without losing any (repeated key)' do
        instance = flexibility_class.new(participants: [[:name, 'Ada'], [:name, 'Grace']])
        expect(instance.participants).to eq([{ 'name' => 'Ada' }, { 'name' => 'Grace' }])
      end

      it 'repairs a single one-field entry from a flat pair' do
        instance = flexibility_class.new(participants: ['name', 'Ada'])
        expect(instance.participants).to eq([{ 'name' => 'Ada' }])
      end

      it 'passes well-formed entries through untouched' do
        instance = flexibility_class.new(participants: [{ 'name' => 'Ada', 'role' => 'Author' },
                                                        { 'name' => 'Grace', 'role' => 'Editor' }])
        expect(instance.participants).to eq([{ 'name' => 'Ada', 'role' => 'Author' },
                                             { 'name' => 'Grace', 'role' => 'Editor' }])
      end
    end
  end
end
