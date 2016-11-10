export class VisibilityComponent {
  constructor(element) {
    this.element = element
    this.form = element.closest('form')
    $('.collapse').collapse({ toggle: false })
    element.find("[type='radio']").on('change', () => { this.showForm() })
    this.showForm()
    this.limitByAdminSet()
  }

  showForm() {
    this.collapseAll()
    this.openSelected()
  }

  collapseAll() {
    $('.collapse').collapse('hide');
  }

  openSelected() {
    let selected = this.element.find("[type='radio']:checked")

    let target = selected.data('target')
    if (!target) {
      return
    }
    $(target).collapse('show');
  }

  // Limit visibility options based on selected AdminSet (if enabled)
  limitByAdminSet() {
    let adminSetInput = this.form.find('select[id$="_admin_set_id"]')
    if(adminSetInput) {
      $(adminSetInput).on('change', () => { this.selectVisibility(adminSetInput.find(":selected")) })
      this.selectVisibility(adminSetInput.find(":selected"))
    }
  }

  // Select visibility to match the AdminSet requirements (if any)
  selectVisibility(selected) {
    // Requirement is in HTML5 'data-visibility' attr
    let visibility = selected.data('visibility')
    if(visibility) {
      this.restrictToVisibility(visibility)
    }
    else {
      this.enableAllOptions()
    }
  }

  // Require given visibility option. All others disabled.
  restrictToVisibility(value) {
    this.element.find("[type='radio'][value='" + value + "']").prop("checked", true).prop("disabled", false)
    this.element.find("[type='radio'][value!='" + value + "']").prop("disabled", true)
    // Ensure required option is opened in form
    this.showForm()
  }

  // Ensure all visibility options are enabled
  enableAllOptions() {
    this.element.find("[type='radio']").prop("disabled", false)
  }

}
