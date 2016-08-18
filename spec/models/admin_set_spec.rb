require 'spec_helper'

RSpec.describe AdminSet, type: :model do
  let(:gf1) { create(:generic_work, user: user) }
  let(:gf2) { create(:generic_work, user: user) }
  let(:gf3) { create(:generic_work, user: user) }

  let(:user) { create(:user) }

  before do
    subject.title = ['Some title']
  end

  describe "#to_solr" do
    let(:admin_set) { build(:admin_set, title: ['A good title']) }
    let(:solr_document) { admin_set.to_solr }

    it "has title information" do
      expect(solr_document).to include 'title_tesim' => ['A good title'],
                                       'title_sim' => ['A good title']
    end
  end

  describe "#members" do
    it "is empty by default" do
      expect(subject.members).to be_empty
    end

    context "adding members" do
      context "using assignment" do
        subject { described_class.create!(title: ['Some title'], members: [gf1, gf2]) }

        it "has many files" do
          expect(subject.reload.members).to match_array [gf1, gf2]
        end
      end

      context "using append" do
        before do
          subject.members = [gf1]
          subject.save
        end
        it "allows new files to be added" do
          subject.reload
          subject.members << gf2
          subject.save
          expect(subject.reload.members).to match_array [gf1, gf2]
        end
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
end
