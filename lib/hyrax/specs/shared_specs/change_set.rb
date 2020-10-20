require 'valkyrie/specs/shared_specs'

RSpec.shared_examples 'a Hyrax::ChangeSet' do
  before do
    raise 'change_set creation requires `let(:resource)`' unless defined? resource
  end

  subject(:changeset)   { described_class.for(resource) }

  it_behaves_like 'a Valkyrie::ChangeSet'
end
