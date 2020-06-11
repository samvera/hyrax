# frozen_string_literal: true
RSpec.describe 'MultifileInput', type: :input do
  class Foo
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include ActiveModel::Validations

    def persisted?
      false
    end

    attr_accessor :bar

    def [](val)
      raise "Unknown attribute" unless val == :bar
      bar
    end
  end

  let(:foo) { Foo.new }
  let(:bar) { ["bar1", "bar2"] }

  subject do
    foo.bar = bar
    input_for(foo, :files, as: :multifile)
  end

  it 'renders multifile' do
    expect(subject).to have_selector('.form-group.multifile label[for=foo_files]', text: 'Upload a file')
    expect(subject).to have_selector('.form-group.foo_files.multifile input[name="foo[files][]"]')
  end
end
