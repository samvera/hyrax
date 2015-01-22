require 'spec_helper'

describe SolrDocument, type: :model do

  describe "date_uploaded" do
    before do
      subject['date_uploaded_dtsi'] = '2013-03-14T00:00:00Z'
    end
    it "should be a date" do
      expect(subject.date_uploaded).to eq '03/14/2013'
    end
  end

  describe '#to_param' do
    let(:id) { '1v53kn56d' }

    before do
      subject[:id] = id
    end

    it 'returns the object identifier' do
      expect(subject.to_param).to eq id
    end
  end

  describe "document types" do
    class Mimes
      include Sufia::GenericFile::MimeTypes
    end

    context "when mime-type is 'office'" do
      it "should be office document" do
        Mimes.office_document_mime_types.each do |type|
          subject['mime_type_tesim'] = [type]
          expect(subject).to be_office_document
        end
      end
    end

    describe "when mime-type is 'video'" do
      it "should be office" do
        Mimes.video_mime_types.each do |type|
          subject['mime_type_tesim'] = [type]
          expect(subject).to be_video
        end
      end
    end

  end

end
