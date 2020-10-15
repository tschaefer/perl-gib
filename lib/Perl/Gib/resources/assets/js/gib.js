hljs.initHighlightingOnLoad();
document.addEventListener('DOMContentLoaded', (event) => {
    document.querySelectorAll('pre code').forEach((block) => {
        hljs.highlightBlock(block);
    });
    document.querySelectorAll('h3 code').forEach((block) => {
        hljs.highlightBlock(block);
    });
});
