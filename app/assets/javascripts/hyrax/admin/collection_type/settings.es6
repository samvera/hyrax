// Enable/disable sharing APPLIES_TO_NEW_WORKS checkbox based on the state of checkbox SHARABLE
export default class {
  constructor(element) {
    this.element = element
  }

  setup() {
    this.sharable_checkbox = $("#collection_type_sharable")
    this.applies_to_new_works = $("#collection_type_share_applies_to_new_works")
    this.container = $("#sharable-applies-to-new-works-setting-checkbox-container")
    this.label = $("#sharable-applies-to-new-works-setting-label")

    // Watch for changes to "sharable" checkbox
    $("#collection_type_sharable").on('change', () => { this.sharableChanged() })
    this.sharableChanged()
  }

  // Based on the "sharable" checked/unchecked, enable/disable adjust share_applies_to_new_works checkbox
  sharableChanged() {
    let selected = this.sharable_checkbox.is(':checked')
    let disabled = this.sharable_checkbox.is(':disabled')

    if(selected) {
        // if sharable is selected, then base disabled on whether or not sharable is disabled.  It will be disabled when a
        // collection of this type exists.  In that case, share_applies_to_new_works is readonly, that is, it has the value
        // from the database and is disabled
        this.applies_to_new_works.prop("disabled", disabled)
        if(disabled) {
            this.addDisabledClasses()
        }
        else {
            this.removeDisabledClasses()
        }
    }
    else {
        // if sharable is not selected, then share_applies_to_new_works must be unchecked and disabled so it cannot be changed
        this.applies_to_new_works.prop("checked", false)
        this.applies_to_new_works.prop("disabled", true)
        this.addDisabledClasses()
    }
  }

  /**
   * Add disabled class to elements surrounding the APPLIES TO NEW WORKS checkbox when it is disabled
   */
  addDisabledClasses() {
      this.container.addClass("disabled")
      this.label.addClass("disabled")
      this.applies_to_new_works.addClass("disabled")
  }

    /**
     * Remove disabled class from elements surrounding the APPLIES TO NEW WORKS checkbox when it is not disabled
     */
  removeDisabledClasses() {
      this.container.removeClass("disabled")
      this.label.removeClass("disabled")
      this.applies_to_new_works.removeClass("disabled")
  }
}
