hljs.initHighlightingOnLoad();
document.addEventListener('DOMContentLoaded', (event) => {
    document.querySelectorAll('pre code').forEach((block) => {
        hljs.highlightBlock(block);
    });
    document.querySelectorAll('h3 code').forEach((block) => {
        hljs.highlightBlock(block);
    });
});

function filter_list() {
    var input, filter, ul, li, a, i, text;
    input = document.getElementById('index-filter');
    console.log(input);
    filter = input.value.toUpperCase();
    ul = document.getElementById('index-list');
    li = ul.getElementsByTagName('li');

    for (i = 0; i < li.length; i++) {
        a = li[i].getElementsByTagName('a')[0];
        text = a.textContent || a.innerText;
        if (text.toUpperCase().indexOf(filter) > -1) {
            li[i].style.display = '';
        } else {
            li[i].style.display = 'none';
        }
    }
}
