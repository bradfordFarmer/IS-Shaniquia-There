###
    The Objectives are mearly a sub set of important infomation from the grid this is done to allow for caching and faster look up on the browser side because it is        faster to look up 5-10 objectives than it is to loop over 100+ grid points.
###
currentController ={}
class Objective
    constructor:(name,description, failedMessage, pointid) ->
        @name = name
        @description =description
        @pointid = pointid
        @failedMessage=failedMessage
        @completed=false
        
    
class GridPoint
    constructor: (image, name, description, failedMessage, size,pointid)->
        @id = pointid
        @image= image
        @size= size
        @name =name
        @description=description
        @failedMessage=failedMessage
        

shuffle = (array)-> 
    currentIndex = array.length
    temporaryValue  ={}
    randomIndex =0 
    while 0 isnt currentIndex
        randomIndex = Math.floor(Math.random() * currentIndex)
        currentIndex -= 1
        temporaryValue = array[currentIndex]
        array[currentIndex] = array[randomIndex]
        array[randomIndex] = temporaryValue
    array

    
app = angular.module 'ShaniquaApp', ['timer']

app.controller 'GridController',
    class GridController
        @$inject: ['$interval','$scope'] 
        CurrentObjective:0
        Objectives:[]
        Grids : []
        StopTimer:[]
        StageName: 'Shaniqua goes to the mall'
        size:19
        length:4 
        createObjectives:()->
            @Objectives.push new Objective point.name,point.description, point.failedMessage, point.id   for point in @Grids
            @Objectives[0].timer='0:00'
            @Objectives[0].timeinSeconds=-1
            @CurrentObjective=0
        createGridPoints : ()->
            @Grids.push new GridPoint 'green','Shaniqua',  'Shaniqua is lost help find her', 'Shaniqua', 20,  0
            @Grids.push new GridPoint 'blue',"Shaniqua's purse", 'Shaniqua lost her pruse help her find it', "her purse!", 20, 1
            @Grids.push new GridPoint 'black', "Shaniqua's lipstick",'Shaniqua is lost her lipstick help her find it', "her lipstick!",20,  2
            @createObjectives()
            nondummyItems =  @Grids.length-1
            @Grids.push new GridPoint 'red', '','','', 20, i  for i in [nondummyItems...@size] 
            shuffle(@Grids)
            
        checkGridPoint: (point)-> 
            found =false
            if point.id is @Objectives[@CurrentObjective].pointid
                found =true
            if found
                @Objectives[@CurrentObjective].completed= true
                @rootScope.$parent.$broadcast 'thank-you', @Objectives[@CurrentObjective].name 
                @CurrentObjective++
                if @CurrentObjective is @Objectives.length
                    @StopTimer()
            else 
                @Objectives[@CurrentObjective].timeinSeconds+=10
                @rootScope.$parent.$broadcast 'failed-to-find',@Objectives[@CurrentObjective].failedMessage 

                @rootScope.$broadcast 'timer-add-time', 10 
        constructor: (@interval,$scope)->
            @rootScope=$scope
            currentController=this.Objectives
            @StopTimer = ->  @rootScope.$parent.$broadcast 'timer-stop';
            @rootScope.$on 'finished-conversation' , (event)->
                event.currentScope.grid.createGridPoints()

                
###
   Dialog functionallity.
###                
class  speaker
    constructor:( name , image, text) ->
        @name = name
        @image = image 
        @text =text

app.controller 'DialogController',
    class DialogController
        CurrentDialog:[]
        CurrentDialogIndex:0
        Showing: false
        Finished : false
        IsGenericMessage : false
        isRedMessage : false
        isGreenMessage : false
        Conversation : []
        @$inject: ['$interval','$scope']
        ThankYou : (item)->
            @Conversation=[];
            @Conversation.push(new speaker('Alexis ', 'red', "You found " + item )) 
            @IsGenericMessage=true
            @Showing=true 
            @isGreenMessage=true
            @CurrentDialog.push @Conversation[0]
        Failed : (item)->
            @Conversation=[];
            @Conversation.push(new speaker('Alexis ', 'red', "That is not " + item )) 
            @IsGenericMessage=true
            @Showing=true 
            @isRedMessage=true
            @CurrentDialog.push @Conversation[0]
        FinishConversating :->
            @rootScope.$parent.$broadcast 'timer-start'
            @rootScope.$parent.$broadcast 'finished-conversation' 
            @Showing=false
        CreateConversation: -> 
            @Conversation.push(new speaker('Phone', 'red', "Ring Ring ")) 
            @Conversation.push(new speaker('Alexis', 'red', "Hello")) 
            @Conversation.push(new speaker('Caller', 'red', "Is Shaniqua there?")) 
            @Conversation.push(new speaker('Alexis', 'red', "No I think she is at the mall")) 
            @CurrentDialog.push(@Conversation[0]);
        CreateFinishingConversation : (time)->
            @Conversation=[];
            @Conversation.push(new speaker('Alexis ', 'red', "You Found her and her stuff in: "+time )) 
            @Finished=true
            @Showing=true 
            @CurrentDialog.push @Conversation[0]
        NextDialog:->
            @CurrentDialogIndex++ 
            @CurrentDialog.pop()
            if @CurrentDialogIndex is @Conversation.length and not @Finished  and not @IsGenericMessage
                @FinishConversating();
            else if not @Finished and not @IsGenericMessage
                @CurrentDialog.push(@Conversation[@CurrentDialogIndex])
            else 
                @Showing=false
                @IsThankYou=false
            @isRedMessage=false
            @isGreenMessage=false
        constructor:(@interval,$scope)->
            @rootScope=$scope
            @CreateConversation()
            @Showing=true
            @rootScope.$on 'thank-you' , (event,item)->
                event.currentScope.dialog.ThankYou(item)
            @rootScope.$on 'failed-to-find' , (event,item)->
                event.currentScope.dialog.Failed(item)
            @rootScope.$on 'found-everything' , (event,time)->
                event.currentScope.dialog.CreateFinishingConversation(time)