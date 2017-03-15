import { RelationshipsTableRow } from './table_row'

export default class RelationshipsTable {

  /**
   * Initializes the class in the context of an individual table element
   * @param {jQuery} element the table element that this class represents
   */
  constructor(element) {
    this.$element = element;
    this.form_action = this.$element.parents("form").attr("action");
    this.query_url = this.$element.data('query-url');
    this.existing_related_works_values = this.$element.find("input.related_works_ids:not(.new-form-control)").map(function(i, e){ return e.value; });

    // TODO: Fall back to just cloning rows and removing rows for form posting
    if (!this.query_url)
      return;

    this.bindAddButton();
    this.bindRemoveButton();
    this.bindKeyEvents();
  }

  /**
   * Handle click events by the "Add" button in the table, setting a warning
   * message if the input is empty or calling the server to handle the request
   */
  bindAddButton() {
    let $this = this;

    $this.$element.on("click", ".btn-add-row", function(event) {
      let $row = $(this).parents("tr:first");
      let $input = $row.find("input.new-form-control");

      // Display an error when the input field is empty, or if the work ID is already related,
      // otherwise clone the row and set appropriate styles
      if ($input.val() === "") {
        $this.setWarningMessage($row, "ID cannot be empty.");
      } else if ($.inArray($input.val(), $this.existing_related_works_values) > -1) {
        $this.setWarningMessage($row, "Work is already related.");
      } else {

        let query_url = $this.query_url.replace('$id', $input.val());
        $this.hideWarningMessage($row);
        $this.callAjax({
          row: $row,
          table: $this.$element,
          input: $input,
          url: $this.form_action,
          query_url: query_url,
          on_error: $this.handleError,
          on_success: $this.handleAddRowSuccess
        });
      }
    });
  }

  /**
   * Find and fire off the click event for the "Add" button
   * @param {jQuery} $row the row containing the add button to click
   */
  clickAddbutton($row) {
    $row.find(".btn-add-row").click();
  }

  /**
   * Handle click events by the "Remove" buttons in the table, and calling the
   * server to handle the request
   */
  bindRemoveButton() {
    let $this = this;

    $this.$element.on("click", ".btn-remove-row", function(event) {
      let $row = $(this).parents("tr:first");
      let $input = $row.find("input.related_works_ids:first");

      // Track which input is attemping to be removed, to provide an easy way
      // for the ajax call to exclude it when making the call to the server
      $input.addClass("removing");
      $this.callAjax({
        row: $row,
        table: $this.$element,
        input: $input,
        url: $this.form_action,
        on_error: $this.handleError,
        on_success: $this.handleRemoveRowSuccess
      });
    });
  }

  /**
   * Handle keyup and keypress events at the form level to prevent the ENTER key
   * from submitting the form. ENTER key within a relationships table should
   * click the "Add" button instead. ESC key should clear the input and hide the
   * error message.
   */
  bindKeyEvents() {
    let $this = this;
    let $form = this.$element.parents("form");

    $form.on("keyup keypress", "input.related_works_ids", function(event) {
      let $row = $(this).parents("tr:first");
      let key_code = event.keyCode || event.which;

      // ENTER key was pressed, wait for keyup to click the Add button
      if (key_code === 13) {
        if (event.type === "keyup") {
          $this.clickAddbutton($row);
        }
        event.preventDefault();
        return false;
      }

      // ESC key was pressed, clear the input field and hide the error
      if (key_code === 27 && event.type === "keyup") {
        $(this).val("");
        $this.hideWarningMessage($row);
      }
    });
  }

  /**
   * Set the warning message related to the appropriate row in the table
   * @param {jQuery} $row the row containing the warning message to display
   * @param {String} message the warning message text to set
   */
  setWarningMessage($row, message) {
    $row.find(".message.has-warning").text(message).removeClass("hidden");
  }

  /**
   * Hide the warning message on the appropriate row
   * @param {jQuery} $row the row containing the warning message to hide
   */
  hideWarningMessage($row){
    $row.find(".message").addClass("hidden");
  }

  /**
   * Call the server, then call the appropriate callbacks to handle success and errors
   * @param {Object} args the table, row, input, url, and callbacks
   */
  callAjax(args) {
    let $this = this;
    // Send only the IDs in this table that aren't in the midst of being "removed"
    let data = args.table.find("input.related_works_ids:not('.removing')").serialize();
    $.ajax({
        type: 'patch',
        url: args.url,
        dataType: 'json',
        data: data
      })
      .done(function(json) {
        args.on_success($this, args, json);
      })
      .fail(function(jqxhr, status, err) {
        args.on_error($this, args, jqxhr, status, err);
      });
  }

  /**
   * Set a warning message to alert the user on an error
   * @param {jQuery} $this the RelationshipsTable class instance
   * @param {Object} args the table, row, input, url, and callbacks
   * @param {Object} jqxhr the jQuery XHR response object
   * @param {String} status the HTTP error status
   * @param {String} err the HTTP error
   */
  handleError($this, args, jqxhr, status, err) {
    args.row.find('input.removing').removeClass('removing');
    let message = jqxhr.statusText;
    if(jqxhr.responseJSON){
      message = jqxhr.responseJSON.description;
    }
    $this.setWarningMessage(args.row, message);
  }

  /**
   * Remove the row when the API returns this type of success
   * @param {jQuery} $this the RelationshipsTable class instance
   * @param {Object} args the table, row, input, url, and callbacks
   * @param {String} json the returned JSON string
   */
  handleRemoveRowSuccess($this, args, json) {
    args.row.remove();
  }

  /**
   * Add a new row to the table, query the server for details about the work to
   * set the title and link for the new work that was added. Hide the input
   * field and display the title and edit button
   * @param {jQuery} $this the RelationshipsTable class instance
   * @param {Object} args the table, row, input, url, and callbacks
   * @param {String} json the returned JSON string
   */
  handleAddRowSuccess($this, args, json) {
    let new_row = new RelationshipsTableRow(args.table);
    new_row.clone(args.row);
    new_row.callAjaxQuery(args.query_url);

    // finally, empty the "add" row input value
    args.row.find("input.new-form-control").val("");
    // synch the related_works_values to include the new work relationship
    $this.existing_related_works_values = $this.$element.find("input.related_works_ids:not(.new-form-control)").map(function(i, e){ return e.value; });
  }
}
