var doc = makeDocument(`{{RECIPE}}`);
doc.addEventListener("select", load.bind(this));
doc.addEventListener("play", play.bind(this));

const segmentedControlElem = doc.getElementsByTagName("segmentBar").item(0);
const searchFieldElem = doc.getElementsByTagName("searchField").item(0);
const searchKeyboard = searchFieldElem.getFeature("Keyboard");

segmentedControlElem.addEventListener("highlight", function(event) {
    const selectedElement = event.target;
    const selectedMode = selectedElement.getAttribute("value");
    segmentBarDidChangeSegment(selectedMode);
    this.buildResults(doc, searchKeyboard.text);
});

menuBarSearchPresenter(doc);
