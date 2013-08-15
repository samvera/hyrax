require 'spec_helper'

describe Hydra::Datastream::RightsMetadata do
  before :all do
    class RightsTest < ActiveFedora::Base
      include Hydra::ModelMixins::RightsMetadata
      has_metadata name: 'rightsMetadata', type: Hydra::Datastream::RightsMetadata
    end
  end

  after :all do
    Object.send(:remove_const,:RightsTest)
  end

  describe "rightsMetadata" do
    let!(:thing) {RightsTest.new}

    [:discover,:read,:edit].each do |mode|
      describe "##{mode}_users" do
        let(:get_method) {"#{mode}_users".to_sym}
        let(:set_method) {"#{mode}_users=".to_sym}

        before :each do
          thing.send(set_method, ['locutus@borg.collective.mil'])
          thing.save
        end

        it "should persist initial setting" do
          thing.reload.send(get_method).should == ['locutus@borg.collective.mil']
        end

        it "should persist changes" do
          thing.send(set_method, ['locutus@borg.collective.mil','sevenofnine@borg.collective.mil'])
          thing.save
          thing.reload.send(get_method).should =~ ['locutus@borg.collective.mil','sevenofnine@borg.collective.mil']
        end

        it "should persist emptiness" do
          thing.send(set_method, [])
          thing.save
          thing.reload.send(get_method).should == []
        end
      end

      describe "##{mode}_groups" do
        let(:get_method) {"#{mode}_groups".to_sym}
        let(:set_method) {"#{mode}_groups=".to_sym}

        before :each do
          thing.send(set_method, ['borg'])
          thing.save
        end

        it "should persist initial setting" do
          thing.reload.send(get_method).should == ['borg']
        end

        it "should persist changes" do
          thing.send(set_method, ['borg','federation'])
          thing.save
          thing.reload.send(get_method).should =~ ['borg','federation']
        end

        it "should persist emptiness" do
          thing.send(set_method, [])
          thing.save
          thing.reload.send(get_method).should == []
        end
      end
    end
  end
end
