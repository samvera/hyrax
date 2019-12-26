# frozen_string_literal: true
RSpec.configure do |config|
  config.before(:each, clean_index: true) do
    client = Valkyrie::IndexingAdapter.find(:solr_index).connection
    client.delete_by_query("*:*", params: { softCommit: true })
  end
end
