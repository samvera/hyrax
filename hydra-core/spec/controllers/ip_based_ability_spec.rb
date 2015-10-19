require 'spec_helper'

describe 'IpBasedAbilitySpec' do
  controller do
    include Hydra::Controller::IpBasedAbility
  end

  describe '#ability' do
    let(:user) { double }
    let(:ip) { '123.456.789.111' }

    before do
      allow(controller).to receive(:current_user).and_return(user)
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_ip) { ip }
    end

    it 'passes ip to ability' do
      expect(Ability).to receive(:new).with(user, remote_ip: ip)
      controller.current_ability
    end
  end
end
