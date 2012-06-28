$(document).ready(function() {
  var Socket = "MozWebSocket" in window ? MozWebSocket : WebSocket;
  var ws     = new Socket("ws://localhost:8998");

  ws.onmessage = function(evt) {
    $('#stream').prepend(evt.data);
  };
});
