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
        stages : [{'none':'found'}]
        LevelLoader:{}
        Showing:false
        loadLevel:(levelurl)->
            scope= @rootScope
            @Showing=false
            @LevelLoader.getLevels(levelurl ,scope).
                success( (data, status)->
                    scope.$parent.$broadcast 'level-downloaded' , data
                    scope.$parent.$broadcast 'remove-loading-screen' , 1
                ).
                error( (data, status)->
                    alert 'error'
                )
        getSpeakerList: (scope)->
            @LevelLoader.getLevels('json/characters.json', scope).
                success( (data, status)->
                    scope.$parent.$broadcast 'speakers-downloaded' , data
                ).
                error( (data, status)->
                    alert 'error'
                )
        getLevelList: (scope,@stages, showing)->
            @rootScope.$parent.$broadcast 'show-loading-screen' , 1
            @LevelLoader.getLevels('levels/levellist.json', scope).
                success( (data, status)->
                    scope.$parent.$broadcast 'level-list-downloaded' , data
                    scope.$parent.$broadcast 'remove-loading-screen' , 1
                ).
                error( (data, status)->
                    alert 'error'
                )
        getBackgroundStyle:(image)->
            { 
                'width':'200px'
                'height':'200px'
                'background-image': 'url('+image+')'
            }
            
        constructor: (@interval,$scope,@LevelLoader)->
            @rootScope = $scope
            @rootScope.$on 'level-list-downloaded' , (event,data)->
                event.currentScope.levels.Showing=true
                event.currentScope.levels.stages=data
            @getSpeakerList($scope)
            @getLevelList($scope, @stages, @Showing)
            
###
    The grid Controller
###

class Objective
    constructor:(@name,@description, @failedMessage, @pointid,@image) ->
       
    
class GridPoint
    constructor: (@image, @backImage,@name, @description, @failedMessage, @size,@pointid,@PrimaryObjective)->
         @subIndexes=[]

app.controller 'GridController',
    class GridController
        @$inject: ['$interval','$scope'] 
        CurrentObjective:0
        Objectives:[]
        Grids : []
        StopTimer:[]
        Showing:false      
        getObjectiveStyle:(objective)->
           { 
                'width':'50px'
                'height':'50px'
                'background-image':  'url('+@levelData.BackgroundImage+')'
                'background-repeat':'no-repeat'
                'background-position' :-objective.image.row+'px '+  -objective.image.col+'px'
            } 
    
        getBackgroundStyle:(point)->
            { 
                'width':'50px'
                'height':'50px'
                'background-image':  'url('+@levelData.BackgroundImage+')'
                'background-repeat':'no-repeat'
                'background-position' :-point.backImage.row+'px '+  -point.backImage.col+'px'
            }
           
        
        getForegroundStyle:(point)->
            {
                'width':'50px'
                'height':'50px'
                'background-image': 'url('+@levelData.ForegroundImage+')'
                'background-repeat':'no-repeat'
                'background-position' : -point.image.row+'px '+  -point.image.col+'px'
            }
         

        createForegrounds : (size)-> 
            foreground=[]
            length =@levelData.spriteSheet.squareLength*@levelData.spriteSheet.squareLength
            j=0
            for i in [0...size]
                row = j% @levelData.spriteSheet.squareLength
                col = Math.floor(j/@levelData.spriteSheet.squareLength)
                foreground[i]= { row:row*50 , col:col*50}
                j++;
                if j is length 
                    j= 0

            shuffle(foreground)
            
        createPrimaryObjectives:()->
            for point in @Grids
                if point.PrimaryObjective
                    @Objectives.push new Objective point.name,point.description, point.failedMessage, point.id, point.backImage 
                    
        createSubObjectives:(currentPoint)->
            hassub= false
            for pointIndex in currentPoint.subIndexes
                hassub=true
                point = @Grids[pointIndex]
                @Objectives.push new Objective point.name,point.description, point.failedMessage, point.id, point.backImage 
            hassub
        RecursivePointCreator: (points, foregrounds, startingIndex)-> 
            for point in points
                 @Grids.push new GridPoint foregrounds[startingIndex], point.ImageLocation,point.Name,  point.Objective, point.FoundMessage, @levelData.spriteSheet.boxSize,  startingIndex,point.PrimaryObjective
                tempIndex=startingIndex;
                startingIndex++
                if point.FoundConversation
                    if point.FoundConversation.NewItems
                        startingIndex=@RecursivePointCreator point.FoundConversation.NewItems , foregrounds, startingIndex
                        for i in [tempIndex+1...startingIndex]
                            @Grids[tempIndex].subIndexes.push i
            ++startingIndex

        createGridPoints : ()->
            foregrounds = @createForegrounds(@levelData.size)
            foregroundIndex=0
            foregroundIndex= @RecursivePointCreator @levelData.Items , foregrounds, foregroundIndex  
            @createPrimaryObjectives()
            nondummyItems =  foregroundIndex
            @Grids.push new GridPoint foregrounds[i], randomWrong(), '','','', 20, i  for i in [nondummyItems...@levelData.size] 
            shuffle(@Grids)
            
        checkGridPoint: (point)-> 
            found =false
            i=0
            j=0
            done= true
            for  objective in @Objectives
                if objective.pointid is point.id
                    found=true
                    j=i
                if objective.completed=false
                    done=false
                i++
            if found
                @Objectives[j].completed= true
                @rootScope.$parent.$broadcast 'thank-you', @Objectives[j].name 
                if @createSubObjectives point
                    done=false
                    @rootScope.$parent.$broadcast 'more-items',@Objectives[@CurrentObjective].failedMessage 
                    @PauseTimer() 
                if done
                    @StopTimer()
            else 
                @rootScope.$parent.$broadcast 'failed-to-find',@Objectives[@CurrentObjective].failedMessage 
                @rootScope.$broadcast 'timer-add-time', 10  
        constructor: (@interval,$scope)->
            @rootScope=$scope
            currentController=this.Objectives
            @StopTimer = ->  @rootScope.$parent.$broadcast 'timer-stop';
            @PauseTimer= -> @rootScope.$parent.$broadcast 'timer-pause';
            @rootScope.$on 'finished-conversation' , (event)->
                event.currentScope.grid.Showing=true
            @rootScope.$on 'level-downloaded' , (event,item)->
                event.currentScope.grid.levelData= item
                event.currentScope.grid.createGridPoints() 
