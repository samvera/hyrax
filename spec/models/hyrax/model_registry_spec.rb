# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Hyrax::ModelRegistry do
  %i[admin_set file_set collection work].each do |type|
    describe ".#{type}_class_names" do
      subject { described_class.public_send("#{type}_class_names") }

      it { is_expected.to be_a(Array) }
      it { is_expected.to be_present }
      it { is_expected.to all(be_kind_of(String)) }
    end

    describe ".#{type}_classes" do
      subject { described_class.public_send("#{type}_classes") }

      it { is_expected.to be_a(Array) }
      it { is_expected.to be_present }

      it { is_expected.to all(be_kind_of(Class)) }
    end

    describe ".#{type}_rdf_representations" do
      subject { described_class.public_send("#{type}_rdf_representations") }

      it { is_expected.to be_a(Array) }
      it { is_expected.to be_present }
      it { is_expected.to all(be_kind_of(String)) }
    end
  end

  describe ".classes_from" do
    subject { described_class.send("classes_from", ["DefinitelyNotARealClass", "Hyrax"]) }

    it { is_expected.to be_a(Array) }
    it { is_expected.not_to include(nil) }
  end
end
