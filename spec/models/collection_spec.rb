require 'spec_helper'

describe Collection, type: :model do
  let(:gf1) { create(:generic_work, user: user) }
  let(:gf2) { create(:generic_work, user: user) }
  let(:gf3) { create(:generic_work, user: user) }

  let(:user) { FactoryGirl.create(:user) }

  before do
    subject.title = ['Some title']
    subject.apply_depositor_metadata(user)
  end

  describe "#to_solr" do
    let(:collection) { FactoryGirl.build(:collection, user: user, title: ['A good title']) }

    let(:solr_document) { collection.to_solr }

    it "has title information" do
      expect(solr_document).to include 'title_tesim' => ['A good title'],
                                       'title_sim' => ['A good title']
    end

    it "has depositor information" do
      expect(solr_document).to include 'depositor_tesim' => [user.user_key],
                                       'depositor_ssim' => [user.user_key]
    end

    context "with members" do
      before do
        collection.members << gf1
      end
    end
  end

  describe "#depositor" do
    before do
      subject.apply_depositor_metadata(user)
    end

    it "has a depositor" do
      expect(subject.depositor).to eq(user.user_key)
    end
  end

  describe "the ability" do
    let(:collection) { described_class.create(title: ['Some title']) { |c| c.apply_depositor_metadata(user) } }

    let(:ability) { Ability.new(user) }

    it "allows the depositor to edit and read" do
      expect(ability.can?(:read, collection)).to be true
      expect(ability.can?(:edit, collection)).to be true
    end
  end

  describe "#members_objects" do
    before do
      subject.save
    end
    it "is empty by default" do
      expect(subject.member_objects).to match_array []
    end

    context "adding members" do
      it "allows multiple files to be added" do
        subject.add_member_objects [gf1.id, gf2.id, gf3.id]
        subject.save
        expect(subject.reload.member_objects).to match_array [gf1, gf2, gf3]
      end
    end
  end

  it "has a title" do
    subject.title = ["title"]
    subject.save
    expect(subject.reload.title).to eq ["title"]
  end

  it "has a description" do
    subject.title = ["title"]
    subject.description = ["description"]
    subject.save
    expect(subject.reload.description).to eq ["description"]
  end

  describe "#destroy" do
    before do
      subject.members = [gf1, gf2]
      subject.save
      subject.destroy
    end

    it "does not delete member files when deleted" do
      expect(GenericWork.exists?(gf1.id)).to be true
      expect(GenericWork.exists?(gf2.id)).to be true
    end
  end

  describe "Collection by another name" do
    before do
      class OtherCollection < ActiveFedora::Base
        include CurationConcerns::Collection
      end

      class Member < ActiveFedora::Base
        include Hydra::Works::WorkBehavior
      end
    end
    after do
      Object.send(:remove_const, :OtherCollection)
      Object.send(:remove_const, :Member)
    end

    let(:member) { Member.create }
    let(:collection) { OtherCollection.create }

    before do
      collection.add_member_objects member.id
    end

    it "have members that know about the collection" do
      member.reload
      expect(member.member_of_collections).to eq [collection]
    end
  end
end
