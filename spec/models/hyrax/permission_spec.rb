# frozen_string_literal: true

require 'valkyrie/specs/shared_specs'

RSpec.describe Hyrax::Permission do
  subject(:permission) { described_class.new }
  let(:resource_id)    { Valkyrie::ID.new('fake_resource_id') }
  let(:user_id)        { 'fake_user_id' }

  it_behaves_like 'a Valkyrie::Resource' do
    let(:resource_klass) { described_class }
  end

  describe '#access_to' do
    it 'sets the resource for the policy' do
      expect { permission.access_to = resource_id }
        .to change { permission.access_to }
        .to resource_id
    end
  end

  describe '#agent' do
    it 'sets the agent for the policy' do
      expect { permission.agent = user_id }
        .to change { permission.agent }
        .to user_id
    end
  end

  describe '#mode' do
    it 'sets the mode for the policy' do
      expect { permission.mode = :read }
        .to change { permission.mode }
        .to :read
    end
  end
end
