require 'spec_helper'

describe Sufia::Messages do

  let(:message) do
    TestClass.new
  end

  before do
    class TestClass
      include Sufia::Messages
    end
  end

  after do
    Object.send(:remove_const, :TestClass)
  end

  let(:batch_id)  { "1" }
  let(:single)    { double(noid: "1", to_s: "File 1") }
  let(:multiple)  { [ double(noid: "1", to_s: "File 1"), double(noid: "2", to_s: "File 2"), double(noid: "3", to_s: "File 3") ] }
  let(:file_list) { "<a href='/files/1'>File 1</a>, <a href='/files/2'>File 2</a>, <a href='/files/3'>File 3</a>"  }

  describe "message subjects" do
    it "should provide a subject for a success message" do
      expect(message.success_subject).to eq("Batch upload complete")
    end
    it "should provide a subject for a failure message" do
      expect(message.failure_subject).to eq("Batch upload permission denied")
    end
  end

  describe "#single_success" do
    let(:expected) { '<span id="ss-1"><a href="/files/1">File 1</a> has been saved.</span>' }
    it "should render a success message for a single file" do
      expect(message.single_success(batch_id, single)).to eq(expected)
    end
  end

  describe "#multiple_success" do
    let(:expected) { '<span id="ss-1"><a rel="popover" data-content="'+file_list+'" data-title="Files uploaded successfully" href="#">These files</a> have been saved.</span>' }
    it "should render a success message for multiple files" do
      expect(message.multiple_success(batch_id, multiple)).to eq(expected)
    end
  end

  describe "#single_failure" do
    let(:expected) { '<span id="ss-1"><a href="/files/1">File 1</a> could not be updated. You do not have sufficient privileges to edit it.</span>' }
    it "should render a failure message for a single file" do
      expect(message.single_failure(batch_id, single)).to eq(expected)
    end
  end

  describe "#multiple_failure" do
    let(:expected) { '<span id="ss-1"><a rel="popover" data-content="'+file_list+'" data-title="Files failed" href="#">These files</a> could not be updated. You do not have sufficient privileges to edit them.</span>' }
    it "should render a failure message for multiple files" do
      expect(message.multiple_failure(batch_id, multiple)).to eq(expected)
    end
  end

  describe "#file_list" do
    it "should replace double-quotes with single quotes" do
      expect(message.file_list(multiple)).to eq(file_list)
    end
  end

end
