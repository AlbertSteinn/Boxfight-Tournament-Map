using { /Fortnite.com/Characters }
using { /Verse.org/Random }
using { /Verse.org/Simulation }


# Directed Acyclic Graph (DAG) to manage the tournament
tournament_graph := class:
    # Final base
    var TopBase:?base = false
    # Array of bases at the bottom
    var BottomBases:[]base = array{}
    # Tracks the base player is in
    var CurrentBase:[player]base = map{}
    # Tracks player elimination subscription
    var EliminationSubscription:[player]cancelable = map{}
    # Tracks the number of active players
    var ActivePlayers:[]player

    # Adds vertices(array of bases) to bottom of the graph
    Add(Bases:[]base)<transacts>:[]base =
        if(not TopBase?) then set TopBase = option{Bases[0]}
        else:
            # Randomize to make the base unpredictable each game round
            set BottomBases = Shuffle(BottomBases)
            # Creates a directed edge from each base to all bottom bases
            for(Base:Bases) do set Base.Parents = BottomBases
        # Bases becomes the bottom bases
        set BottomBases = Bases

    # Moves player to an active vertex (base) in next stage
    Traverse(Player:player):void =
        for:
            Base:CurrentBase[Player].Parents
            Base.IsActive?
            Base.BasePlayers.Length < 2
            # Update CurrentBase
            set CurrentBase[Player] = Base
            FortCharacter := Player.GetFortCharacter[]
        do:
            defer:
                if(Base.BasePlayers.Length = 2) then set Base.IsActive = false
            Base.Teleport(Player)
            option {EliminationSubscription[Player].Cancel()}
            Subcription := FortCharacter.EliminatedEvent().Subscribe(Base.OnBasePlayerEliminated)
            option {set EliminationSubscription[Player] = Subcription}
            return

    # Removes Player from ActivePlayers
    RemovePlayer(Player:player)<transacts>:void =
        set ActivePlayers = ActivePlayers.RemoveAllElements(Player)

