FactoryBot.define do
  factory :embargo, class: Hyrax::Embargo do
    to_create do |instance|
      persister = Valkyrie::MetadataAdapter.find(:indexing_persister).persister
      persister.save(resource: instance)
    end
  end
end
