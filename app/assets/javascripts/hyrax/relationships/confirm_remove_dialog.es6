export default class ConfirmRemoveDialog {
  /**
   * The function to perform when the dialog is accepted.
   *
   * @callback requestCallback
   */

  /**
   * Initialize the dialog
   * @param {String} text the text for the body of the dialog
   * @param {String} cancel the text for the cancel button
   * @param {String} remove the text for the remove button
   * @param {requestCallback} fn the function to perform if the remove button is pressed
   */
  constructor(text, cancel, remove, fn) {
      this.text = text
      this.cancel = cancel
      this.remove = remove
      this.fn = fn
  }

  template() {
      return `<div class="modal confirm-remove-dialog" tabindex="-1" role="dialog">
              <div class="modal-dialog modal-md" role="document">
              <div class="modal-content">
              <div class="modal-body">${this.text}</div>
              <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-dismiss="modal">${this.cancel}</button>
                <button type="button" class="btn btn-danger" data-behavior="submit">${this.remove}</button>
              </div>
              </div>
              </div>
              </div>`
  }

  launch() {
      let dialog = $(this.template())
      dialog.find('[data-behavior="submit"]').click(() => {
          dialog.modal('hide');
          dialog.remove();
          this.fn();
      })
      dialog.modal('show')
  }
}
