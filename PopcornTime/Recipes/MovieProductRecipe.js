var doc = makeDocument(`{{RECIPE}}`);
doc.addEventListener("select", load.bind(this));
doc.addEventListener("play", play.bind(this));
doc.addEventListener("unload", function(e) {
                     disableThemeSong();
                     });
defaultPresenter(doc);
function updateWatchlistButton(){
    console.log("I am here");
    var favoriteButton = doc.getElementById("favoriteButton");
    if(favoriteButton.innerHTML.indexOf("button-rated")==-1)favoriteButton.innerHTML=favoriteButton.innerHTML.replace("button-rate","button-rated");
    else
        favoriteButton.innerHTML=favoriteButton.innerHTML.replace("button-rated","button-rate");
}