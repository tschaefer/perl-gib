hljs.initHighlightingOnLoad();
document.addEventListener('DOMContentLoaded', (event) => {
    document.querySelectorAll('pre code').forEach((block) => {
        hljs.highlightBlock(block);
    });
    document.querySelectorAll('h3 code').forEach((block) => {
        hljs.highlightBlock(block);
    });
});

function navbar_toggle() {
    var nav = document.getElementById("navbar");
    nav.style.display === "block"
      ? nav.style.display = "none"
      : nav.style.display = "block";
}

function code_toggle() {
    var code = document.getElementById("code");
    var content = document.getElementById("content");
    if (code.style.display === "block") {
      code.style.display = "none";
      content.style.display = "block";
    }
    else {
      code.style.display = "block";
      content.style.display = "none";
    }
}
