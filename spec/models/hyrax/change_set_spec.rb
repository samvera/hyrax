# frozen_string_literal: true

RSpec.describe Hyrax::ChangeSet do
  subject(:change_set) { described_class.for(resource) }
  let(:resource)       { resource_class.new }
  let(:resource_class) { Hyrax::Test::BookResource }
  let(:titles)         { ['comet in moominland', 'finn family moomintroll'] }

  it 'changes when changed' do
    expect { change_set.title = titles }
      .to change { change_set.changed? }
      .from(false)
      .to(true)
  end

  it 'sets changeset attributes' do
    expect { change_set.title = titles }
      .to change { change_set.title }
      .to contain_exactly(*titles)
  end

  it 'applies changeset attributes' do
    change_set.title = titles

    expect { change_set.sync }
      .to change { resource.title }
      .to contain_exactly(*titles)
  end
end
