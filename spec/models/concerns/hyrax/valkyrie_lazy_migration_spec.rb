# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::ValkyrieLazyMigration do
  before do
    class MigratingResource < Hyrax::Resource
    end
  end
  after { Object.send(:remove_const, :MigratingResource) }

  let(:model) { MigratingResource }
  let(:from) { Hyrax::Test::SimpleWorkLegacy }

  describe '.migrating' do
    subject { described_class.migrating(model, from: ) }

    it 'returns the given model' do
      expect(subject).to eq(model)
    end

    its(:migrating_from) { is_expected.to eq from }
    its(:to_rdf_representation) { is_expected.to eq from.to_rdf_representation }
    its(:included_modules) { is_expected.to include described_class  }
    its(:_hyrax_default_name_class) { is_expected.to eq Hyrax::Name }
    its(:name) { is_expected.to eq("MigratingResource") }
  end
end
