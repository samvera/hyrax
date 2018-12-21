# frozen_string_literal: true

RSpec::Matchers.define :be_a_lease_matching do |lease_args|
  match do |lease|
    (lease.visibility_after_lease == lease_args[:after]) &&
      (lease.visibility_during_lease == lease_args[:during]) &&
      lease.lease_expiration_date.to_s.start_with?(lease_args[:release_date][0..9])
  end
end
