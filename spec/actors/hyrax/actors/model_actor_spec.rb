# coding: utf-8

module MusicalWork
  class Cover < ActiveFedora::Base
  end
end

class Hyrax::Actors::MusicalWork
  class CoverActor < ::Hyrax::Actors::AbstractActor
  end
end

RSpec.describe Hyrax::Actors::ModelActor do
  let(:work) { MusicalWork::Cover.new }
  let(:depositor) { create(:user) }
  let(:ability) { ::Ability.new(depositor) }
  let(:attributes) { {} }
  let(:change_set) { GenericWorkChangeSet.new(work) }
  let(:change_set_persister) { double }
  let(:env) { Hyrax::Actors::Environment.new(change_set, change_set_persister, ability, attributes) }

  describe '#model_actor' do
    subject { described_class.new('¯\_(ツ)_/¯').send(:model_actor, env) }

    it "preserves the namespacing" do
      is_expected.to be_kind_of Hyrax::Actors::MusicalWork::CoverActor
    end
  end
end
