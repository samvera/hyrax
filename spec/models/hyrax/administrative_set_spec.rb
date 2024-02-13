# frozen_string_literal: true

require 'spec_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe Hyrax::AdministrativeSet do
  it_behaves_like 'a Hyrax::AdministrativeSet'

  describe 'class methods' do
    subject { described_class }

    # The presence of this value is more important than the value; though only by a little bit.
    #
    # If we want to migrated to Hyrax::AdministrativeSet as a resource but not invalidate the Solr
    # index, we can set Hyrax::AdministrativeSet.to_rdf_representation to be that of the AdminSet;
    # something we're doing in the Lazy migration for Hyku.
    #
    # However, the current configuration assumes that this to_rdf_representation is different than
    # the AdminSet's to_rdf_representation.
    its(:to_rdf_representation) { is_expected.to be_present }
  end

  context 'when saving' do
    context 'with wings adapter' do
      let(:admin_set) { described_class.new(title: 'AdminSet with wings') }
      it 'can be persisted' do
        expect(Hyrax.persister.save(resource: admin_set)).to be_persisted
      end
    end

    context 'with non-wings adapter', valkyrie_adapter: :postgres_adapter do
      before do
        allow(Hyrax).to receive_message_chain(:config, :disable_wings).and_return(true) # rubocop:disable RSpec/MessageChain
        hide_const("Wings") # disable_wings=true removes the Wings constant
      end
      let(:admin_set) { described_class.new(title: 'AdminSet without wings') }
      it 'can be persisted' do
        expect(Hyrax.persister.save(resource: admin_set)).to be_persisted
      end
    end
  end
end
