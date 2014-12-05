require 'spec_helper'

describe "generic file audits" do
  let(:f) do
    gf = GenericFile.new
    gf.add_file('hello one', 'content', 'hello1.txt')
    gf.apply_depositor_metadata('mjg36')
    gf.save!

    # force a second version
    gf = GenericFile.find(gf.id)
    gf.add_file('hello two', 'content', 'hello2.txt')
    gf.save!

    gf
  end

  context "force an audit on a file with two versions" do 
    specify "should return two log results" do
      logs = f.audit(true)
      expect(logs.length).to eq(2)
    end
  end

  context "force an audit on a specific version" do 
    specify "should return a single log result" do
      log = f.audit_each(f.content.versions[0], true)
      expect(log).to_not be_nil
    end
  end
end
