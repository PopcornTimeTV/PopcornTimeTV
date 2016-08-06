var doc = makeDocument(`{{RECIPE}}`);
doc.addEventListener("select", load.bind(this));
doc.addEventListener("play", play.bind(this));
doc.addEventListener("unload", function(e) {
  disableThemeSong();
});
defaultPresenter(doc);