shared_examples 'is_embargoable' do
  it 'has an embargo_release_date attribute' do
    expect(subject).to respond_to(:embargo_release_date)
    expect(subject).to respond_to(:embargo_release_date=)
  end
end