###
   Dialog functionallity.
###                
class  speaker
    constructor:( @name , @image, @text) ->


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
        ThankYou : (thanksMessage)->
            @Showing=true;
            @Conversation=[];
            @Conversation.push(new speaker('', '',thanksMessage)) 
            @isGenericMessage=true
            @Showing=true 
            @isGreenMessage=true
            @CurrentDialog.push @Conversation[0]
        Failed : (item)->
            @Conversation=[];
            @Conversation.push(new speaker('', '', "That is not " + item )) 
            @isGenericMessage=true
            @Showing=true 
            @isRedMessage=true
            @CurrentDialog.push @Conversation[0]
        MoreItems :(message)->
            currentSpeaker =@speakers[message.SpeakerId]
            @Conversation.push(new speaker(currentSpeaker.Name , currentSpeaker.Image, message.Text)) 
            @CurrentDialog.push(@Conversation[0]);
            @Showing=true
            
        FinishConversating :->
            @rootScope.$parent.$broadcast 'timer-start'
            @rootScope.$parent.$broadcast 'finished-conversation' 
            @Showing=false
        CreateConversation: -> 
            for conversation in @levelData.OpeningConversation
                currentSpeaker =@speakers[conversation.SpeakerId]
                @Conversation.push(new speaker(currentSpeaker.Name , currentSpeaker.Image, conversation.Text)) 
            @CurrentDialog.push(@Conversation[0]);
            @Showing=true
        CreateFinishingConversation : (time)->
            currentSpeaker =@speakers[@levelData.EndingConversation.SpeakerId]
            @Conversation=[]
            @Conversation.push(new speaker(currentSpeaker.Name , currentSpeaker.Image, @levelData.EndingConversation.Text)) 
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
            @rootScope.$on 'speakers-downloaded' , (event,item)->
                 event.currentScope.dialog.speakers= item
            @rootScope.$on 'level-downloaded' , (event,item)->
                 event.currentScope.dialog.levelData= item
                 event.currentScope.dialog.CreateConversation()
            @rootScope.$on 'thank-you' , (event,item)->
                event.currentScope.dialog.ThankYou(item)
            @rootScope.$on 'failed-to-find' , (event,item)->
                event.currentScope.dialog.Failed(item)
            @rootScope.$on 'more-items' , (event,message)->
                event.currentScope.dialog.MoreItems(message)
            @rootScope.$on 'found-everything' , (event,time)->
                event.currentScope.dialog.CreateFinishingConversation(time)