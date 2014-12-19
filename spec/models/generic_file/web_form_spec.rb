require 'spec_helper'

describe GenericFile, :type => :model do
  before do
    subject.apply_depositor_metadata('jcoyne')
  end

  describe "accessible_attributes" do
    it "should have a list" do
      expect(subject.accessible_attributes).to include(:part_of, :resource_type, :title, :creator, :contributor, :description,
        :tag, :rights, :publisher, :date_created, :subject, :language, :identifier, :based_near, :related_url, :permissions_attributes)
    end

    it "should sanitize them" do
      expect(subject.sanitize_attributes({'part_of' => 'A book', 'something_crazy' => "get's thrown out"})).to eq(
        {'part_of' => 'A book'}
      )
    end
  end
end
