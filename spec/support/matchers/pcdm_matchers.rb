# frozen_string_literal: true
RSpec::Matchers.define :have_file_set_members do
  match do |actual|
    expect(Hyrax.custom_queries.find_child_filesets(resource: actual)).not_to be_empty
  end
end
