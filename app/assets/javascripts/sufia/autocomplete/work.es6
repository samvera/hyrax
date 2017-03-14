export default class Work {
  // Autocomplete for finding possible related works.
  constructor(element, url, excludeWorkId) {
    this.url = url;
    this.excludeWorkId = excludeWorkId;
    this.initUI(element)
  }

  initUI(element) {
    element.select2( {
      minimumInputLength: 2,
      initSelection : (row, callback) => {
        var data = {id: row.val(), text: row.val()};
        callback(data);
      },
      ajax: { // instead of writing the function to execute the request we use Select2's convenient helper
        url: this.url,
        dataType: 'json',
        data: (term, page) => {
          return {
            q: term, // search term
            id: this.excludeWorkId // Exclude this work
          };
        },
        results: this.processResults
      }
    }).select2('data', null);
  }

  // parse the results into the format expected by Select2.
  // since we are using custom formatting functions we do not need to alter remote JSON data
  processResults(data, page) {
    let results = data.map((obj) => {
                             return { id: obj.id, text: obj.label[0] };
                          })
    return { results: results };
  }
}
