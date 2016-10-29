var doc = makeDocument(`{{RECIPE}}`);
doc.addEventListener("select", load.bind(this));

var disappearEvent = new CustomEvent("disappear");
var appearEvent = new CustomEvent("appear");

doc.addEventListener("disappear", function(e) {
  console.log("disappear triggered");
  disableThemeSong();
});

doc.addEventListener("appear", function(e) {
  console.log("appear triggered");
  enableThemeSong();
});

function viewDidDisappear() {
    doc.getElementById("watchlistButton").dispatchEvent(disappearEvent); // Get random element to dispatch event off.
}

function viewDidAppear() {
    doc.getElementById("watchlistButton").dispatchEvent(appearEvent); // Get random element to dispatch event off.
}

doc.addEventListener("play", play.bind(this));

defaultPresenter(doc);

function updateWatchlistButton() {
    var watchlistButton = doc.getElementById("watchlistButton");
    if(watchlistButton.innerHTML.indexOf("button-rated")==-1)watchlistButton.innerHTML=watchlistButton.innerHTML.replace("button-rate","button-rated");
    else
        watchlistButton.innerHTML=watchlistButton.innerHTML.replace("button-rated","button-rate");
}
