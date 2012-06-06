require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
require "nokogiri"

describe Hydra::Datastream::ModsBasic do
  
  context "general behaviors" do
    subject { Hydra::Datastream::ModsBasic.new(nil, nil) }

    it "should be a kind of ActiveFedora::NokogiriDatastream" do
      subject.should be_kind_of(ActiveFedora::NokogiriDatastream)
    end
    
    it "should include mods name behaviors" do
      subject.class.included_modules.should include(Hydra::Datastream::CommonModsIndexMethods)
      subject.should respond_to(:extract_person_full_names)
    end
    
    it "should have relator terms translation methods specific to this model" do
      subject.class.should respond_to(:person_relator_terms)
      subject.class.should respond_to(:conference_relator_terms)
      subject.class.should respond_to(:organization_relator_terms)
      subject.class.should respond_to(:dc_relator_terms)
    end
  end
  
  MODS_NS = 'http://www.loc.gov/mods/v3'

  context "creating new mods xml" do
    subject { Hydra::Datastream::ModsBasic.new(nil, nil) }
    
    it "should have an xml_template method returning desired xml" do
      empty_xml = subject.class.xml_template
      empty_xml.should be_a_kind_of(Nokogiri::XML::Document)
      root = empty_xml.root
      root.namespace.href.should == MODS_NS
      root.get_attribute("schemaLocation").end_with?("http://www.loc.gov/standards/mods/v3/mods-3-3.xsd").should be_true
      root.get_attribute("version").should == "3.3"
      # looking at one single descendant node; more may be indicated
      title = root.at_xpath('mods:titleInfo/mods:title',  {'mods' => MODS_NS} )
      title.should_not be_nil
      title.text.should == ""
    end
  end

  
  context "reading existing Mods xml" do
    subject { Hydra::Datastream::ModsBasic.from_xml(fixture("example_mods.xml")) }
    
    it "should get correct values from OM terminology" do
      tests = [
        [:main_title, 'main title'],
        [[:title_info, :subtitle], 'subtitle'],

        [:abstract, 'abstract'],

#        [[:subject, :topic],  ['topic 1', 'topic 2', 'authority controlled topic']],
#        [:topic_tag,          ['topic 1', 'topic 2', 'authority controlled topic']],

        [:identifier, ['http://projecthydra.org/testdata/', 'doi:10.1006/jmbi.1995.0238']],
        [:doi, 'doi:10.1006/jmbi.1995.0238'],
        [:uri, 'http://projecthydra.org/testdata/'],

        [[:name, :namePart], ['Hydra', 'Hubert', 'some conference']],
        [[:name, :last_name], 'Hydra'],
        [[:person, :last_name], 'Hydra'],
        [[:name, :first_name], 'Hubert'],
        [[:person, :first_name], 'Hubert'],
#        [:role, ['Creator', 'Host']],
#        [:person, 'Hydra Hubert Project Hydra Creator'],
#        [:conference, 'some conference Host'],
      ]

      tests.each do |terms, exp|
        terms = [terms] unless terms.class == Array
        exp   = [exp]   unless exp.class == Array
        subject.term_values(*terms).should == exp
      end
    end
  end
=begin  
  context "updating Mods xml" do
    it "should do something" do
      pending "to be implemented"
    end
    it "should be able to insert new name nodes" do
      pending "test to be implemented"
    end
    it "should be able to add additional topics" do
      pending "to be implemented"
    end
    it "should be able to remove nodes, including the last of a node" do
      pending "to be implemented"
    end
  end
=end    
end
