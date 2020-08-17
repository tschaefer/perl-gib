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
