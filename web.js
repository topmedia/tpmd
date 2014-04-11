var express = require('express');
var logfmt = require("logfmt");
var app = express();

var autotask_base = 'https://ww7.autotask.net/Autotask/AutotaskExtend/ExecuteCommand.aspx?'

app.use(logfmt.requestLogger());

app.get('/at/:code/:argument/:value', function(req, res) {
  res.redirect(autotask_base + 'Code=' + req.params.code + '&' + req.params.argument + '=' + req.params.value);
});

var port = Number(process.env.PORT || 5000);
app.listen(port, function() {
  console.log("Listening on " + port);
});
