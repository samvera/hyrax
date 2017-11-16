import RelationshipsControl from 'hyrax/relationships/control'
import SaveWorkControl from 'hyrax/save_work/save_work_control'
import AdminSetWidget from 'hyrax/editor/admin_set_widget'
import LinkedDataResource from 'hyrax/editor/linked_data_resource'
import Autocomplete from 'hyrax/autocomplete'
import AuthoritySelect from 'hyrax/authority_select'

export default class {
  /**
   * initialize the editor behaviors
   * @param {jQuery} element - The form that has a data-param-key attribute
   */
  constructor(element) {
    this.element = element
    this.paramKey = element.data('paramKey') // The work type
    this.adminSetWidget = new AdminSetWidget(element.find('select[id$="_admin_set_id"]'))
    this.sharingTabElement = $('#tab-share')

    this.autocomplete()
    this.linkedDataResources()
    this.sharingTab()
    this.relationshipsControl()
    this.saveWorkControl()
    this.saveWorkFixed()
  }

  // Used when you have a linked data field that can have terms from multiple
  // authorities.
  authoritySelect() {
      $("[data-authority-select]").each(function() {
          let authoritySelect = $(this).data().authoritySelect
          let options =  {selectBox: 'select.' + authoritySelect,
                          inputField: 'input.' + authoritySelect}
          new AuthoritySelect(this, options);
      })
  }

  // Autocomplete fields for the work edit form (based_near, subject, language, child works)
  autocomplete() {
      var autocomplete = new Autocomplete()

      $('[data-autocomplete]').each((function() {
        var elem = $(this)
        autocomplete.setup(elem, elem.data('autocomplete'), elem.data('autocompleteUrl'))
      }))

      $('.multi_value.form-group').manage_fields({
        add: function(e, element) {
          var elem = $(element)
          // Don't mark an added element as readonly even if previous element was
          // Enable before initializing, as otherwise LinkedData fields remain disabled
          elem.attr('readonly', false)
          autocomplete.setup(elem, elem.data('autocomplete'), elem.data('autocompleteUrl'))
        }
      })
  }

  // initialize any linked_data_resource widgets
  linkedDataResources() {
    this.element.find('.linked_data_resource.form-group').each((_idx, controlled_field) =>
      new LinkedDataResource(controlled_field, this.paramKey)
    )
  }

  // Display the sharing tab if they select an admin set that permits sharing
  sharingTab() {
    if(this.adminSetWidget && !this.adminSetWidget.isEmpty()) {
      this.adminSetWidget.on('change', () => this.sharingTabVisiblity(this.adminSetWidget.isSharing()))
      this.sharingTabVisiblity(this.adminSetWidget.isSharing())
    }
  }

  sharingTabVisiblity(visible) {
      if (visible)
         this.sharingTabElement.removeClass('hidden')
      else
         this.sharingTabElement.addClass('hidden')
  }

  relationshipsControl() {
      new RelationshipsControl(this.element.find('[data-behavior="child-relationships"]'),
                               'work_members_attributes',
                               'tmpl-child-work')
  }

  saveWorkControl() {
      new SaveWorkControl(this.element.find("#form-progress"), this.adminSetWidget)
  }

  saveWorkFixed() {
      // Fixedsticky will polyfill position:sticky
      this.element.find('#savewidget').fixedsticky()
  }
}
