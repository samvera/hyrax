require 'spec_helper'

describe Worthwhile::GenericFile do
  it "should have depositor" do
    subject.depositor = 'tess@example.com'
  end

  describe "to_solr" do
    before do
      subject.title = ['One Flew Over the Cuckoo\'s Nest']
      subject.characterization.metadata.image.height = '500'
      subject.characterization.metadata.image.width = '600'
    end
    let(:solr_doc) { subject.to_solr }

    it "has a solr_doc" do
      expect(solr_doc['desc_metadata__title_tesim']).to eq ['One Flew Over the Cuckoo\'s Nest']
      expect(solr_doc['desc_metadata__title_sim']).to eq ['One Flew Over the Cuckoo\'s Nest']
      expect(solr_doc['height_isi']).to eq 500
      expect(solr_doc['width_isi']).to eq 600
    end
  end


  describe 'with a parent work' do
    let(:parent_pid) { 'pid:123' }
    let!(:parent) {
      if ActiveFedora::Base.exists?(parent_pid)
        ActiveFedora::Base.find(parent_pid).destroy
      end
      GenericWork.new pid: parent_pid, title: ['asdf']
    }

    subject { Worthwhile::GenericFile.create(batch: parent) }

    describe '#remove_representative_relationship' do
      let(:some_other_pid) { 'something:456' }
      before do
        parent.representative = some_other_pid
        parent.save!
      end

      context "the parent object doesn't exist" do
        before do
          parent.representative = subject.pid
          parent.save!
          @parent_pid = parent.pid
          parent.destroy
        end

        it "doesn't raise an error" do
          expect(ActiveFedora::Base.exists?(@parent_pid)).to eq false
          expect {
            subject.remove_representative_relationship
          }.to_not raise_error
        end
      end

      context 'it is not the representative' do
        it "doesn't update parent work when file is deleted" do
          expect(subject.batch).to eq parent
          expect(parent.representative).to eq some_other_pid
          subject.destroy
          expect(parent.representative).to eq some_other_pid
        end
      end

      context 'it is the representative' do
        before do
          parent.representative = subject.pid
          parent.save!
        end

        it 'updates the parent work when the file is deleted' do
          expect(subject.batch).to eq parent
          expect(parent.representative).to eq subject.pid
          subject.destroy
          expect(parent.representative).to be_nil
        end
      end
    end
  end

end
