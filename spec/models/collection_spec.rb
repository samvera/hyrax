RSpec.describe Collection do
  let(:collection) { build(:collection, :public) }
  let(:persister) { Valkyrie.config.metadata_adapter.persister }

  it "has open visibility" do
    expect(collection.read_groups).to eq ['public']
  end

  describe "#depositor" do
    let(:user) { build(:user) }

    before do
      subject.apply_depositor_metadata(user)
    end

    it "has a depositor" do
      expect(subject.depositor).to eq(user.user_key)
    end
  end

  describe "#members_objects", clean_repo: true do
    let(:collection) { create_for_repository(:collection) }

    it "is empty by default" do
      expect(collection.member_objects).to match_array []
    end

    context "adding members" do
      let(:work1) { create_for_repository(:work) }
      let(:work2) { create_for_repository(:work) }

      before do
        collection.add_member_objects [work1.id, work2.id]
        persister.save(resource: collection)
      end

      it "allows multiple files to be added" do
        reloaded = Hyrax::Queries.find_by(id: collection.id)
        expect(reloaded.member_objects.map(&:id)).to match_array [work1, work2].map(&:id)
      end
    end
  end

  describe "Collection by another name" do
    before do
      class OtherCollection < Valkyrie::Resource
        include Hyrax::CollectionBehavior
      end

      class Member < Valkyrie::Resource
        include Hyrax::WorkBehavior
      end
      collection.add_member_objects member.id
    end
    after do
      Object.send(:remove_const, :OtherCollection)
      Object.send(:remove_const, :Member)
    end

    let(:member) { persister.save(resource: Member.new) }
    let(:collection) do
      col = OtherCollection.new(title: ['test title'])
      persister.save(resource: col)
    end

    it "have members that know about the collection", clean_repo: true do
      reloaded = Hyrax::Queries.find_by(id: member.id)
      expect(reloaded.member_of_collection_ids).to eq [collection.id]
    end
  end
end
