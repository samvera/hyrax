require 'spec_helper'

describe RoleMapper do
  it "defines the 4 roles" do
    expect(RoleMapper.role_names.sort).to eq %w(admin_policy_object_editor archivist donor patron researcher)
  end

  describe "#whois" do
    it "knows who is what" do
      expect(RoleMapper.whois('archivist').sort).to eq %w(archivist1@example.com archivist2@example.com leland_himself@example.com)
      expect(RoleMapper.whois('salesman')).to be_empty
      expect(RoleMapper.whois('admin_policy_object_editor').sort).to eq %w(archivist1@example.com)
    end
  end

  describe "fetch_groups" do
    let(:user) { instance_double(User, user_key: email, new_record?: false) } 
    subject { RoleMapper.fetch_groups(user: user) }

    context "for a user with multiple roles" do
      let(:email) { 'leland_himself@example.com' }
      it { is_expected.to match_array ['archivist', 'donor', 'patron'] }

      it "doesn't change its response when it's called repeatedly" do
        expect(subject).to match_array ['archivist', 'donor', 'patron']
        expect(RoleMapper.fetch_groups(user: user)).to match_array ['archivist', 'donor', 'patron']
      end
    end
      
    context "for a user with a single role" do
      let(:email) { 'archivist2@example.com' }
      it { is_expected.to match_array ['archivist'] }
    end

    context "for a user with no roles" do
      let(:email) { 'zeus@olympus.mt' }
      it { is_expected.to be_empty }
    end
  end

  describe "roles" do
    before do
      allow(Deprecation).to receive(:warn)
    end
    it "is quer[iy]able for roles for a given user" do
      expect(RoleMapper.roles('leland_himself@example.com').sort).to eq ['archivist', 'donor', 'patron']
      expect(RoleMapper.roles('archivist2@example.com')).to eq ['archivist']
    end

    context "when called with a user instance" do
      let(:user) { User.new(email: 'leland_himself@example.com') }
      before do
        allow(user).to receive(:new_record?).and_return(false)
      end

      it "doesn't change its response when it's called repeatedly" do
        expect(RoleMapper.roles(user).sort).to eq ['archivist', 'donor', 'patron']
        expect(RoleMapper.roles(user).sort).to eq ['archivist', 'donor', 'patron']
      end
    end

    it "returns an empty array if there are no roles" do
      expect(RoleMapper.roles('zeus@olympus.mt')).to be_empty
    end
  end
end
