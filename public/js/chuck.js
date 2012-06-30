var chuck  = chuck || {};
chuck.home = (function (home) {
  home.tables = function () {
    $('body#page_home table.requests').tables();
  };
  return home;
})(chuck.home || {});

$(document).ready(function() {
  chuck.home.tables();
});
