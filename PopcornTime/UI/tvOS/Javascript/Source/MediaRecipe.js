
var {{RECIPE_NAME}};

{{RECIPE_NAME}}.doc = makeDocument(`{{RECIPE}}`);

{{RECIPE_NAME}}.doc.addEventListener("select", load.bind(this));

/**
 * @description - get the index of an element in an array
 * @param {Array.Element} element - the element in the array
 * @param {Array} array - array to be indexed
 */
var indexOf = function(element, array) {
    for (var i = 0; i < array.length; i++) {
        if (array.item(i) == element) {
            return i;
        }
    }
    return -1;
}

/**
 * @description - called when a cell is highlighted
 * @param {IKDOMElement} event - the cell that was highlighted
 */
var highlightCellEvent = function(event, recipe) {
    var highlightedCell = event.target;
    var parentNode = highlightedCell.parentNode;
    var allCells = parentNode.childNodes;
    var highlightedCellIndex = indexOf(highlightedCell, allCells);
    var totalCells = allCells.length;
    var cellsUntilLastCell = totalCells - (highlightedCellIndex + 1);

    if ((cellsUntilLastCell <= 10) && !recipe.isLoading && recipe.hasNextPage) {
        recipe.loadNextPage(function(data) {
            const element = recipe.doc.getElementsByTagName("collectionList").item(0);
            refresh(element, data, recipe.doc);
            addEventListeners(recipe);
        });
    }
}

/**
 * @description - add's highlight event listeners to all paginated cells in the view
 */
var addEventListeners = function(recipe) {
    var lockupElements = recipe.doc.getElementsByTagName("lockup");
    
    for (var i = 0; i < lockupElements.length; i++) {
        var element = lockupElements.item(i);
        // do not add the highlight listener to "continue watching" elements as they are not paginated.
        if (element.id === "continueWatchingLockup") { return }
        
        element.addEventListener("highlight", function(event) {
            highlightCellEvent(event, recipe);
        });
    }
}

/**
 * @description - refresh the DOM. Child elements will be overridden.
 * @param {IKDOMElement} element - any element you wish to append content to it's innerHTML
 * @param {String} stringData - the new HTML you wish to append
 */
function refresh(element, stringData, doc) {
    
    var domImplementation = doc.implementation;
    
    var lsParser = domImplementation.createLSParser(1, null);
    var lsInput = domImplementation.createLSInput();
    
    //add the new input element to the document by providing the newly created input, the context,
    //and the operator integer flag (1 to append as child, 2 to overwrite existing children)
    lsInput.stringData = stringData;
    lsParser.parseWithContext(lsInput, element, 2);
}

addEventListeners({{RECIPE_NAME}});

menuBarItemPresenter({{RECIPE_NAME}}.doc);
