var doc = makeDocument(`{{RECIPE}}`);
doc.addEventListener("select", load.bind(this));
doc.addEventListener("play", play.bind(this));

function viewDidDisappear() {
    disableThemeSong();
}

function viewDidAppear() {
    // If element is not nil it means the view has definately appeared.
    if (doc.getElementById("watchlistButton") == -1) { return; }
    enableThemeSong();
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
