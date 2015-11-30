require 'spec_helper'

describe CurationConcerns::NullLogger do
  subject { described_class.new }
  its(:debug) { is_expected.to be_nil }
  its(:info) { is_expected.to be_nil }
  its(:warn) { is_expected.to be_nil }
  its(:error) { is_expected.to be_nil }
  its(:fatal) { is_expected.to be_nil }
end
