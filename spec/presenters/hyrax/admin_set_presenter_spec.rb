RSpec.describe Hyrax::AdminSetPresenter do
  let(:admin_set) do
    mock_model(AdminSet,
               id: '123',
               description: ['An example admin set.'],
               title: ['Example Admin Set Title'])
  end

  let(:work) { build(:work, title: ['Example Work Title']) }
  let(:solr_document) { SolrDocument.new(admin_set.to_solr) }
  let(:ability) { double }
  let(:presenter) { described_class.new(solr_document, ability) }

  describe "total_items" do
    subject { presenter.total_items }

    let(:admin_set) { build(:admin_set) }

    context "empty admin set" do
      it { is_expected.to eq 0 }
    end

    context "admin set with work" do
      let(:admin_set) { create(:admin_set, members: [work]) }

      it { is_expected.to eq 1 }
    end
  end

  describe "disable_delete?" do
    subject { presenter.disable_delete? }

    context "empty admin set" do
      let(:admin_set) { create(:admin_set) }

      it { is_expected.to be false }
    end

    context "non-empty admin set" do
      let(:admin_set) { create(:admin_set, members: [work]) }

      it { is_expected.to be true }
    end

    context "default admin set" do
      let(:admin_set) do
        build(:admin_set, id: AdminSet::DEFAULT_ID)
      end

      it { is_expected.to be true }
    end
  end

  describe '#collection_type' do
    let(:admin_set) do
      build(:admin_set, id: AdminSet::DEFAULT_ID)
    end

    subject { presenter.collection_type }

    it { is_expected.to eq(create(:admin_set_collection_type)) }
  end

  describe '#show_path' do
    let(:admin_set) do
      build(:admin_set, id: 'sb397824g')
    end

    subject { presenter.show_path }

    it { is_expected.to eq "/admin/admin_sets/#{admin_set.id}?locale=en" }
  end

  describe '#managed_access' do
    let(:admin_set) { create(:admin_set, members: [work]) }

    context 'when manager' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_document).and_return(true)
      end
      it 'returns Manage label' do
        expect(presenter.managed_access).to eq 'Manage'
      end
    end

    context 'when depositor' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_document).and_return(false)
        allow(ability).to receive(:can?).with(:deposit, solr_document).and_return(true)
      end
      it 'returns Deposit label' do
        expect(presenter.managed_access).to eq 'Deposit'
      end
    end

    context 'when viewer' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_document).and_return(false)
        allow(ability).to receive(:can?).with(:deposit, solr_document).and_return(false)
        allow(ability).to receive(:can?).with(:read, solr_document).and_return(true)
      end
      it 'returns View label' do
        expect(presenter.managed_access).to eq 'View'
      end
    end
  end

  describe '#allow_batch?' do
    let(:admin_set) { create(:admin_set, members: [work]) }

    context 'when user cannot edit' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_document).and_return(false)
      end

      it 'returns false' do
        expect(presenter.allow_batch?).to be false
      end
    end

    context 'when user can edit' do
      before do
        allow(ability).to receive(:can?).with(:edit, solr_document).and_return(true)
      end

      context 'and there are works in the admin set' do
        it 'returns false' do
          expect(presenter.allow_batch?).to be false
        end
      end

      context 'and there are no works in the admin set' do
        before do
          allow(presenter).to receive(:total_items).and_return(0)
        end

        it 'returns true' do
          expect(presenter.allow_batch?).to be true
        end
      end
    end
  end
end
