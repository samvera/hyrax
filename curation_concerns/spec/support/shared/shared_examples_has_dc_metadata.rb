shared_examples 'has_dc_metadata' do
  # Single-valued fields
  it { should have_unique_field(:created) }
  it { should have_unique_field(:date_uploaded) }
  it { should have_unique_field(:date_modified) }

  # Multivalued fields
  it { should have_multivalue_field(:content_format) }
  it { should have_multivalue_field(:description) }
  it { should have_multivalue_field(:identifier) }
  it { should have_multivalue_field(:publisher) }
  it { should have_multivalue_field(:source) }
  it { should have_multivalue_field(:language) }
  it { should have_multivalue_field(:subject) }
end
