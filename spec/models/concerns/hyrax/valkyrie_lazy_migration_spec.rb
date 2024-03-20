# frozen_string_literal: true

require 'spec_helper'
require 'wings'

RSpec.describe Hyrax::ValkyrieLazyMigration, :active_fedora do
  before do
    class MigratingFromWork < ActiveFedora::Base
      include Hyrax::WorkBehavior
      include Hyrax::CoreMetadata
    end

    class MigratingToResource < Hyrax::Work
    end

    described_class.migrating(MigratingToResource, from: MigratingFromWork)
  end

  after do
    Object.send(:remove_const, :MigratingToResource)
    Object.send(:remove_const, :MigratingFromWork)
  end

  describe '.migrating' do
    subject { MigratingToResource }

    its(:migrating_from) { is_expected.to eq MigratingFromWork }
    its(:migrating_to) { is_expected.to eq MigratingToResource }
    its(:to_rdf_representation) { is_expected.to eq MigratingFromWork.to_rdf_representation }
    its(:included_modules) { is_expected.to include described_class }
    its(:_hyrax_default_name_class) { is_expected.to eq Hyrax::ValkyrieLazyMigration::ResourceName }
    its(:name) { is_expected.to eq("MigratingToResource") }

    context 'the from adds new methods' do
      subject { MigratingFromWork }
      its(:migrating_from) { is_expected.to eq MigratingFromWork }
      its(:migrating_to) { is_expected.to eq MigratingToResource }
    end
  end

  describe 'resource.model_name' do
    subject { MigratingToResource.model_name }

    its(:klass) { is_expected.to eq(MigratingToResource) }
    its(:name) { is_expected.to eq("MigratingToResource") }

    its(:singular) { is_expected.to eq(MigratingFromWork.model_name.singular) }
    its(:plural) { is_expected.to eq(MigratingFromWork.model_name.plural) }
    its(:element) { is_expected.to eq(MigratingFromWork.model_name.element) }
    # The human value is something that is titleized
    its(:human) { is_expected.to eq(MigratingFromWork.model_name.human.titleize) }
    its(:collection) { is_expected.to eq(MigratingFromWork.model_name.collection) }
    its(:param_key) { is_expected.to eq(MigratingFromWork.model_name.param_key) }
    its(:i18n_key) { is_expected.to eq(MigratingFromWork.model_name.i18n_key) }
    its(:route_key) { is_expected.to eq(MigratingFromWork.model_name.route_key) }
    its(:singular_route_key) { is_expected.to eq(MigratingFromWork.model_name.singular_route_key) }
  end
end
