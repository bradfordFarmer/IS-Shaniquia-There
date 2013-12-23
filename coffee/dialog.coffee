class  speaker
    constructor:( name , image, text) ->
        @name = name
        @image = image 
        @text =text

app.controller 'DialogController',
    class DialogController
        Conversation : []
        FinishConversating :->
            
        CreateConversation: -> 
            @Conversation.push 'Alexis', 'red', "I can't find Shaniquia can you help me" 
            
        init: -> 