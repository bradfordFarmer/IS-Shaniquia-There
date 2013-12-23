###
    The Objectives are mearly a sub set of important infomation from the grid this is done to allow for caching and faster look up on the browser side because it is        faster to look up 5-10 objectives than it is to loop over 100+ grid points.
###
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
objectiveTimer=(Objective)->
    setInterval startTimer(Objective),1000
    Objective.timeinSeconds++
    mins = Objective.timeinSeconds%60
    secondsRemainder = Objective.timeinSeconds-(Objective.timeinSeconds * mins)
    Objective.timer= mins + ':'+secondsRemainder
    
app = angular.module 'ShaniquaApp', []

app.controller 'GridController',
    class GridController
        CurrentObjective:0
        Objectives:[]
        Grids : []
        size:8
        length:4
        
        createObjectives: ->
            @Objectives.push new Objective point.name,point.description, point.failedMessage, point.id   for point in @Grids
            @Objectives[0].timer='0:00';
            @Objectives[0].timeinSeconds=-1
            objectiveTimer(@Objectives[0]);
        createGridPoints : ->
            @Grids.push new GridPoint 'green','Shaniqua',  'Shaniqua is lost help find her', 'Hell no!', 20,  0
            @Grids.push new GridPoint 'blue',"Shaniqua's purse", 'Shaniqua lost her pruse help her find it', "That's not my purse!", 20, 1
            @Grids.push new GridPoint 'black', "Shaniqua's lipstick",'Shaniqua is lost her lipstick help her find it', "That's not my lipstick!",20,  2
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
                alert 'Found '+@Objectives[@CurrentObjective].name
                @CurrentObjective++
                if @CurrentObjective is @Objectives.length
                    clearInterval()
                else
                    @Objectives[@CurrentObjective].timer='0:00';
                    @Objectives[@CurrentObjective].timeinSeconds=-1
                    objectiveTimer(@Objectives[@CurrentObjective]);
               
            else 
                @Objectives[@CurrentObjective].timeinSeconds+=10
                alert @Objectives[@CurrentObjective].failedMessage + ': 10 sec  added'
        init: ->
            @createGridPoints()
            
            