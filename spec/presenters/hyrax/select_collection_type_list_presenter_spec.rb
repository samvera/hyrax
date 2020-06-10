# frozen_string_literal: true
RSpec.describe Hyrax::SelectCollectionTypeListPresenter, :clean_repo do
  let(:user) { create(:user) }
  let(:instance) { described_class.new(user) }
  let(:collection_type) { create(:collection_type, creator_user: user) }
  let(:user_collection_type) { create(:user_collection_type) }

  describe "#many?" do
    let(:subject) { instance.many? }

    it "finds only one" do
      expect(subject).to be false
    end

    it "finds many" do
      collection_type
      user_collection_type
      expect(subject).to be true
    end
  end

  describe "#any?" do
    let(:subject) { instance.any? }

    it 'finds no collection types' do
      expect(subject).to be false
    end

    it 'finds a collection type' do
      collection_type
      expect(subject).to be true
    end
  end

  describe "authorized_collection_types" do
    let(:subject) { instance.authorized_collection_types }

    it 'returns an array of Hyrax::CollectionTypes' do
      expect(Hyrax::CollectionTypes::PermissionsService).to receive(:can_create_collection_types).with(user: user).and_return(:the_response)
      expect(subject).to equal(:the_response)
    end
  end

  describe "#first_collection_type" do
    let(:subject) { instance.first_collection_type }

    it 'returns the first collection_type' do
      collection_type
      user_collection_type
      expect(subject).to eq(Hyrax::CollectionType.first)
    end
  end

  describe "#each" do
    it 'iterates through all collection types' do
      expect(Hyrax::CollectionTypes::PermissionsService).to receive(:can_create_collection_types).with(user: user).and_return([:the_response])
      expect { |block| instance.each(&block) }.to yield_successive_args(kind_of(Hyrax::SelectCollectionTypePresenter))
    end
  end
end
