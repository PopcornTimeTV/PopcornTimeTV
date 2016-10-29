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
    doc.getElementById("watchlistButton").dispatchEvent(disappearEvent); // Get random element to dispatch event off.
}

function viewDidAppear() {
    doc.getElementById("watchlistButton").dispatchEvent(appearEvent); // Get random element to dispatch event off.
}


defaultPresenter(doc);
function updateWatchlistButton() {
    var watchlistButton = doc.getElementById("watchlistButton");
    if(watchlistButton.innerHTML.indexOf("button-rated")==-1)watchlistButton.innerHTML=watchlistButton.innerHTML.replace("button-rate","button-rated");
    else
        watchlistButton.innerHTML=watchlistButton.innerHTML.replace("button-rated","button-rate");
}

function changeSeason(number) {
    updateSeason(number, function(data) {
        doc.documentElement.innerHTML = data;
        navigationDocument.dismissModal();
    });
}
