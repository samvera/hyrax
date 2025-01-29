# frozen_string_literal: true
RSpec.describe Hyrax::Forms::FailedSubmissionFormWrapper do
  let(:form) { instance_double(Hyrax::Forms::WorkForm, **form_attributes) }
  let(:form_attributes) { { title: ["Form's Title"], description: ["Form's description"] } }
  # I would love to use Hyrax::Forms::WorkForm, but I encountered an
  # exception when I do Hyrax::Forms::WorkForm.permitted_params.  In
  # this spec, things fail, however in
  # ./spec/forms/hyrax/forms/work_form_spec.rb it works.
  let(:permitted_params) do
    [
      { title: [] },
      :representative_id,
      { description: [] },
      { based_near_attributes: [:id, :_destroy], member_of_collections_attributes: [:id, :_destroy], work_members_attributes: [:id, :_destroy] },
      { permissions_attributes: [:type, :name, :access, :id, :_destroy] }
    ]
  end
  let(:input_params) do
    ActionController::Parameters.new(
      title: ["Title"],
      representative_id: "123",
      obviously_missing_attribute: "One",
      member_of_collections_attributes: { "0" => { id: "1" }, "2" => { id: "2", _destroy: "1" } }
    )
  end

  subject(:wrapper) { described_class.new(form: form, input_params: input_params, permitted_params: permitted_params) }

  describe "input param key is part of permitted params" do
    it "exposes the given input params" do
      expect(wrapper.representative_id).to eq(input_params.fetch(:representative_id))
      expect(wrapper[:representative_id]).to eq(input_params.fetch(:representative_id))

      expect(wrapper.title).to eq(input_params.fetch(:title))
      expect(wrapper[:title]).to eq(input_params.fetch(:title))

      # Params come back from wrapper as ActionController::Parameters in a regular hash, so we have to do the same to input_params
      params_hash = {}
      input_params.fetch("member_of_collections_attributes").each_pair do |nested_key, nested_value|
        params_hash[nested_key] = nested_value
      end
      expect(wrapper.member_of_collections_attributes).to eq(params_hash)
      expect(wrapper[:member_of_collections_attributes]).to eq(params_hash)

      expect { wrapper.obviously_missing_attribute }.to raise_error(NoMethodError)
    end

    it "delegates to the underlying form when an input param is not given" do
      expect(wrapper.description).to eq(form.description)
      allow(form).to receive(:[]).with(:description).and_return(form_attributes.fetch(:description))
      expect(wrapper[:description]).to eq(form.description)
    end
  end

  describe "when no permitted params are given" do
    let(:form) { double(**form_attributes) } # Need to get around some constraints of instance_double, so I'm loosening requirements
    subject(:wrapper) { described_class.new(form: form, input_params: input_params) }
    it "uses the form's #permitted_params" do
      allow(form).to receive(:respond_to?).with(:permitted_params).and_return(true)
      expect(form).to receive(:permitted_params).and_return(permitted_params)
      expect(wrapper.instance_variable_get("@permitted_params")).to eq(permitted_params)
    end

    it "uses form.permitted_params when form does not respond to #permitted_params" do
      allow(form).to receive(:respond_to?).with(:permitted_params).and_return(false)
      allow(form.class).to receive(:respond_to?).with(:permitted_params).and_return(true)
      expect(form.class).to receive(:permitted_params).and_return(permitted_params)
      expect(wrapper.instance_variable_get("@permitted_params")).to eq(permitted_params)
    end

    it "uses form.build_permitted_params when form does not respond to #permitted_params nor .permitted_params" do
      allow(form).to receive(:respond_to?).with(:permitted_params).and_return(false)
      allow(form.class).to receive(:respond_to?).with(:permitted_params).and_return(false)
      allow(form.class).to receive(:respond_to?).with(:build_permitted_params).and_return(true)
      expect(form.class).to receive(:build_permitted_params).and_return(permitted_params)
      expect(wrapper.instance_variable_get("@permitted_params")).to eq(permitted_params)
    end

    it "raises an error when it can't find a suitable permitted params" do
      expect { wrapper }.to raise_error(ArgumentError)
    end
  end
end
