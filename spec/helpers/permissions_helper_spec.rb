require 'spec_helper'

describe Sufia::PermissionsHelper do
  describe "#visibility_help" do
    subject { helper.visibility_help }

    it "draws help_icon" do
      expect(subject).to match(/data-content="<p>This setting will determine who can view your file/)
      expect(subject).to have_selector 'a i.help-icon'
    end
  end

  describe "#share_with_help" do
    subject { helper.share_with_help }

    it "draws help_icon" do
      expect(subject).to match(/data-content="<p>You may grant &quot;View\/Download/)
      expect(subject).to have_selector 'a i.help-icon'
    end
  end
end
