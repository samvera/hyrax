require 'spec_helper'

describe Hydra::AccessControls::Visibility do
  module VisibilityOverride
    extend ActiveSupport::Concern
    include Hydra::AccessControls::Permissions
    def visibility; super; end
    def visibility=(value); super(value); end
  end
  class MockParent < ActiveFedora::Base
    include VisibilityOverride
  end

  describe "setting visibility" do
    before do
      class Foo < ActiveFedora::Base
        include Hydra::AccessControls::Permissions
      end
    end

    after { Object.send(:remove_const, :Foo) }

    subject { Foo.new }

    [ Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE,
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED,
      Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC ]
    .each do |vis|

      describe "to #{vis}" do

        before { subject.visibility=vis }

        it "should be set to #{vis}" do
          expect(subject.visibility).to eql vis
        end

        describe "and then to private" do
          before { subject.visibility=Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
          it "should be set to private" do
            expect(subject.visibility).to eql Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
          end
          it "should have no permissions" do
            expect(subject.permissions.map(&:to_hash)).to be_empty
          end
        end

        describe "and then to authenticated" do
          before { subject.visibility=Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED }
          it "should be set to authenticated" do
            expect(subject.visibility).to eql Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
          end
          it "should have authenticated permissions only" do
            expect(subject.permissions.map(&:to_hash)).to match_array [
                {type: "group", access: "read", name: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED } ]
          end
        end

        describe "and then to public" do
          before { subject.visibility=Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC }
          it "should be set to public" do
            expect(subject.visibility).to eql Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
          end
          it "should have public permissions only" do
            expect(subject.permissions.map(&:to_hash)).to match_array [
                {type: "group", access: "read", name: Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC } ]
          end
        end
      end

    end

  end

  it 'allows for overrides of visibility' do
    expect{
      MockParent.new(visibility: Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE)
    }.to_not raise_error
  end
end
