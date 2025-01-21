Blacklight.onLoad(function() {
    const isCollapsed = getCollapsedActivity();
    if(isCollapsed){
        localStorage.setItem('collapsedActivity', 'collapsed');
    }else{
        localStorage.setItem('collapsedActivity', 'un-collapsed');
    }
    getStatusActivity();

    const isCollapsedSettings = getCollapsedSettings();
    if(isCollapsedSettings){
        localStorage.setItem('collapsedSettings', 'collapsed');
    }else{
        localStorage.setItem('collapsedSettings', 'un-collapsed');
    }
    getStatusSettings();
});

function getCollapsedActivity() {
    const state = localStorage.getItem('collapsedActivity');
    if(state === 'un-collapsed'){
        return false;
    }
    return true;
}

function getCollapsedSettings() {
    const state = localStorage.getItem('collapsedSettings');
    if(state === 'un-collapsed'){
        return false;
    }
    return true;
}

function getStatusActivity(){
    const resultDiv = document.getElementById('collapseUserActivity');
    const isCollapsed = getCollapsedActivity();
    if (resultDiv === null) {
        return;
    }
    else if(isCollapsed){
        resultDiv.classList.remove("in");
        // resultDiv.setAttribute("aria-expanded", "false");
    }else{
        resultDiv.classList.add("in");
        // resultDiv.setAttribute("aria-expanded", "true");
    }
}

function getStatusSettings(){
    const resultDiv = document.getElementById('collapseSettings');
    const isCollapsed = getCollapsedSettings();
    if (resultDiv === null) {
        return;
    }
    else if(isCollapsed){
        resultDiv.classList.remove("in");
        // resultDiv.setAttribute("aria-expanded", "false");
    }else{
        resultDiv.classList.add("in");
        // resultDiv.setAttribute("aria-expanded", "true");
    }
}

function getStatusAnalytics(){
    const resultDiv = document.getElementById('collapseAnalytics');
    const isCollapsed = getCollapsedSettings();
    if (resultDiv === null) {
        return;
    }
    else if(isCollapsed){
        resultDiv.classList.remove("in");
        resultDiv.setAttribute("aria-expanded", "false");
    }else{
        resultDiv.classList.add("in");
        resultDiv.setAttribute("aria-expanded", "true");
    }
}

function toggleCollapse(input){
    var type = input.href;
    var start = type.indexOf("#");
    type = type.substring(start + 1);

    if (type === "collapseUserActivity"){
        const isCollapsedActivity = getCollapsedActivity();
        if(isCollapsedActivity){
            localStorage.setItem('collapsedActivity', 'un-collapsed');
        }else{
            localStorage.setItem('collapsedActivity', 'collapsed');
        }
    }

    if (type === "collapseReports"){
        const isCollapsedReports = getCollapsedReports();
        if(isCollapsedReports){
            localStorage.setItem('collapsedReports', 'un-collapsed');
        }else{
            localStorage.setItem('collapsedReports', 'collapsed');
        }
    }

    if (type === "collapseSettings"){
        const isCollapsedSettings = getCollapsedSettings();
        if(isCollapsedSettings){
            localStorage.setItem('collapsedSettings', 'un-collapsed');
        }else{
            localStorage.setItem('collapsedSettings', 'collapsed');
        }
    }
}

function dontChangeAccordion(e) {
    e.stopPropagation();
}