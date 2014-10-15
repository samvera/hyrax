require 'spec_helper'

describe "WithAccessRight" do

  before do
    class TestClass < ActiveFedora::Base
      include Hydra::AccessControls::Permissions
      include Hydra::AccessControls::WithAccessRight
    end
  end

  after do
    Object.send(:remove_const, :TestClass)
  end

  subject { TestClass.new }

  context "not persisted" do
    context "when it is public" do
      before { subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC}
      its(:authenticated_only_access?) { should be false}
      its(:private_access?) { should be false}
      its(:open_access?) { should be true}
      its(:open_access_with_embargo_release_date?) { should be false}
    end

    context "when it is private" do
      before { subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE }
      its(:authenticated_only_access?) { should be false}
      its(:private_access?) { should be true}
      its(:open_access?) { should be false}
      its(:open_access_with_embargo_release_date?) { should be false}
    end
  end

  context "persisted" do
    before { allow(subject).to receive(:persisted?).and_return(true) }
    context "when it is public" do
      before do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
      end
      its(:authenticated_only_access?) { should be false}
      its(:private_access?) { should be false}
      its(:open_access?) { should be true}
      its(:open_access_with_embargo_release_date?) { should be false}
    end

    context "when it is private" do
      before do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
      end
      its(:authenticated_only_access?) { should be false}
      its(:private_access?) { should be true}
      its(:open_access?) { should be false}
      its(:open_access_with_embargo_release_date?) { should be false}
    end

    context "when it is authenticated access" do
      before do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
      end
      its(:authenticated_only_access?) { should be true}
      its(:private_access?) { should be false}
      its(:open_access?) { should be false}
      its(:open_access_with_embargo_release_date?) { should be false}
    end
  end

end
