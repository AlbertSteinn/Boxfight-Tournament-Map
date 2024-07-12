using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Verse.org/Simulation }


# Superclass for Stages, serving as node in the linked list
stage := class<unique>:
    @editable
    Accolade:accolades_device = accolades_device{}

    var Previous:?stage = false
    var Devices:device = device{}

    # Returns an array of bases in the stage
    GetBases()<transacts>:[]base = array{}

    # Returns an array of players in the Stage
    GetStagePlayers()<transacts>:[]player =
        Concatenate(for(Base:GetBases()) do Base.BasePlayers)

    # Returns the total number of players in the current stage and all preceding stages.
    # It does this by recursively summing the number of players in each stage, traversing backward through the linked list of stages.
    RecursivePlayerCount()<transacts>:int =
        if(Prev := Previous?) then GetStagePlayers().Length + Prev.RecursivePlayerCount() else GetStagePlayers().Length


# Superclass for bases, serving as vertices/nodes in the graph
base := class<abstract><unique>:
    @editable
    Volume:volume_device = volume_device{}
    @editable
    DamageVolume:damage_volume_device = damage_volume_device{}
    @editable
    Billboard:billboard_device = billboard_device{}
    @editable
    Barriers:[]barrier_device = array{}
    @editable
    Rifts:[]teleporter_device = array{}

    var Teleporter:?teleporter_device = false
    # Number of Players in base
    var BasePlayers:[]player = array{}
    # Array of bases in Stage.Next 
    var Parents:[]base = array{}
    # Current stage
    var Stage:stage = stage{}
    var PlayerForfeited:logic = true
    var IsActive:logic = true
    
    
    # Subscribes the devices in base
    Initialize():void =
        Volume.AgentExitsEvent.Subscribe(OnPlayerExitingZone)
        Billboard.ShowText()
        for(Barrier:Barriers) do Barrier.Enable()
        for(Rift:Rifts):
            Rift.TeleportedEvent.Subscribe(OnPlayerTeleported)

    # Traverses Agent in the graph
    Advance(Agent:agent):void =
        if:
            Graph := TournamentGraph[GetSession()]
            Player := player[Agent]
            Player.IsActive[]
        then:
            Graph.Traverse(Player)
            option {set TournamentGraph[GetSession()] = Graph}

    # Adds Agent to base
    Add(Agent:agent):void =
        option:
            set BasePlayers += array{player[Agent]}

    # Removes Agent from base
    Remove(Agent:agent)<transacts>:void =
        option:
            Player := player[Agent]
            set BasePlayers = BasePlayers.RemoveAllElements(Player)

    # Resets the timers for Agent
    ResetTimers(Agent:agent):void =
        Stage.Devices.LongTimer.Reset(Agent)
        Stage.Devices.ShortTimer.Reset(Agent)

    # Teleports player to the next available rift
    Teleport(Player:player):void =
        defer:
            if(Rift := Teleporter?) then Rift.Teleport(Player)
        if(Teleporter?) then set Teleporter = option{Rifts[1]}
        else {set Teleporter = option{Rifts[0]}}
    
    # Ends the game if only 1 player left
    EndGame(Agent:agent)<suspends>:void =
        if(TournamentGraph[GetSession()].ActivePlayers.Length = 1):
            Sleep(0.2)
            Print("Game Ended")
            Stage.Devices.EndGameDevice.Activate(Agent)

    # Called when player exits base zone
    OnPlayerExitingZone(Agent:agent):void =
        spawn {EndGame(Agent)}
        Remove(Agent)
        spawn {CheckPlayerForfeit()}
        Stage.Devices.ItemRemover.Remove(Agent)
        ResetTimers(Agent)

    # Checks if player forfeits
    CheckPlayerForfeit()<suspends>:void =
        if(Player := BasePlayers[0]):
            if(PlayerForfeited?):
                Print("Player Forfeited")
                Stage.Devices.HudMessage.ShowMessage(Player, "OPPONENT FORFEITED")
                Sleep(3.0)
            # Advance to next stage
            Advance(Player)
        
    # Called when player is eliminated
    # Awards accolade to Eliminator
    OnBasePlayerEliminated(Result:elimination_result):void =
        if:
            Remove(Result.EliminatedCharacter.GetAgent[])
            # player[Result.EliminatingCharacter?.GetAgent[]] gives true even when there's no eliminating character #Epicbug
            # Hence, why i used comparison '=' 
            Player := BasePlayers[0] = player[Result.EliminatingCharacter?.GetAgent[]]
            set PlayerForfeited = false
            # Remove eliminated player from graph
            TournamentGraph[GetSession()].RemovePlayer(player[Result.EliminatedCharacter.GetAgent[]])
        then {Stage.Devices.EliminationAccolade.Award(Player)}
            
    # Called when player is teleported
    OnPlayerTeleported(Agent:agent):void =
        Add(Agent)
        Stage.Accolade.Award(Agent)
        Stage.Devices.HealthPowerUp.Pickup(Agent)
        spawn {CheckForOpponent(Agent)}
        if(BasePlayers.Length = 2):
            for(Player:BasePlayers):
                Stage.Devices.ItemGranter.GrantItem(Player)
                Stage.Devices.ShortTimer.Starts(BasePlayers)
            Billboard.HideText()

    # Checks if an opponent is available
    CheckForOpponent(Agent:agent)<suspends>:void =
        Sleep(1.0)
        if:
            BasePlayers.Length = 1
            Stage.Previous?.RecursivePlayerCount() = 0
            set PlayerForfeited = false
        then:
            Stage.Devices.HudMessage.ShowMessage(Agent, "NO OPPONENT FOUND")
            Sleep(4.0)  
            Advance(Agent)


