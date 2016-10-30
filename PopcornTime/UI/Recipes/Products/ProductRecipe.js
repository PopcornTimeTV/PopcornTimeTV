var doc = makeDocument(`{{RECIPE}}`);
doc.addEventListener("select", load.bind(this));
doc.addEventListener("play", play.bind(this));

var disappearEvent = new CustomEvent("disappear");
var appearEvent = new CustomEvent("appear");

doc.addEventListener("disappear", function(e) {
  disableThemeSong();
});

doc.addEventListener("appear", function(e) {
  updateWatchlistButton();
  enableThemeSong();
});

function viewDidDisappear() {
    doc.getElementById("watchlistButton").dispatchEvent(disappearEvent); // Get random element to dispatch event off.
}

function viewDidAppear() {
    doc.getElementById("watchlistButton").dispatchEvent(appearEvent); // Get random element to dispatch event off.
}

function updateWatchlistButton() {
    var watchlistButton = doc.getElementById("watchlistButton");
    if (watchlistButton.innerHTML.indexOf("button-remove") == -1) {
        watchlistButton.innerHTML = watchlistButton.innerHTML.replace("button-add","button-remove");
    } else {
        watchlistButton.innerHTML = watchlistButton.innerHTML.replace("button-remove","button-add");
    }
}

function changeSeason(number) {
    updateSeason(number, function(data) {
        doc.documentElement.innerHTML = data;
        navigationDocument.dismissModal();
    });
}

function updateWatchedlistButton() {
    var watchedlistButton = doc.getElementById("watchedlistButton");
    if (watchedlistButton.innerHTML.indexOf("button-watched") == -1) {
        watchedlistButton.innerHTML = watchedlistButton.innerHTML.replace("button-unwatched","button-watched");
    } else {
        watchedlistButton.innerHTML = watchedlistButton.innerHTML.replace("button-watched","button-unwatched");
    }
}

defaultPresenter(doc);
