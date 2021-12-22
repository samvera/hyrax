import { RequiredFields } from './required_fields'
import { ChecklistItem } from './checklist_item'
import { UploadedFiles } from './uploaded_files'
import { DepositAgreement } from './deposit_agreement'
import VisibilityComponent from './visibility_component'

/**
 * Polyfill String.prototype.startsWith()
 */
if (!String.prototype.startsWith) {
    String.prototype.startsWith = function(searchString, position){
      position = position || 0;
      return this.substr(position, searchString.length) === searchString;
  };
}

export default class SaveWorkControl {
  /**
   * Initialize the save controls
   * @param {jQuery} element the jquery selector for the save panel
   * @param {AdminSetWidget} adminSetWidget the control for the adminSet dropdown
   */
  constructor(element, adminSetWidget) {
    if (element.length < 1) {
      return
    }
    this.element = element
    this.adminSetWidget = adminSetWidget
    this.form = element.closest('form')
    element.data('save_work_control', this)
    this.activate();
  }

  /**
   * Keep the form from submitting (if the return key is pressed)
   * unless the form is valid.
   *
   * This seems to occur when focus is on one of the visibility buttons
   */
  preventSubmitUnlessValid() {
    this.form.on('submit', (evt) => {
      if (!this.isValid())
        evt.preventDefault();
    })
  }

  /**
   * Keep the form from being submitted many times.
   *
   */
  preventSubmitIfAlreadyInProgress() {
    this.form.on('submit', (evt) => {
      if (this.isValid())
        this.saveButton.prop("disabled", true);
    })
  }

  /**
   * Keep the form from being submitted while uploads are running
   *
   */
  preventSubmitIfUploading() {
    this.form.on('submit', (evt) => {
      if (this.uploads.inProgress) {
        evt.preventDefault()
      }
    })
  }

  /**
   * Is the form for a new object (vs edit an existing object)
   */
  get isNew() {
    return this.form.attr('id').startsWith('new')
  }

  /*
   * Call this when the form has been rendered
   */
  activate() {
    if (!this.form) {
      return
    }
    this.requiredFields = new RequiredFields(this.form, () => this.formStateChanged())
    this.uploads = new UploadedFiles(this.form, () => this.formStateChanged())
    this.saveButton = this.element.find(':submit')
    this.depositAgreement = new DepositAgreement(this.form, () => this.formStateChanged())
    this.requiredMetadata = new ChecklistItem(this.element.find('#required-metadata'))
    this.requiredFiles = new ChecklistItem(this.element.find('#required-files'))
    this.requiredAgreement = new ChecklistItem(this.element.find('#required-agreement'))
    new VisibilityComponent(this.element.find('.visibility'), this.adminSetWidget)
    this.preventSubmit()
    this.watchMultivaluedFields()
    this.formChanged()
    this.addFileUploadEventListeners();
  }

  addFileUploadEventListeners() {
    let $uploadsEl = this.uploads.element;
    const $cancelBtn = this.uploads.form.find('#file-upload-cancel-btn');

    $uploadsEl.bind('fileuploadstart', () => {
      $cancelBtn.prop('hidden', false);
    });

    $uploadsEl.bind('fileuploadstop', () => {
      $cancelBtn.prop('hidden', true);
    });
  }

  preventSubmit() {
    this.preventSubmitUnlessValid()
    this.preventSubmitIfAlreadyInProgress()
    this.preventSubmitIfUploading()
  }

  // If someone adds or removes a field on a multivalue input, fire a formChanged event.
  watchMultivaluedFields() {
      $('.multi_value.form-group', this.form).bind('managed_field:add', () => this.formChanged())
      $('.multi_value.form-group', this.form).bind('managed_field:remove', () => this.formChanged())
  }

  // Called when a file has been uploaded, the deposit agreement is clicked or a form field has had text entered.
  formStateChanged() {
    this.saveButton.prop("disabled", !this.isSaveButtonEnabled);
  }

  // called when a new field has been added to the form.
  formChanged() {
    this.requiredFields.reload();
    this.formStateChanged();
  }

  // Indicates whether the "Save" button should be enabled: a valid form and no uploads in progress
  get isSaveButtonEnabled() {
    return this.isValid() && !this.uploads.inProgress;
  }

  isValid() {
    // avoid short circuit evaluation. The checkboxes should be independent.
    let metadataValid = this.validateMetadata()
    let filesValid = this.validateFiles()
    let agreementValid = this.validateAgreement(filesValid)
    return metadataValid && filesValid && agreementValid
  }

  // sets the metadata indicator to complete/incomplete
  validateMetadata() {
    if (this.requiredFields.areComplete) {
      this.requiredMetadata.check()
      return true
    }
    this.requiredMetadata.uncheck()
    return false
  }

  // sets the files indicator to complete/incomplete
  validateFiles() {
    if (!this.uploads.hasFileRequirement) {
      return true
    }
    if (!this.isNew || this.uploads.hasFiles) {
      this.requiredFiles.check()
      return true
    }
    this.requiredFiles.uncheck()
    return false
  }

  validateAgreement(filesValid) {
    if (filesValid && this.uploads.hasNewFiles && this.depositAgreement.mustAgreeAgain) {
      // Force the user to agree again
      this.depositAgreement.setNotAccepted()
      this.requiredAgreement.uncheck()
      return false
    }
    if (!this.depositAgreement.isAccepted) {
      this.requiredAgreement.uncheck()
      return false
    }
    this.requiredAgreement.check()
    return true
  }
}
