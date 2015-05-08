require 'spec_helper'

describe GenericWork do

  describe ".properties" do
    subject { described_class.properties.keys }
    it { is_expected.to include("has_model", "create_date", "modified_date") }
  end

  describe "basic metadata" do
    it "should have dc properties" do
      subject.title = ['foo', 'bar']
      expect(subject.title).to eq ['foo', 'bar']
    end
  end

  describe "associations" do
    let(:file) { GenericFile.new.tap {|gf| gf.apply_depositor_metadata("user")} }
    context "base model" do
      subject { GenericWork.create(title: ['test'], files: [file]) }

      it "should have many generic files" do
        expect(subject.files).to eq [file]
      end
    end

    context "sub-class" do
      before do
        class TestWork < GenericWork
        end
      end

      subject { TestWork.create(title: ['test'], files: [file]) }

      it "should have many generic files" do
        expect(subject.files).to eq [file]
      end
    end
  end

  describe "trophies" do
    before do
      u = FactoryGirl.find_or_create(:jill)
      @w = GenericWork.new.tap do |gw|
        gw.apply_depositor_metadata(u)
        gw.save!
      end
      @t = Trophy.create(user_id: u.id, generic_work_id: @w.id)
    end
    it "should have a trophy" do
      expect(Trophy.where(generic_work_id: @w.id).count).to eq 1
    end
    it "should remove all trophies when work is deleted" do
      @w.destroy
      expect(Trophy.where(generic_work_id: @w.id).count).to eq 0
    end
  end

  describe "#destroy", skip: "Is this behavior we need? Could other works be pointing at the file?" do
    let(:file1) { GenericFile.new.tap {|gf| gf.apply_depositor_metadata("user")} }
    let(:file2) { GenericFile.new.tap {|gf| gf.apply_depositor_metadata("user")} }
    let!(:work) { GenericWork.create(files: [file1, file2]) }

    it "should destroy the files" do
      expect { work.destroy }.to change{ GenericFile.count }.by(-2)
    end
  end

  describe "metadata" do
    it "should have descriptive metadata" do
      expect(subject).to respond_to(:relative_path)
      expect(subject).to respond_to(:depositor)
      expect(subject).to respond_to(:related_url)
      expect(subject).to respond_to(:based_near)
      expect(subject).to respond_to(:part_of)
      expect(subject).to respond_to(:contributor)
      expect(subject).to respond_to(:creator)
      expect(subject).to respond_to(:title)
      expect(subject).to respond_to(:description)
      expect(subject).to respond_to(:publisher)
      expect(subject).to respond_to(:date_created)
      expect(subject).to respond_to(:date_uploaded)
      expect(subject).to respond_to(:date_modified)
      expect(subject).to respond_to(:subject)
      expect(subject).to respond_to(:language)
      expect(subject).to respond_to(:rights)
      expect(subject).to respond_to(:resource_type)
      expect(subject).to respond_to(:identifier)
    end
  end

  describe '#to_solr' do
    let(:collection) { FactoryGirl.create(:collection, title: 'My Collection') }
    let(:work) { FactoryGirl.create(:work, title: ['My Work'], collections: [collection]) }

    subject { work.to_solr }

    it 'indexes the properties' do
      expect(subject['collection_ids_tesim']).to eq [collection.id]
    end
  end

end

