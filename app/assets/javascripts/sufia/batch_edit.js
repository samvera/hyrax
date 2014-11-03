function batch_edit_init () {

    // initialize popover helpers
    $("a[rel=popover]").popover({ html: true });

    $("tr.expandable").click(function () {
        $(this).next("ul").slideToggle();

        $(this).find('i.toggle').toggleClass("glyphicon glyphicon-chevron-down");
    });

    $("tr.expandable_new").click(function () {
        $(this).find('i').toggleClass("glyphicon glyphicon-chevron-down");
    });


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
                            after_ajax(form_id);
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
                form = [requests[0].form]
                for (var i = requests.length - 1; i > 0; i--) {
                    req = requests.pop();
                    adata = deserialize(req.data.replace(/\+/g, " "));

                    for (key in  Object.keys(adata)) {
                        curKey = Object.keys(adata)[key];
                        if (curKey.slice(0, 12) == "generic_file") {
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

    function after_ajax(form_id) {
        var key = form_id.replace("form_", "");
        var save_button = "#" + key + "_save";
        var outer_div = "#detail_" + key;
        $("#status_" + key).html("Changes Saved");
        $(save_button).removeAttr("disabled");
        $(outer_div).removeClass("loading");
        $('#' + form_id).children([".form-group"]).removeClass('hidden')
    }

    function before_ajax(form_id) {
        var key = form_id.replace("form_", "");
        var save_button = "#" + key + "_save";
        var outer_div = "#detail_" + key;
        $(save_button).attr("disabled", "disabled");
        $(outer_div).addClass("loading");
        $('#' + form_id).children([".form-group"]).addClass('hidden')
    }


    function runSave(e) {
        e.preventDefault();
        var button = $(this);
        var form = $(button.parent().parent()[0]);
        var form_id = form[0].id
        before_ajax(form_id);

        ajaxManager.addReq({
            form: form_id,
            queue: "add_doc",
            url: form.attr("action"),
            dataType: "json",
            type: form.attr("method").toUpperCase(),
            data: form.serialize(),
            complete: function (e) {
                after_ajax(form_id);
                if (e.status == 200) {
                    eval(e.responseText);
                } else {
                    alert("Error!  Status: " + e.status);
                }
            }
        });
        setTimeout(ajaxManager.runNow(), 100);
    }

    function enable_show_hide_links() {
        // Show/hide field details when clicking on a link with ID "expand_link_XXX".
        // We expect to find an element named detail_XXX in addition to the expand_link_XXX.
        // The "detail_XXX" element has the chevron icon.
        $('.glyphicon-chevron-right-helper').on('click', function() {
            var array = this.id.split("expand_link_");
            if (array.length > 1) {
                var docId = array[1];
                $("#detail_" + docId + " .expanded-details").slideToggle();
                var button = $("#expand_" + docId);
                button.toggleClass('glyphicon-chevron-right glyphicon-chevron-down');
            }
            return false;
        });
    }

    $("#permissions_save").click(runSave);
    $(".field-save").click(runSave);
    enable_show_hide_links();

}



// turbolinks triggers page:load events on page transition
// If app isn't using turbolinks, this event will never be triggered, no prob.
$(document).on('page:load', function() {
    batch_edit_init();
});

$(document).ready(function() {
    batch_edit_init();
});
