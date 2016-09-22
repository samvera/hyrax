require 'spec_helper'

describe 'curation_concerns/permissions/confirm.html.erb' do
  before do
    allow(curation_concern).to receive(:to_param).and_return('test:123')
    allow(view).to receive(:curation_concern).and_return(curation_concern)
    render
  end

  context 'when the work is embargoed' do
    let(:curation_concern) { build(:embargoed_work, embargo_date: '2099-09-26'.to_date) }

    it 'has a message about embargos' do
      expect(rendered).to have_content "You've applied an embargo to this Generic Work, Test title, changing its visibility to Private until September 26th, 2099. Would you like to apply the same embargo to all of the files within the Generic Work as well?"
    end
  end

  context 'when the work is leased' do
    let(:curation_concern) { build(:leased_work, lease_date: '2099-09-26'.to_date) }

    it 'has a message about leases' do
      expect(rendered).to have_content "You've applied a lease to this Generic Work, Test title, changing its visibility to Open Access until September 26th, 2099. Would you like to apply the same lease to all of the files within the Generic Work as well?"
    end
  end

  context 'when the work is not embargoed' do
    let(:curation_concern) { build(:work) }

    it 'has a message about visibility' do
      expect(rendered).to have_content "You've changed the permissions on this Generic Work, Test title, making it visible to Private. Would you like change all of the files within the Generic Work to Private as well?"
    end
  end
end
