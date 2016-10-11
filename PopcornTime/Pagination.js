var doc = makeDocument(`{{RECIPE}}`);
var type = "{{TYPE}}";
doc.addEventListener("select", load.bind(this));
doc.addEventListener("play", play.bind(this));

var getIndex = function(nodeList, el) {
    var i = 0;
    for (; i < nodeList.length; i++) {
        if (nodeList.item(i) == el) {
            return i;
        }
    }
    return -1;
}

var highlightSectionEvent = function(event) {
    var ele = event.target;
    var lockupList = ele.parentNode.childNodes;
    var index = getIndex(lockupList, ele);
    var diff = lockupList.length - index;
    var parentNode = ele.parentNode
    if (diff <= 8) {
        var nextPage = (lockupList.length / 50) + 1;
        highlightLockup(nextPage, function(data) {
          parentNode.innerHTML += data
          addEventListenersLockupElements(parentNode.childNodes)
        });
    }
    return;
};

var addEventListenersLockupElements = function(lockupElements) {
  for (var i = 0; i < lockupElements.length; i++) {
    lockupElements.item(i).addEventListener("highlight", highlightSectionEvent.bind(this));
  }
}

var lockupElements = doc.getElementsByTagName("lockup");
addEventListenersLockupElements(lockupElements)

if (type === "catalog") {
    defaultPresenter(doc);
} else {
    menuBarItemPresenter(doc);
}
