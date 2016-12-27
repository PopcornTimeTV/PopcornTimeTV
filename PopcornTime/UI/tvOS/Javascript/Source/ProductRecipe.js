var doc = makeDocument(`{{RECIPE}}`);
doc.addEventListener("select", load.bind(this));
doc.addEventListener("play", play.bind(this));


var disappearEvent = new CustomEvent("disappear");
var appearEvent = new CustomEvent("appear");

doc.addEventListener("disappear", function(e) {
  disableThemeSong();
});

doc.addEventListener("appear", function(e) {
  enableThemeSong();
});

function viewDidDisappear() {
    var element = doc.getElementById("watchlistButton");
    
    if (typeof element !== 'undefined') {
        element.dispatchEvent(disappearEvent); // Get random element to dispatch event off.
    }
}

function viewDidAppear() {
    var element = doc.getElementById("watchlistButton");
    
    if (typeof element !== 'undefined') {
        element.dispatchEvent(appearEvent); // Get random element to dispatch event off.
    }
}

function updateWatchlistButton() {
    var watchlistButton = doc.getElementById("watchlistButton");
    if (typeof watchlistButton === 'undefined') { return; }
    const src = "resource://" + watchlistStatusButtonImage();
    watchlistButton.firstChild.setAttribute("src", src);
}

function changeSeason(number) {
    updateSeason(number, function(data) {
        doc.getElementById("episodeShelf").innerHTML = data;
        navigationDocument.dismissModal();
    });
}

function updateWatchedButton() {
    var watchedButton = doc.getElementById("watchedButton");
    if (typeof watchedButton === 'undefined') { return; }
    const src = "resource://" + watchedStatusButtonImage();
    watchedButton.firstChild.setAttribute("src", src);
}

defaultPresenter(doc);
