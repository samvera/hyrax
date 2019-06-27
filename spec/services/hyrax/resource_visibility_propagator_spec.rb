# frozen_string_literal: true

RSpec.describe Hyrax::ResourceVisibilityPropagator do
  subject(:propagator) { described_class.new(source: work) }
  let(:queries)        { Hyrax.query_service.custom_queries }
  let(:work)           { FactoryBot.create(:work_with_files).valkyrie_resource }
  let(:file_sets)      { queries.find_child_filesets(resource: work) }

  context 'a public work' do
    before { work.visibility = 'open' }

    it 'updates the file_set permissions' do
      # files are private at the outset
      expect(file_sets.first.visibility).to eq 'restricted'

      expect { propagator.propagate }
        .to change { queries.find_child_filesets(resource: work).map(&:visibility) }
        .to contain_exactly(work.visibility, work.visibility)
    end
  end
end
