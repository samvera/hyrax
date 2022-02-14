# frozen_string_literal: true
RSpec::Matchers.define :have_file_set_members do |*expected_file_sets|
  match do |actual_work|
    actual_file_sets = Hyrax.custom_queries.find_child_file_sets(resource: actual_work)

    expect(actual_file_sets).to contain_exactly(*expected_file_sets)
  end
end

RSpec::Matchers.define :have_attached_files do |*expected_files|
  match do |actual_file_set|
    @actual_files = Hyrax.custom_queries.find_files(file_set: actual_file_set)

    (expected_files.empty? && @actual_files.any?) ||
      values_match?(expected_files, @actual_files)
  end

  failure_message_for_should do |actual_file_set|
    if expected_files.empty?
      "Expected #{actual_file_set} to have at least one file.\n" \
      "Found #{@actual_files}."
    else
      "Expected #{actual_file_set} to have files: #{expected_files}\n" \
      "Found #{@actual_files}."
    end
  end
end

RSpec::Matchers.define :be_a_resource_with_permissions do |*expected_permissions|
  match do |actual_resource|
    expect(Hyrax::AccessControlList.new(resource: actual_resource).permissions)
      .to include(*expected_permissions)
  end
end
