require 'spec_helper'

describe Hydra::WithDepositor do
  before do
    class TestClass
      include Hydra::WithDepositor
      attr_accessor :edit_users, :depositor
      def initialize
        @edit_users = []
      end
    end
  end

  after { Object.send(:remove_const, :TestClass) }

  subject { TestClass.new }

  describe "#apply_depositor_metadata" do
    it "should add edit access" do
      subject.apply_depositor_metadata('naomi')
      expect(subject.edit_users).to eq ['naomi']
    end

    it "should not overwrite people with edit access" do
      subject.edit_users = ['jessie']
      subject.apply_depositor_metadata('naomi')
      expect(subject.edit_users).to match_array ['naomi', 'jessie']
    end

    it "should set depositor" do
      subject.apply_depositor_metadata('chris')
      expect(subject.depositor).to eq 'chris'
    end

    it "should accept objects that respond_to? :user_key" do
      stub_user = double(:user, user_key: 'monty')
      subject.apply_depositor_metadata(stub_user)
      expect(subject.depositor).to eq 'monty'
    end
  end
end
