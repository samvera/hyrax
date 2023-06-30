# frozen_string_literal: true
RSpec::Matchers.define :require_membership do
  match do |actual|
    actual&.require_membership?
  end
end

RSpec::Matchers.define :allow_multiple_membership do
  match do |actual|
    actual&.allow_multiple_membership?
  end
end

RSpec::Matchers.define :assign_visibility do
  match do |actual|
    actual&.assigns_visibility?
  end
end

RSpec::Matchers.define :assign_workflow do
  match do |actual|
    actual&.assigns_workflow?
  end
end

RSpec::Matchers.define :have_collections do
  match do |actual|
    actual&.collections&.any?
  end
end
