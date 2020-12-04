# frozen_string_literal: true
RSpec::Matchers.define :have_file_set_members do |*expected_file_sets|
  match do |actual_work|
    actual_file_sets = Hyrax.custom_queries.find_child_filesets(resource: actual_work)

    expect(actual_file_sets).to contain_exactly(*expected_file_sets)
  end
end

RSpec::Matchers.define :be_a_resource_with_permissions do |*expected_permissions|
  match do |actual_resource|
    expect(Hyrax::AccessControlList.new(resource: actual_resource).permissions)
      .to include(*expected_permissions)
  end
end
