using { /Verse.org/Simulation }

# Linkedlist for Tournament Stages
stagelist := class:
    var Tail:?stage = false
    var Current:stage = stage{}

    # Adds Node to Linked List
    # Basically adding a Head to linkedlist
    Add(Node:stage)<transacts>:void =
        defer:
            set Current = Node
        if(not Tail?) then set Tail = option{Node}
        else {set Current.Previous = option{Node}}

    # Returns the number of nodes in the list
    Length():int =
        var ListLength:int = 0
        if(var InCurrent:stage = Tail?):
            loop:
                set ListLength += 1
                if(Previous := InCurrent.Previous?):
                    set InCurrent = Previous
                else {break}
        ListLength
        
