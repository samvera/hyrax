require 'spec_helper'

describe Hydra::ModelMethods do

  before do
    allow(Deprecation).to receive(:warn)
    class TestModel < ActiveFedora::Base
      include Hydra::AccessControls::Permissions
      include Hydra::ModelMethods
      property :depositor, predicate: ::RDF::URI.new("http://id.loc.gov/vocabulary/relators/dpt"), multiple: false
      attr_accessor :label
    end
  end

  after { Object.send(:remove_const, :TestModel) }

  subject { TestModel.new }

  describe 'add_file' do
    let(:file_name) { "my_file.foo" }
    let(:mock_file) { "File contents" }

    it "should set the dsid, mimetype and content" do
      expect(subject).to receive(:set_title_and_label).with(file_name, only_if_blank: true )
      expect(MIME::Types).to receive(:of).with(file_name).and_return([double(content_type: "mymimetype")])
      subject.add_file(mock_file, 'bar', file_name)
      expect(subject.bar.content).to eq mock_file
    end

    it "should accept a supplied mime_type and content" do
      expect(subject).to receive(:set_title_and_label).with(file_name, only_if_blank: true )
      subject.add_file(mock_file, 'bar', file_name, 'image/png')
      expect(subject.bar.content).to eq mock_file
    end
  end

  describe '#set_title_and_label' do
    context 'when only_if_blank is true' do
      before do
        subject.label = initial_label
        subject.set_title_and_label('second', only_if_blank: true)
      end

      context 'and label is already set' do
        let(:initial_label) { 'first' }
        it "should not update the label" do
          expect(subject.label).to eq 'first'
        end
      end

      context 'and label is not already set' do
        let(:initial_label) { nil }
        it "should not update the label" do
          expect(subject.label).to eq 'second'
        end
      end
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
