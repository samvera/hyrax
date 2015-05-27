module CurationConcerns
  module FactoryHelpers
    module_function
    def load_factories_for(context, klass)
      context.instance_exec(klass) do |curation_concern_class|
        let(:curation_concern_type_underscore) { curation_concern_class.name.underscore }
        let(:default_work_factory_name) { curation_concern_type_underscore }
        let(:default_work_factory_name_with_files) { "#{default_work_factory_name}_with_files".to_sym }
        let(:private_work_factory_name) { "private_#{curation_concern_type_underscore}".to_sym }
        let(:public_work_factory_name) { "public_#{curation_concern_type_underscore}".to_sym }
      end
    end
  end
end
