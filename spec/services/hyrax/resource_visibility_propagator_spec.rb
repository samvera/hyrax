# frozen_string_literal: true

RSpec.describe Hyrax::ResourceVisibilityPropagator do
  subject(:propagator) { described_class.new(source: work) }
  let(:queries)        { Hyrax.custom_queries }
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

  context 'when work is under embargo' do
    let(:work) { FactoryBot.create(:embargoed_work_with_files).valkyrie_resource }

    before do
      fs = file_sets.first
      fs.visibility = 'open'
      fs.permission_manager.acl.save
    end

    it 'copies visibility' do
      expect { propagator.propagate }
        .to change { queries.find_child_filesets(resource: work).map(&:visibility) }
        .to contain_exactly(work.visibility, work.visibility)
    end

    it 'applies a copy of the embargo' do
      release_date = work.embargo.embargo_release_date

      expect { propagator.propagate }
        .to change { queries.find_child_filesets(resource: work).map(&:embargo) }
        .to contain_exactly(have_attributes(embargo_release_date: release_date),
                            have_attributes(embargo_release_date: release_date))
    end
  end

  context 'when work is under lease' do
    let(:work) { FactoryBot.create(:leased_work_with_files).valkyrie_resource }

    before do
      fs = file_sets.first
      fs.visibility = 'restricted'
      fs.permission_manager.acl.save
    end

    it 'copies visibility' do
      expect { propagator.propagate }
        .to change { queries.find_child_filesets(resource: work).map(&:visibility) }
        .to contain_exactly(work.visibility, work.visibility)
    end

    it 'applies a copy of the lease' do
      release_date = work.lease.lease_expiration_date

      expect { propagator.propagate }
        .to change { queries.find_child_filesets(resource: work).map(&:lease) }
        .to contain_exactly(have_attributes(lease_expiration_date: release_date),
                            have_attributes(lease_expiration_date: release_date))
    end
  end
end
