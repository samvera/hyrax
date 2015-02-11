require 'spec_helper'

describe Worthwhile::RelatedResourceHelper do

  let(:linked_resource) { FactoryGirl.build(:linked_resource) }
  describe "related_resource_link_name" do
    it "if title is not set, should render the url" do
      expect(related_resource_link_name(linked_resource)).to include(linked_resource.url)
      expect(related_resource_link_name(linked_resource)).to_not have_css("span.secondary")
    end
    it "if title is set, should render title and url with hooks for styling the url" do
      linked_resource.title = ["My Link"]
      expect(related_resource_link_name(linked_resource)).to include(linked_resource.title.first)
      expect(related_resource_link_name(linked_resource)).to have_css("span.secondary", text:linked_resource.url)
    end
  end

end