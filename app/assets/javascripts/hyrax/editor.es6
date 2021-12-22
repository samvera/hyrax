import RelationshipsControl from 'hyrax/relationships/control'
import SaveWorkControl from 'hyrax/save_work/save_work_control'
import AdminSetWidget from 'hyrax/editor/admin_set_widget'
import ControlledVocabulary from 'hyrax/editor/controlled_vocabulary'
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
  }

  init() {
    this.autocomplete()
    this.controlledVocabularies()
    this.sharingTab()
    this.relationshipsControl()
    this.saveWorkControl()
    this.saveWorkFixed()
    this.authoritySelect()
    this.formInProgress()
  }

  // Immediate feedback after work creation, editing.
  formInProgress() {
    $('[data-behavior~=work-form]').on('submit', function(event){
      $('.card-footer').prop('hidden', (_, old) => !old);
    });
  }
  
  // Used when you have a linked data field that can have terms from multiple
  // authorities.
  authoritySelect() {
      $("[data-authority-select]").each(function() {
          let authoritySelect = $(this).data().authoritySelect
          let options =  {selectBox: 'select.' + authoritySelect,
                          inputField: 'input.' + authoritySelect}
          new AuthoritySelect(options);
      })
  }

  // Autocomplete fields for the work edit form (based_near, subject, language, child works)
  autocomplete() {
      var autocomplete = new Autocomplete()

      $('[data-autocomplete]').each((function() {
        var elem = $(this)
        autocomplete.setup(elem, elem.data('autocomplete'), elem.data('autocompleteUrl'))
        elem.parents('.multi_value.form-group').manage_fields({
          add: function(e, element) {
            var elem = $(element)
            // Don't mark an added element as readonly even if previous element was
            // Enable before initializing, as otherwise LinkedData fields remain disabled
            elem.attr('readonly', false)
            autocomplete.setup(elem, elem.data('autocomplete'), elem.data('autocompleteUrl'))
          }
        })
      }))
  }

  // initialize any controlled vocabulary widgets
  controlledVocabularies() {
    this.element.find('.controlled_vocabulary.form-group').each((_idx, controlled_field) =>
      new ControlledVocabulary(controlled_field, this.paramKey)
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
         this.sharingTabElement.prop('hidden', false)
      else
         this.sharingTabElement.prop('hidden', true)
  }

  relationshipsControl() {
      let collections = this.element.find('[data-behavior="collection-relationships"]')
      collections.each((_idx, element) =>
          new RelationshipsControl(element,
                                   collections.data('members'),
                                   collections.data('paramKey'),
                                   'member_of_collections_attributes',
                                   'tmpl-collection').init())

      let works = this.element.find('[data-behavior="child-relationships"]')
      works.each((_idx, element) =>
          new RelationshipsControl(element,
                                   works.data('members'),
                                   works.data('paramKey'),
                                   'work_members_attributes',
                                   'tmpl-child-work').init())
  }

  saveWorkControl() {
      new SaveWorkControl(this.element.find("#form-progress"), this.adminSetWidget)
  }

  saveWorkFixed() {
      // Fixedsticky will polyfill position:sticky
      this.element.find('#savewidget').fixedsticky()
  }
}
