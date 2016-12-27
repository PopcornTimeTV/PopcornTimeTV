var search;

search.doc = makeDocument(`{{RECIPE}}`);

search.doc.addEventListener("select", load.bind(this));
search.doc.addEventListener("play", play.bind(this));

const segmentedControlElem = search.doc.getElementsByTagName("segmentBar").item(0);
const searchFieldElem = search.doc.getElementsByTagName("searchField").item(0);
const searchKeyboard = searchFieldElem.getFeature("Keyboard");

segmentedControlElem.addEventListener("highlight", function(event) {
    const selectedElement = event.target;
    const selectedMode = selectedElement.getAttribute("value");
    search.segmentBarDidChangeSegment(selectedMode);
    this.buildResults(search.doc, searchKeyboard.text);
});

menuBarSearchPresenter(search.doc);
