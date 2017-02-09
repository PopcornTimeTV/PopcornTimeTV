
var {{RECIPE_NAME}};

{{RECIPE_NAME}}.doc = makeDocument(`{{RECIPE}}`);

{{RECIPE_NAME}}.doc.addEventListener("select", load.bind(this));
{{RECIPE_NAME}}.doc.addEventListener("play", play.bind(this));


var disappearEvent = new CustomEvent("disappear");
var appearEvent = new CustomEvent("appear");

{{RECIPE_NAME}}.doc.addEventListener("disappear", function(e) {
  {{RECIPE_NAME}}.disableThemeSong();
});

{{RECIPE_NAME}}.doc.addEventListener("appear", function(e) {
  {{RECIPE_NAME}}.enableThemeSong();
});

function viewDidDisappear() {
    var element = {{RECIPE_NAME}}.doc.getElementById("watchlistButton");
    
    if (typeof element !== 'undefined') {
        element.dispatchEvent(disappearEvent); // Get random element to dispatch event off.
    }
}

function viewDidAppear() {
    var element = {{RECIPE_NAME}}.doc.getElementById("watchlistButton");
    
    if (typeof element !== 'undefined') {
        element.dispatchEvent(appearEvent); // Get random element to dispatch event off.
    }
}

defaultPresenter({{RECIPE_NAME}}.doc);
