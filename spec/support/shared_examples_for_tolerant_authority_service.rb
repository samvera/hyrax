# frozen_string_literal: true

# Behavioral contract for the *tolerant subset* of the authority service API
# that is shared between {Hyrax::QaSelectService} (a base class) and the
# {Hyrax::AuthorityService} mixin (used by module-level services such as
# {Hyrax::ResourceTypesService}).
#
# Covers the methods that are guaranteed identical across both shapes:
# `#label(id)` and
# `#include_current_value(value, index, render_options, html_options)`.
#
# Behaviors that differ between the two implementations (notably how `#active?`
# treats an entry with no `active:` flag — the mixin defaults to true; the
# base class raises) stay asserted in each individual spec, not here.
#
# Hosts must provide:
#   - `service` — the object under test, responding to label/include_current_value
#   - `service_authority` — the FakeAuthority instance backing the service, so
#     the examples can stub `find` for the "authority returns {} for an
#     unknown id" branch
RSpec.shared_examples "a tolerant authority service" do
  describe "#label" do
    it "returns the term for a known id" do
      expect(service.label('active-id')).to eq 'Active Label'
    end

    it "falls back to the id when the entry has no term" do
      expect(service.label('active-no-term-id')).to eq 'active-no-term-id'
    end

    it "accepts a block to override the fallback" do
      expect(service.label('active-no-term-id') { :backup }).to eq :backup
    end
  end

  describe "#include_current_value" do
    let(:render_opts) { [] }
    let(:html_opts)   { { class: 'moomin' } }

    it "preserves an inactive value as a forced-select option" do
      expect(service.include_current_value('inactive-id', :idx, render_opts, html_opts))
        .to eq [[['Inactive Label', 'inactive-id']], { class: 'moomin force-select' }]
    end

    it "preserves an off-authority value using the id as the label" do
      allow(service_authority).to receive(:find).with('unknown-id').and_return({})
      expect(service.include_current_value('unknown-id', :idx, render_opts, html_opts))
        .to eq [[['unknown-id', 'unknown-id']], { class: 'moomin force-select' }]
    end

    it "leaves the options untouched for an active term" do
      expect(service.include_current_value('active-id', :idx, render_opts.dup, html_opts.dup))
        .to eq [render_opts, html_opts]
    end

    it "leaves the options untouched when the value is blank" do
      expect(service.include_current_value('', :idx, render_opts.dup, html_opts.dup))
        .to eq [render_opts, html_opts]
    end
  end
end
