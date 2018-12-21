# frozen_string_literal: true

RSpec::Matchers.define :be_an_embargo_matching do |embargo_args|
  match do |embargo|
    (embargo.visibility_after_embargo == embargo_args[:after]) &&
      (embargo.visibility_during_embargo == embargo_args[:during]) &&
      embargo.embargo_release_date.to_s.start_with?(embargo_args[:release_date][0..9])
  end
end
