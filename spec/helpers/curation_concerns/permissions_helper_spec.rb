require 'spec_helper'

describe CurationConcerns::PermissionsHelper do
  describe "#help_link" do
    subject { helper.help_link 'curation_concerns/base/visibility', 'Visibility', 'Usage information for visibility' }

    it "draws help_icon" do
      expect(subject).to match(/data-content="<p>This setting will determine who can view your file/)
      expect(subject).to have_selector 'a i.help-icon'
    end
  end
end
