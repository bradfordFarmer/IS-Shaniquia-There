class Objective
    constructor:(name,description, failedMessage, objectid) ->
        @name = name
        @description =description
        @objectid = objectid
        @failedMessage=failedMessage
        @completed=false


    
class Object
    constructor: (hiddenObject,  id)->
        @id = id
        @hiddenObject= hiddenObject
    
class Grid
    constructor: (image,size, objectid)->
        @image= image
        @size= size
        @objectid= objectid
        
        
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

app = angular.module 'ShaniquaApp', []

app.controller 'GridController',
    class GridController
        CurrentObjective:0
        Objectives:[]
        Objects :[]
        Grids : []
        size:8
        length:4
        
        fillWithDummyObjects:-> 
            @Objects.push new Object  'none' , i for i in [@Objectives.length-1...@size] 
                
        createObjects: ->
            @Objects.push new Object 'Shaniquia',  @Objects.length
            @Objectives.push new Objective 'Shaniquia', 'Shaniquia is lost help find her', 'Hell no!', @Objects.length-1
            @Objects.push new Object "Shaniquia's purse", @Objects.length
            @Objectives.push new Objective "Shaniquia's purse", 'Shaniquia lost her pruse help her find it',"That's not my purse!", @Objects.length-1
            @Objects.push new Object "Shaniquia's lipstick", @Objects.length
            @Objectives.push new Objective "Shaniquia's lipstick", 'Shaniquia is lost her lipstick help her find it',"That's not my lipstick!", @Objects.length-1
            @fillWithDummyObjects()
        
        createGridPoints : ->
            @Grids.push new Grid 'Is '+@Objectives[@CurrentObjective].name+' There?', 20, @Objects[i].id for i in [0...@size] 
            shuffle(@Grids)
            
        checkGridPoint: (objectid)-> 
            found =false
            for object in @Objects 
                if object.id is objectid and object.id is @Objectives[@CurrentObjective].objectid
                  found =true  
                
            if found
                @Objectives[@CurrentObjective].completed= true
                alert 'found'+@Objectives[@CurrentObjective].name
                @CurrentObjective++
            else 
                alert @Objectives[@CurrentObjective].failedMessage
        init: ->
            @createObjects()
            @createGridPoints()