function batch_edit_init () {

    function deserialize(Params) {
        var Data = Params.split("&");
        var i = Data.length;
        var Result  = {};
        while (i--) {
            var Pair = decodeURIComponent(Data[i]).split("=");
            var key = Pair[0];
            var val = Pair[1];
            if (Result[key] != null) {
                if(!$.isArray(Result[key])) Result[key] = [Result[key]];
                Result[key].push(val);
            } else
                Result[key] = val;
        }
        return Result;
    }

    var ajaxManager = (function () {
        var requests = [];
        var running = false;
        return {
            addReq: function (opt) {
                requests.push(opt);
            },
            removeReq: function (opt) {
                if ($.inArray(opt, requests) > -1)
                    requests.splice($.inArray(opt, requests), 1);
            },
            runNow: function () {
                clearTimeout(this.tid);
                if (!running) {
                    this.run();
                }
            },
            run: function () {
                running = true;
                var self = this;

                if (requests.length) {

                    // combine data from multiple requests
                    if (requests.length > 1) {
                      requests = this.combine_requests(requests);
                    }

                    requests = this.setup_request_complete(requests);
                    $.ajax(requests[0]);
                } else {
                    self.tid = setTimeout(function () {
                        self.run.apply(self, []);
                    }, 500);
                    running = false;
                }
            },
            stop: function () {
                requests = [];
                clearTimeout(this.tid);
            },
            setup_request_complete: function (requests) {
                oriComp = requests[0].complete;

                requests[0].complete = [ function (e) {
                    req = requests.shift();
                    if (typeof req.form === 'object') {
                        for (f in req.form) {
                            form_id = form[f];
                            after_ajax(new BatchEditField($("#"+form_id)));
                        }
                    }
                    this.tid = setTimeout(function () {
                        ajaxManager.run.apply(ajaxManager, []);
                    }, 50);
                    return true;
                }];
                if (typeof oriComp === 'function') requests[0].complete.push(oriComp);
                return requests;
            },
            combine_requests: function (requests) {
                var data = deserialize(requests[0].data.replace(/\+/g, " "));
                var adata;
                form = [requests[0].form]
                for (var i = requests.length - 1; i > 0; i--) {
                    req = requests.pop();
                    adata = deserialize(req.data.replace(/\+/g, " "));

                    for (key in  Object.keys(adata)) {
                        curKey = Object.keys(adata)[key];
                        if (curKey.slice(0, 12) == req.key) {
                            data[curKey] = adata[curKey];
                            form.push(req.form);
                        }
                    }
                }
                requests[0].data = $.param(data);
                requests[0].form = form;
                return requests;
            }
        };
    }());

    ajaxManager.run();

    function after_ajax(form) {
        form.enableForm();
    }

    function before_ajax(form) {
        form.disableForm();
    }

    var BatchEditField = function (form) {
        this.form = form;
        this.formButtons = form.find('.btn');
        this.formFields = form.find('.form-group > *');
        this.formRightPanel = form.find('.form-group');
        this.statusField = form.find('.status');
    }

    BatchEditField.prototype = {
        disableForm: function () {
            this.formButtons.attr("disabled", "disabled");
            this.formRightPanel.addClass("loading");
            this.formFields.addClass('invisible')
        },

        enableForm: function () {
            this.statusField.html("Changes Saved");
            this.formButtons.removeAttr("disabled");
            this.formRightPanel.removeClass("loading");
            this.formFields.removeClass('invisible')
        }
    }

    function runSave(e) {
        e.preventDefault();
        var button = $(this);
        var form = button.closest('form');
        var f = new BatchEditField(form);
        var form_id = form[0].id;
        before_ajax(f);

        ajaxManager.addReq({
            form: form_id,
            key: form.data('model'),
            queue: "add_doc",
            url: form.attr("action"),
            dataType: "json",
            type: form.attr("method").toUpperCase(),
            data: form.serialize(),
            success: function (e) {
                after_ajax(f);
            },
            fail: function (e) {
                alert("Error!  Status: " + e.status);
            }
        });
        setTimeout(ajaxManager.runNow(), 100);
    }

    $("#permissions_save").click(runSave);
    $(".field-save").click(runSave);
}

Blacklight.onLoad(function() {
  // set up global batch edit options to override the ones in the hydra-batch-edit gem
  window.batch_edits_options = { checked_label: "",
                                 unchecked_label: "",
                                 progress_label: "",
                                 status_label: "",
                                 css_class: "batch_toggle" };
  batch_edit_init();

}); //end of Blacklight.onload
