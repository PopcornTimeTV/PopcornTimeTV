var doc = makeDocument(`{{RECIPE}}`);
doc.addEventListener("select", load.bind(this));
doc.addEventListener("play", play.bind(this));

function changeImage(url) {
    updateImage(url, function(data) {
        doc.getElementById("backgroundImage").innerHTML = data;
    });
}

defaultPresenter(doc);
