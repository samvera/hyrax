# frozen_string_literal: true
module Hyrax
  RSpec.describe TwitterPresenter do
    describe '.twitter_handle_for' do
      let(:user_key) { 'user_key' }

      subject { described_class.twitter_handle_for(user_key: user_key) }

      context "with a found user that has a twitter handle" do
        before { allow(::User).to receive(:find_by_user_key).with(user_key).and_return(user) }
        let(:user) { instance_double(::User, twitter_handle: 'test', user_key: user_key) }

        it { is_expected.to eq '@test' }
      end

      context "with a found user that doesn't have a twitter handle" do
        before { allow(::User).to receive(:find_by_user_key).with(user_key).and_return(user) }
        let(:user) { instance_double(::User, twitter_handle: '', user_key: user_key) }

        it { is_expected.to eq '@SamveraRepo' }
      end

      context "with a user that can't be found" do
        it { is_expected.to eq '@SamveraRepo' }
      end
    end
  end
end
