$(document).ready(function() {
  var Socket = "MozWebSocket" in window ? MozWebSocket : WebSocket;
  var ws     = new Socket("ws://localhost:8998");
  var paused = false;

  ws.onmessage = function(evt) {
    if (!paused) {
      $('#stream > tr.message').remove();
      $('#stream').prepend(evt.data);
    }
  };

  $('#stream > tr').focus(function() { paused = true; }, function() { paused = false; });
});
