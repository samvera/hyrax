# frozen_string_literal: true
require 'wings_helper'
require 'wings/orm_converter'

RSpec.describe Wings::OrmConverter do
  describe '.to_valkyrie_resource_class' do
    context 'when given a ActiveFedora class (eg. a constant that responds to #properties)' do
      context 'for the returned object (e.g. a class)' do
        subject { described_class.to_valkyrie_resource_class(klass: GenericWork) }
        it 'will be Valkyrie::Resource build' do
          expect(subject.new).to be_a Valkyrie::Resource
        end
        it 'has a to_s instance that delegates to the given klass' do
          expect(subject.to_s).to eq(GenericWork.to_s)
        end
        it 'has a internal_resource instance that is the given klass' do
          expect(subject.internal_resource).to eq(GenericWork.to_s)
        end
      end
    end

    context 'when given a non-ActiveFedora class' do
      it 'raises an exception' do
        expect { described_class.to_valkyrie_resource_class(klass: String) }.to raise_error
      end
    end
  end
end
