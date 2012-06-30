var chuck  = chuck || {};
var Socket = "MozWebSocket" in window ? MozWebSocket : WebSocket;

chuck.stream = (function (stream) {
  stream.start = function () {
    var ws = new Socket("ws://" + ws_server);
    ws.onmessage = function(evt) {
      $('#stream > tr.message').remove();
      $('#stream').prepend(evt.data);
    };
  };
  return stream;
})(chuck.stream || {});

/* TODO: reconnect */
$(document).ready(function() {
  chuck.stream.start();
});
