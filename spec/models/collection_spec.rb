require 'spec_helper'

describe Collection do
  let(:reloaded_subject) { Collection.find(subject.pid) }

  it 'can be part of a collection' do
    expect(subject.can_be_member_of_collection?(double)).to be_true
  end


  it 'can contain another collection' do
    another_collection = FactoryGirl.create(:collection)
    subject.members << another_collection
    subject.members.should == [another_collection]
  end

  it 'cannot contain itself' do
    subject.members << subject
    subject.save
    reloaded_subject.members.should == []
  end

  describe "when visibility is private" do
    it "should not be open_access?" do
      subject.should_not be_open_access
    end
    it "should not be authenticated_only_access?" do
      subject.should_not be_authenticated_only_access
    end
    it "should not be private_access?" do
      subject.should be_private_access
    end
  end

  describe "visibility" do
    it "should have visibility accessor" do
      subject.visibility.should == Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
    end
    it "should have visibility writer" do
      subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      subject.should be_open_access
    end
  end

  describe "to_solr on a saved object" do
    let(:solr_doc) {subject.to_solr}
    it "should have a generic_type_sim" do
      solr_doc['generic_type_sim'].should == ['Collection']
    end

  end

  describe '#human_readable_type' do
    it "indicates collection" do
      subject.human_readable_type.should == 'Collection'
    end
  end

  describe '#add_member' do
    it 'adds the member to the collection and returns true' do
      work = FactoryGirl.create(:generic_work, title: 'Work 1')
      subject.add_member(work).should be_true
      reloaded_subject.members.should == [work]

      work.reload
      work.collections.should == [subject]
      work.to_solr["collection_sim"].should == [subject.pid]
    end

    it 'returns false if there is nothing to add' do
      subject.add_member(nil).should be_false
    end

    it 'returns false if it failed to save' do
      subject.save
      work = FactoryGirl.create(:generic_work)
      subject.stub(:save).and_return(false)
      subject.add_member(work).should be_false
      reloaded_subject.members.should == []
    end
  end

  describe '#remove_member' do
    it 'removes the member from the collection and returns true' do
      work = FactoryGirl.create(:generic_work, title: 'Work 2')
      subject.add_member(work)
      subject.members.should == [work]

      work.reload
      work.collections.should == [subject]
      work.to_solr["collection_sim"].should == [subject.pid]

      subject.remove_member(work).should be true
      subject.save!
      reloaded_subject.members.should == []

      work.reload
      work.collections.should == []
      work.to_solr["collection_sim"].should == []
    end

    it 'returns false if there is nothing to delete' do
      subject.remove_member(nil).should be_false
    end

    it 'returns false when trying to delete a member with does not belong to the collection' do
      subject.save
      work = FactoryGirl.create(:generic_work)
      subject.remove_member(work).should be_false
      reloaded_subject.members.should == []
    end
  end

end
