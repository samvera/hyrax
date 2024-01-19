# frozen_string_literal: true

# NOTE: Valkyrie has it's own factory (Hyrax::PcdmMemberPresenterFactory).
#   This is the legacy ActiveFedora factory.
RSpec.describe Hyrax::MemberPresenterFactory, :active_fedora do
  subject(:factory) { described_class.new(solr_document, ability, request) }

  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) { {} }
  let(:ability) { double }
  let(:request) { double }
  let(:presenter_class) { double }

  describe "#member_presenters" do
    it 'is empty by default' do
      expect(factory.member_presenters).to be_empty
    end

    it 'is empty when requested ids do not exist' do
      expect(factory.member_presenters(['fake', 'fake2'])).to be_empty
    end

    it 'builds presenters for the object ids passed in' do
      ids = FactoryBot.create_list(:work, 2).map(&:id)

      expect(factory.member_presenters(ids))
        .to contain_exactly(*ids.map { |id| have_attributes(id: id) })
    end

    context 'with members' do
      let(:work) { FactoryBot.create(:work_with_file_and_work) }
      let(:attributes) { work.to_solr }

      it 'builds presenters for the memebers' do
        expect(factory.member_presenters)
          .to contain_exactly(*work.member_ids.map { |id| have_attributes(id: id) })
      end
    end
  end

  describe "#file_set_presenters" do
    describe "getting presenters from factory" do
      # rubocop:disable RSpec/SubjectStub
      before do
        allow(factory).to receive(:composite_presenter_class).and_return(presenter_class)
        allow(factory).to receive(:ordered_ids).and_return(['12', '33'])
        allow(factory).to receive(:file_set_ids).and_return(['33', '12'])
      end
      # rubocop:enable RSpec/SubjectStub

      it "uses the set class" do
        expect(Hyrax::PresenterFactory).to receive(:build_for)
          .with(ids: ['12', '33'],
                presenter_class: presenter_class,
                presenter_args: [ability, request])
        factory.file_set_presenters
      end
    end
  end
end
