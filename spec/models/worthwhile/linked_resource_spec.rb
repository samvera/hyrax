require 'spec_helper'

describe Worthwhile::LinkedResource do
  subject { Worthwhile::LinkedResource.new }

  it { should respond_to(:human_readable_type) }

  it 'has a #human_readable_short_description' do
    expect(subject.human_readable_short_description.length).to_not eq 0
  end

  it 'has a .human_readable_short_description' do
    expect(subject.class.human_readable_short_description.length).to_not eq 0
  end

  it 'uses #noid for #to_param' do
    allow(subject).to receive(:persisted?).and_return(true)
    expect(subject.to_param).to eq subject.noid
  end

  it 'has no url to display' do
    expect(subject.to_s).to eq nil
  end

  describe "to_s" do
    it "if title is not set, returns the url" do
      subject.url = 'http://www.youtube.com/watch?v=oHg5SJYRHA0'
      expect(subject.to_s).to eq('http://www.youtube.com/watch?v=oHg5SJYRHA0')
    end
    it "if title is set, returns the title" do
      subject.url = 'http://www.youtube.com/watch?v=oHg5SJYRHA0'
      subject.title = "My Link Title"
      expect(subject.to_s).to eq("My Link Title")
    end
  end

  describe "validating" do
    subject {Worthwhile::LinkedResource.new}
    it "should not validate and have an error" do
      expect(subject).to_not be_valid
      expect(subject.errors[:url]).to eq ["can't be blank"]
    end
  end

  describe "sanitizing" do
    context "javascript uri" do
      subject { FactoryGirl.build(:linked_resource, url: "javascript:void(alert('Hello'));") }
      it "should be cleared" do
        expect(subject.url).to be_nil
      end
    end
    context "http uri" do
      subject { FactoryGirl.build(:linked_resource, url: "http://www.youtube.com/watch?v=oHg5SJYRHA0") }
      it "should be stored" do
        expect(subject.to_s).to eq 'http://www.youtube.com/watch?v=oHg5SJYRHA0'
      end
    end
    context "https uri" do
      subject { FactoryGirl.build(:linked_resource, url: "https://www.youtube.com/watch?v=oHg5SJYRHA0") }
      it "should be stored" do
        expect(subject.to_s).to eq 'https://www.youtube.com/watch?v=oHg5SJYRHA0'
      end
    end
    context "ftp uri" do
      subject { FactoryGirl.build(:linked_resource, url: "ftp://ftp.ed.ac.uk") }
      it "should be stored" do
        expect(subject.to_s).to eq 'ftp://ftp.ed.ac.uk/'
      end
    end
  end

  context '#to_solr' do
    subject { Worthwhile::LinkedResource.new(url: 'http://www.youtube.com/watch?v=oHg5SJYRHA0') }
    it 'should solrize its url' do
      expect(subject.to_solr.fetch('url_tesim')).to eq(['http://www.youtube.com/watch?v=oHg5SJYRHA0'])
    end
  end

  describe "with a persisted resource" do
    let!(:resource) { FactoryGirl.create(:linked_resource, url: 'http://www.youtube.com/watch?v=oHg5SJYRHA0') }

    it 'has url as its title to display' do
      expect(resource.to_s).to eq 'http://www.youtube.com/watch?v=oHg5SJYRHA0'
    end

  end

end