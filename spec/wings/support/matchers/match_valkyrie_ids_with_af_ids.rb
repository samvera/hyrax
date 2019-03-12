RSpec::Matchers.define :match_valkyrie_ids_with_active_fedora_ids do |_active_fedora_ids|
  match do |valkyrie_ids|
    contain_exactly(valkyrie_ids.map(&:id))
  end
end
