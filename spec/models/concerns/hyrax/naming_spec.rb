# frozen_string_literal: true

RSpec.describe Hyrax::Naming do
  subject(:class_with_naming) do
    Hyrax::Test::Naming::TestClass
  end

  before do
    module Hyrax::Test::Naming
      class TestClass
        include ActiveModel::Model
        include Hyrax::Naming
      end
    end
  end

  after { Hyrax::Test.send(:remove_const, :Naming) }

  describe '.model_name' do
    it 'is a Hyrax::Name' do
      expect(class_with_naming.model_name).to be_a Hyrax::Name
    end

    it 'accepts a name_class' do
      expect(class_with_naming.model_name(name_class: ActiveModel::Name))
        .to be_a ActiveModel::Name
    end
  end
end
