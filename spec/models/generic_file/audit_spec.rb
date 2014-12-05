require 'spec_helper'

describe "generic file audits" do
  let(:f) do
    gf = GenericFile.new
    gf.add_file(File.open(fixture_path + '/world.png'), 'content', 'world.png')
    gf.apply_depositor_metadata('mjg36')
    gf.save!
    gf
  end

  context "force an audit on a file" do 
    specify "should return a list of log results" do
      logs = f.audit(true)
      expect(logs).to_not be_empty
    end
  end

  context "force an audit on a specific versio" do 
    specify "should return a log result" do
      log = f.audit_each(f.content.versions[0], true)
      expect(log).to_not be_nil
    end
  end
end
