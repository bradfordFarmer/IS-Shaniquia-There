// Generated by CoffeeScript 1.6.3
(function() {
  var DialogController, speaker;

  speaker = (function() {
    function speaker(name, image, text) {
      this.name = name;
      this.image = image;
      this.text = text;
    }

    return speaker;

  })();

  app.controller('DialogController', DialogController = (function() {
    function DialogController() {}

    DialogController.prototype.Conversation = [];

    DialogController.prototype.FinishConversating = function() {};

    DialogController.prototype.CreateConversation = function() {
      return this.Conversation.push('Alexis', 'red', "I can't find Shaniquia can you help me");
    };

    DialogController.prototype.init = function() {};

    return DialogController;

  })());

}).call(this);
