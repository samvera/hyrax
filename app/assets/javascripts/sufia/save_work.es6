Blacklight.onLoad(() => new SaveWorkControl($("#form-progress"))
)

class RequiredFields {
  // Monitors the form and runs the callback if any of the required fields change
  constructor(form, callback) {
    this.form = form
    this.requiredFields = this.form.find('input[required]')
    this.requiredFields.change(callback)
  }

  get areComplete(){
    return this.requiredFields.filter((n, elem) => { return $(elem).val().length < 1 } ).length == 0
  }
}

class SaveWorkControl {
  constructor(element) {
    this.element = element
    this.form = element.closest('form')
    this.requiredFields = new RequiredFields(this.form, () => this.formChanged())
    this.requiredMetadata = element.find('#required-metadata')

    // Fire the change event after being loaded:
    this.formChanged()
  }

  formChanged() {
    this.validateMetadata()
  }

  // sets the metadata indicator to complete/incomplete
  validateMetadata() {
    if (this.requiredFields.areComplete) {
      this.requiredMetadata.removeClass('incomplete')
      this.requiredMetadata.addClass('complete')
    } else {
      this.requiredMetadata.removeClass('complete')
      this.requiredMetadata.addClass('incomplete')
    }
  }
}
