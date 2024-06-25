# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'wings_helper'
require 'wings/orm_converter'

RSpec.describe Wings::OrmConverter, :active_fedora do
  describe '.to_valkyrie_resource_class' do
    context 'when given a ActiveFedora class (eg. a constant that responds to #properties)' do
      context 'for the returned object (e.g. a class)' do
        subject(:klass) { described_class.to_valkyrie_resource_class(klass: GenericWork) }

        it 'will be Hyrax::Resource build' do
          expect(subject.new).to be_a Hyrax::Resource
        end

        it 'has a to_s instance that delegates to the given klass' do
          expect(subject.to_s).to eq(GenericWork.to_s)
        end

        it 'has a internal_resource instance that is the given klass' do
          expect(subject.internal_resource).to eq(GenericWork.to_s)
        end

        it 'has a name' do
          expect(klass.name).to eq 'Hyrax::Work'
        end

        it 'includes name in instance inspect' do
          expect(klass.new.inspect).to start_with '#<Hyrax::Work'
        end

        it 'has a to_model for route resolution' do
          expect(klass.new.to_model)
            .to have_attributes(model_name: an_instance_of(Hyrax::Name),
                                to_partial_path: 'hyrax/generic_works/generic_work')
        end
      end

      context 'for a custom class' do
        subject(:klass) { described_class.to_valkyrie_resource_class(klass: Hyrax::Test::Book) }

        it 'will be the registered resource class' do
          expect(subject.new).to be_a Hyrax::Test::BookResource
        end

        it 'has a name' do
          expect(klass.name).to eq 'Hyrax::Test::BookResource'
        end

        it 'includes name in instance inspect' do
          expect(klass.new.inspect).to start_with '#<Hyrax::Test::BookResource'
        end

        it 'has a to_model for route resolution' do
          expect(klass.new.to_model)
            .to have_attributes(model_name: an_instance_of(ActiveModel::Name),
                                to_partial_path: 'hyrax/test/books/book')
        end
      end
    end

    context 'when given a non-ActiveFedora class' do
      it 'raises an exception' do
        expect { described_class.to_valkyrie_resource_class(klass: String) }.to raise_error(NoMethodError)
      end
    end

    context 'when given a registered class' do
      it 'returns a subclass of the corresponding native valkyrie resource' do
        klass = Wings::ModelRegistry.lookup(Hyrax::Test::BookResource)

        expect(described_class.to_valkyrie_resource_class(klass: klass).ancestors)
          .to include Hyrax::Test::BookResource
      end
    end
  end
end
