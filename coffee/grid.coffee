###
    The Objectives are mearly a sub set of important infomation from the grid this is done to allow for caching and faster look up on the browser side because it is        faster to look up 5-10 objectives than it is to loop over 100+ grid points.
###
### 
    app setup
###
app = angular.module 'ShaniquaApp', ['timer']
currentController ={}

### 
    general Math functions
###
randomWrong = ->
    indexes = [{ row:50, col:0} , {row:150,col:0}, {row:0, col:50}, {row:100,col:50}, {row:150,col:50}]
    i= Math.floor Math.random()*5 
    indexes[i];
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


    
### 
    httpFactories
###

app.factory 'LevelLoader' , ($http,$rootScope)->
    {
        getLevels : (url,scope)->
            $rootScope.$broadcast 'show-loading-screen' , 1
            $http.get(url)
    }
###
   Level functionallity.
###   
app.controller 'LevelController',
    class LevelController
        @$inject: ['$interval','$scope' ,'LevelLoader'] 
        levels : [{'none':'found'}]
        loadLevel:(levelurl)->
             scope= @rootScope
            @LevelLoader.getLevels(levelurl ,scope).
                success( (data, status)->
                    scope.$parent.$broadcast 'level-downloaded' , data
                    scope.$parent.$broadcast 'remove-loading-screen' , 1
                ).
                error( (data, status)->
                    alert 'error'
                )
                
        getLevelList: (scope,levels)->
            @rootScope.$parent.$broadcast 'show-loading-screen' , 1
            @LevelLoader.getLevels('levels/levellist.json', @scope).
                success( (data, status)->
                    levels=data
                    scope.$parent.$broadcast 'remove-loading-screen' , 1
                ).
                error( (data, status)->
                    alert 'error'
                )
            
        constructor: (@interval,$scope,@LevelLoader)->
            @rootScope = $scope
            @getLevelList($scope, @levels)
            

###
    The grid Controller
###

class Objective
    constructor:(name,description, failedMessage, pointid,image) ->
        @name = name
        @description =description
        @pointid = pointid
        @failedMessage=failedMessage
        @completed=false
        @image = image
        
    
class GridPoint
    constructor: (image, backImage,name, description, failedMessage, size,pointid)->
        @id = pointid
        @image= image
        @backImage=backImage
        @size= size
        @name =name
        @description=description
        @failedMessage=failedMessage
    

app.controller 'GridController',
    class GridController
        @$inject: ['$interval','$scope'] 
        CurrentObjective:0
        Objectives:[]
        Grids : []
        StopTimer:[]
        ForegroundImageName:'backgrounds.png'
        BackgroundImageName:'items.png'
        StageName: 'Shaniquia in the mall'
        size:100
        spriteSheet:{
            boxSize:50
            squareLength:4
        }
        length:4 
        getObjectiveStyle:(objective)->
           { 
                'width':'50px'
                'height':'50px'
                'background-image': 'url("images/items.png")'
                'background-repeat':'no-repeat'
                'background-position' :-objective.image.row+'px '+  -objective.image.col+'px'
            } 
    
        getBackgroundStyle:(point)->
            { 
                'width':'50px'
                'height':'50px'
                'background-image': 'url("images/items.png")'
                'background-repeat':'no-repeat'
                'background-position' :-point.backImage.row+'px '+  -point.backImage.col+'px'
            }
           
        
        getForegroundStyle:(point)->
            {
                'width':'50px'
                'height':'50px'
                'background-image': 'url("images/backgrounds.png") '
                'background-repeat':'no-repeat'
                'background-position' : -point.image.row+'px '+  -point.image.col+'px'
            }
         

        createForegrounds : (size)-> 
            foreground=[]
            length =@spriteSheet.squareLength*@spriteSheet.squareLength
            j=0
            for i in [0...size]
                
                row = j% @spriteSheet.squareLength
                col = Math.floor(j/@spriteSheet.squareLength)
                foreground[i]= { row:row*50 , col:col*50}
                j++;
                if j is length 
                    j= 0

            shuffle(foreground)
            
        createObjectives:()->
            @Objectives.push new Objective point.name,point.description, point.failedMessage, point.id, point.backImage   for point in @Grids
            @Objectives[0].timer='0:00'
            @Objectives[0].timeinSeconds=-1
            @CurrentObjective=0
        createGridPoints : ()->
            foregrounds = @createForegrounds(@size)
            @Grids.push new GridPoint foregrounds[0], {row:0,  col:0},'Shaniqua',  'Shaniqua is lost help find her', 'Shaniqua', 20,  0
            @Grids.push new GridPoint foregrounds[1],{row:50, col:50},"Shaniqua's purse", 'Shaniqua lost her pruse help her find it', "her purse!", 20, 1
            @Grids.push new GridPoint foregrounds[2],{row:100,col:0}, "Shaniqua's lipstick",'Shaniqua is lost her lipstick help her find it', "her lipstick!",20,  2
            @createObjectives()
            nondummyItems =  @Grids.length-1
            @Grids.push new GridPoint foregrounds[i], randomWrong(), '','','', 20, i  for i in [nondummyItems...@size] 
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
        isGenericMessage : false
        isRedMessage : false
        isGreenMessage : false
        Conversation : []
        @$inject: ['$interval','$scope']
        ThankYou : (item)->
            @Conversation=[];
            @Conversation.push(new speaker('Alexis ', 'red', "You found " + item )) 
            @isGenericMessage=true
            @Showing=true 
            @isGreenMessage=true
            @CurrentDialog.push @Conversation[0]
        Failed : (item)->
            @Conversation=[];
            @Conversation.push(new speaker('Alexis ', 'red', "That is not " + item )) 
            @isGenericMessage=true
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
            @Showing=true
        CreateFinishingConversation : (time)->
            @Conversation=[];
            @Conversation.push(new speaker('Alexis ', 'red', "You Found her and her stuff in: "+time )) 
            @Finished=true
            @Showing=true 
            @CurrentDialog.push @Conversation[0]
        NextDialog:->
            @CurrentDialogIndex++ 
            @CurrentDialog.pop()
            if @CurrentDialogIndex is @Conversation.length and not @Finished  and not @isGenericMessage
                @FinishConversating();
            else if not @Finished and not @isGenericMessage
                @CurrentDialog.push(@Conversation[@CurrentDialogIndex])
            else 
                @Showing=false
            @isRedMessage=false
            @isGreenMessage=false
        constructor:(@interval,$scope)->
            @rootScope=$scope
            @rootScope.$on 'level-downloaded' , (event,item)->
                 event.currentScope.dialog.CreateConversation() 
            @rootScope.$on 'thank-you' , (event,item)->
                event.currentScope.dialog.ThankYou(item)
            @rootScope.$on 'failed-to-find' , (event,item)->
                event.currentScope.dialog.Failed(item)
            @rootScope.$on 'found-everything' , (event,time)->
                event.currentScope.dialog.CreateFinishingConversation(time)