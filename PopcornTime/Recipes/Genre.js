var doc = makeDocument(`{{RECIPE}}`);
doc.addEventListener("select", load.bind(this));
doc.addEventListener("play", play.bind(this));
var highlightSectionEvent = function(event) {
    var ele = event.target,
    sectionID = ele.getAttribute("sectionID");
    if (sectionID) {
        var container = doc.getElementById(sectionID);
        highlightSection(sectionID, function(data) {
            container.innerHTML = data;
        });
        return;
    }
};
var listItemLockupElements = doc.getElementsByTagName("listItemLockup");
for (var i = 0; i < listItemLockupElements.length; i++) {
    listItemLockupElements.item(i).addEventListener("highlight", highlightSectionEvent.bind(this));
}
menuBarItemPresenter(doc);
