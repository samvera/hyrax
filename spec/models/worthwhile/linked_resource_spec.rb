require 'spec_helper'

describe Worthwhile::LinkedResource do
  subject { Worthwhile::LinkedResource.new }

  it { should respond_to(:human_readable_type) }

  it 'has a #human_readable_short_description' do
    subject.human_readable_short_description.length.should_not == 0
  end

  it 'has a .human_readable_short_description' do
    subject.class.human_readable_short_description.length.should_not == 0
  end

  it 'uses #noid for #to_param' do
    subject.stub(:persisted?).and_return(true)
    subject.to_param.should == subject.noid
  end

  it 'has no url to display' do
    subject.to_s.should == nil
  end

  describe "validating" do
    subject {Worthwhile::LinkedResource.new}
    it "should not validate and have an error" do
      subject.should_not be_valid
      subject.errors[:url].should == ["can't be blank"]
    end
  end

  describe "sanitizing" do
    context "javascript uri" do
      subject { FactoryGirl.build(:linked_resource, url: "javascript:void(alert('Hello'));") }
      it "should be cleared" do
        subject.url.should be_nil
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
