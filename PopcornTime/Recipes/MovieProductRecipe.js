var doc = makeDocument(`{{RECIPE}}`);
doc.addEventListener("select", load.bind(this));
doc.addEventListener("play", play.bind(this));
doc.addEventListener("unload", function(e) {
  disableThemeSong();
});
defaultPresenter(doc);
function updateWatchlistButton() {
    var watchlistButton = doc.getElementById("watchlistButton");
    if(watchlistButton.innerHTML.indexOf("button-rated")==-1)watchlistButton.innerHTML=watchlistButton.innerHTML.replace("button-rate","button-rated");
    else
        watchlistButton.innerHTML=watchlistButton.innerHTML.replace("button-rated","button-rate");
}
