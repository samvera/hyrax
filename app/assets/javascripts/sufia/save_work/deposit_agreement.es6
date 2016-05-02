export class DepositAgreement {
  // Monitors the form and runs the callback if any files are added
  constructor(form, callback) {
    this.agreementCheckbox = form.find('input#agreement')
    // If true, require the accept checkbox to be checked.
    this.isActiveAgreement = this.agreementCheckbox.size() > 0
    if (this.isActiveAgreement) {
      this.setupActiveAgreement(callback)
    }

    // Tracks whether the user needs to accept again to the depositor
    // agreement. Once the user has manually agreed once she does not
    // need to agree again regardless on how many files are being added.
    this.mustAgreeAgain = this.isAccepted
  }

  setupActiveAgreement(callback) {
    this.agreementCheckbox.on('change', callback)
  }

  setNotAccepted() {
    this.agreementCheckbox.prop("checked", false)
    this.mustAgreeAgain = false
  }

  setAccepted() {
    this.agreementCheckbox.prop("checked", true)
  }

  /**
   * return true if it's a passive agreement or if the checkbox has been checked
   */
  get isAccepted() {
    return !this.isActiveAgreement || this.agreementCheckbox[0].checked
  }
}
