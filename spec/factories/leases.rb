FactoryBot.define do
  factory :lease, class: Hyrax::Lease do
    to_create do |instance|
      persister = Valkyrie::MetadataAdapter.find(:indexing_persister).persister
      persister.save(resource: instance)
    end
  end
end
