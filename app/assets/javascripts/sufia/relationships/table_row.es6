export class RelationshipsTableRow {
  /**
   * Inititializes a new table row class
   * @param {jQuery} $table the table which this row is related to
   */
  constructor($table){
    this.table = $table;
    this.element = null;
  }

  /**
   * The title element
   * @returns {jQuery} the title element
   */
  get title() { return this.element.find("a.title:first"); }

  /**
   * The input field
   * @returns {jQuery} the input field
   */
  get input() { return this.element.find("input.related_works_ids:first"); }

  /**
   * The "Add" button
   * @returns {jQuery} the add button element
   */
  get addButton() { return this.element.find(".btn-add-row"); }

  /**
   * The "Remove" button
   * @returns {jQuery} the remove button element
   */
  get removeButton() { return this.element.find(".btn-remove-row"); }

  /**
   * The "Edit" button
   * @returns {jQuery} the edit button element
   */
  get editButton() { return this.element.find("a.edit:first"); }

  /**
   * Clone the row, set the element in this instance of the class, and reset the proper styles for this row. Insert
   * this new row before the row passed in.. leaving the passed in row styled as-is, the caller of this method is responsible
   * for properly handling adjustment to the passed in row
   * @param {jQuery} $row the row to be cloned
   */
  clone($row){
    this.element = $row.clone();
    this.addButton.addClass("hidden");
    this.removeButton.removeClass("hidden");
    this.element.insertBefore($row);
  }

  /**
   * Make an ajax call to the supplied url.
   * After a row is cloned, this method could be called to refresh the row with more details (title, appropriate links, etc)
   * based on the details returned from the server.
   * @param {String} query_url the url to be called for querying details from the server
   */
  callAjaxQuery(query_url) {
    let $this = this;
    $.getJSON(query_url, function (data) {
      // Set the cloned input to have the proper name and value for posting the
      // form to the server, and hide it.
      $this.input.removeClass("new-form-control")
        .addClass("hidden")
        .val(data.id);

      // Set the linkified title and show.
      $this.title.text(data.title[0])
        .attr("href", query_url)
        .removeClass("hidden");

      // Set the edit button link and show.
      $this.editButton.attr("href", query_url + "/edit")
        .removeClass("hidden");
    });
  }
}