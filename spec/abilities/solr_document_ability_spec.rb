require 'cancan/matchers'

# rubocop:disable RSpec/EmptyExampleGroup
RSpec.describe 'SolrDocumentAbility' do
  subject { ability }

  let(:ability) { Ability.new(current_user) }
  let(:user) { create(:user) }
  let(:current_user) { user }

  context 'with Collection solr doc' do
    # tested with collection's solr doc in collection_ability_spec.rb
  end

  context 'with admin_set' do
    # tested with admin_set's solr doc in admin_set_ability_spec.rb
  end

  context 'with works' do
    # TODO: Need tests for works
  end

  context 'with files' do
    # TODO: Need tests for files
  end
end
# rubocop:enable RSpec/EmptyExampleGroup