# Hub      
hub := class(stage):
    Base:hub_base = hub_base{}

    GetBases<override>()<transacts>:[]base =
        array{Base}

# Vertex for the hub stage
hub_base := class(base):


# Round of 16
preliminary := class<concrete>(stage):
    @editable
    baseA:preliminary_A = preliminary_A{}
    @editable
    baseB:preliminary_B = preliminary_B{}
    @editable
    baseC:preliminary_C = preliminary_C{}
    @editable
    baseD:preliminary_D = preliminary_D{}
    @editable
    baseE:preliminary_E = preliminary_E{}
    @editable
    baseF:preliminary_F = preliminary_F{}
    @editable
    baseG:preliminary_G = preliminary_G{}
    @editable
    baseH:preliminary_H = preliminary_H{}

    GetBases<override>()<transacts>:[]base =
        array:
            baseA, baseB, baseC, baseD, baseE,  baseF, baseG, baseH

# Vertices for preliminary stages
preliminary_A := class<concrete>(base):
preliminary_B := class<concrete>(base):
preliminary_C := class<concrete>(base):
preliminary_D := class<concrete>(base):
preliminary_E := class<concrete>(base):
preliminary_F := class<concrete>(base):
preliminary_G := class<concrete>(base):
preliminary_H := class<concrete>(base):


# Quater Finals
quaterfinals := class<concrete>(stage):
    @editable
    baseA:quaterfinals_A = quaterfinals_A{}
    @editable
    baseB:quaterfinals_B = quaterfinals_B{}
    @editable
    baseC:quaterfinals_C = quaterfinals_C{}
    @editable
    baseD:quaterfinals_D = quaterfinals_D{}

    GetBases<override>()<transacts>:[]base =
        array:
            baseA, baseB, baseC, baseD
        
# Vertices for quarter-final stages
quaterfinals_A := class<concrete>(base):
quaterfinals_B := class<concrete>(base):
quaterfinals_C := class<concrete>(base):
quaterfinals_D := class<concrete>(base):


# Semi Finals
semifinals := class<concrete>(stage):
    @editable
    baseA:semifinals_A = semifinals_A{}
    @editable
    baseB:semifinals_B = semifinals_B{}

    GetBases<override>()<transacts>:[]base =
        array:
            baseA, baseB
    
# Vertices for semi-final stages
semifinals_A := class<concrete>(base):
semifinals_B := class<concrete>(base):


# Finals
finals := class<concrete>(stage):
    @editable
    baseA:finals_base = finals_base{}

    GetBases<override>()<transacts>:[]base =
        array{baseA}

# Vertex for final stage
finals_base := class<concrete>(base):
