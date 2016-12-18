var doc = makeDocument(`{{RECIPE}}`);
var type = "{{TYPE}}";
doc.addEventListener("select", load.bind(this));
doc.addEventListener("play", play.bind(this));

var indexOf = function(element, array) {
    for (var i = 0; i < array.length; i++) {
        if (array.item(i) == element) {
            return i;
        }
    }
    return -1;
}

var highlightCellEvent = function(event) {
    
    var highlightedCell = event.target;
    var parentNode = highlightedCell.parentNode;
    var allCells = parentNode.childNodes;
    var highlightedCellIndex = indexOf(highlightedCell, allCells);
    var totalCells = allCells.length;
    var cellsUntilLastCell = totalCells - (highlightedCellIndex + 1);
    
    if ((cellsUntilLastCell <= 10) && !isLoading() && hasNextPage()) {
        loadNextPage(function(data) {
            doc.getElementById("lockups").insertAdjacentHTML("beforeend", data);
            addEventListeners();
        });
    }
    
    return;
};

var addEventListeners = function() {
    var lockupElements = doc.getElementsByTagName("lockup");
    for (var i = 0; i < lockupElements.length; i++) {
        lockupElements.item(i).addEventListener("highlight", highlightCellEvent.bind(this));
    }
}


addEventListeners();

if (type === "catalog") {
    defaultPresenter(doc);
} else {
    menuBarItemPresenter(doc);
}
