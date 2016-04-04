export class RequiredFields {
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
