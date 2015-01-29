require 'spec_helper'

describe Hydra::ModelMethods do

  before do
    allow(Deprecation).to receive(:warn)
    class TestModel < ActiveFedora::Base
      include Hydra::AccessControls::Permissions
      include Hydra::ModelMethods
      property :depositor, predicate: ::RDF::URI.new("http://id.loc.gov/vocabulary/relators/dpt"), multiple: false
    end
  end

  after { Object.send(:remove_const, :TestModel) }

  subject { TestModel.new }

  describe 'add_file' do
    let(:file_name) { "my_file.foo" }
    let(:mock_file) { "File contents" }

    it "should set the dsid, mimetype and content" do
      expect(subject).to receive(:add_file_datastream).with(mock_file, label: file_name, mime_type: "mymimetype", dsid: 'bar', original_name: file_name)
      expect(subject).to receive(:set_title_and_label).with(file_name, only_if_blank: true )
      expect(MIME::Types).to receive(:of).with(file_name).and_return([double(content_type: "mymimetype")])
      subject.add_file(mock_file, 'bar', file_name)
    end

    it "should accept a supplied mime_type and content" do
      expect(subject).to receive(:add_file_datastream).with(mock_file, label: file_name, mime_type: "image/png", dsid: 'bar', original_name: file_name)
      expect(subject).to receive(:set_title_and_label).with(file_name, only_if_blank: true )
      subject.add_file(mock_file, 'bar', file_name, 'image/png')
    end
  end

  describe '#set_title' do
    context "on a class with a title property" do
      before do
        expect(Deprecation).to receive(:warn)
        class WithProperty < ActiveFedora::Base
          include Hydra::ModelMethods
          property :title, predicate: ::RDF::DC.title
        end
      end

      subject { WithProperty.new }

      it "should set the property" do
        subject.set_title('foo')
        expect(subject.title).to eq ['foo']
      end
    end
  end
end
