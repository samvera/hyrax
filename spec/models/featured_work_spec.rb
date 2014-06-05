require 'spec_helper'

describe FeaturedWork do
  let(:feature) { FeaturedWork.create(generic_file_id:"99") }

  it "should have a file" do
    expect(feature.generic_file_id).to eq "99"
  end

  it "should not allow six features" do
    5.times do |n|
      expect(FeaturedWork.create(generic_file_id:n.to_s)).to_not be_new_record 
    end
    FeaturedWork.create(generic_file_id:"6").tap do |sixth|
      expect(sixth).to be_new_record 
      expect(sixth.errors.full_messages).to eq ["Limited to 5 featured works."]
    end
    expect(FeaturedWork.count).to eq 5
  end

  describe "can_create_another?" do
    subject { FeaturedWork }
    context "when none exist" do
      its(:can_create_another?) { should be true }
    end
    context "when five exist" do
      before do
        5.times do |n|
          FeaturedWork.create(generic_file_id:n.to_s)
        end
      end
      its(:can_create_another?) { should be false }
    end
  end

  describe "#order" do
    subject { FeaturedWork.new(order: 5) }
    its(:order) {should eq 5 }
  end
end


