export class DepositAgreement {
  // Monitors the form and runs the callback if any files are added
  constructor(form, callback) {
    this.agreementCheckbox = form.find('input#agreement')
    // If true, require the accept checkbox to be checked.
    this.isActiveAgreement = this.agreementCheckbox.size() > 0
    if (this.isActiveAgreement)
      this.setupActiveAgreement(callback)
  }

  setupActiveAgreement(callback) {
    this.agreementCheckbox.on('change', callback)
  }

  /**
   * return true if it's a passive agreement or if the checkbox has been checked
   */
  get isAccepted() {
    return !this.isActiveAgreement || this.agreementCheckbox[0].checked
  }
}
