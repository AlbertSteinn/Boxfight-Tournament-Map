using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/FortPlayerUtilities }
using { /Fortnite.com/Game }
using { /Verse.org/Random }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

# Global Variables
var TournamentGraph:weak_map(session, tournament_graph) = map{}
var StageList:weak_map(session, stagelist) = map{}

# struct representing devices that are shared amongst stages
device := struct<concrete>:
    @editable
    EndGameDevice:end_game_device = end_game_device{}
    @editable
    EliminationAccolade:accolades_device = accolades_device{}
    @editable
    HudMessage:hud_message_device = hud_message_device{}
    @editable
    ItemGranter:item_granter_device = item_granter_device{}
    @editable
    ItemRemover:item_remover_device = item_remover_device{}
    @editable
    ShortTimer:timer_device = timer_device{}
    @editable
    LongTimer:timer_device = timer_device{}
    @editable
    HealthPowerUp:health_powerup_device = health_powerup_device{}
    
# Verse Device
GameManager := class(creative_device):
    @editable
    Devices:device = device{}
    # Tournament Stages
    @editable
    Preliminary:preliminary = preliminary{}
    @editable
    QuaterFinals:quaterfinals = quaterfinals{}
    @editable
    SemiFinals:semifinals = semifinals{}
    @editable
    Finals:finals = finals{}

    Hub:hub = hub{}

    var AllPlayers:[]player = array{}
    var Stages:[]stage = array{}

    
    OnBegin<override>()<suspends>:void =
        set AllPlayers = Shuffle(GetPlayers())
        GetPlayerRemovedEvent().Subscribe(OnPlayerLeavingMap)
        Devices.ShortTimer.SuccessEvent.Subscribe(OnShortTimerCompleted)
        Devices.LongTimer.SuccessEvent.Subscribe(OnLongTimerCompleted)
        InitializeGraph()
        Sleep(1.0)
        StartGame()

    
    # Handles the complettion of the short timer
    # Disables Barriers and Starts a 3 Minute Countdown
    OnShortTimerCompleted(Agent:?agent):void =
        if(Player := player[Agent?]):
            Devices.LongTimer.Start(Player)
            for(Barrier:TournamentGraph[GetSession()].CurrentBase[Player].Barriers):
                Barrier.Disable()

    # Handles the completion of the long timer
    # Damages Player Every Second
    OnLongTimerCompleted(Agent:?agent):void =
        if(DamageVolume := TournamentGraph[GetSession()].CurrentBase[Agent?].DamageVolume):
            DamageVolume.Enable()

    # Teleports all players to bases
    StartGame():void =
        if:
            InPlayers := TournamentGraph[GetSession()].ActivePlayers
            set Hub.Base.BasePlayers = InPlayers
        then:
            for:
                Player:InPlayers
                set TournamentGraph[GetSession()].CurrentBase[Player] = Hub.Base
            do:
                Hub.Base.Advance(Player)
                Hub.Base.Remove(Player)

    # Initializes the graph
    InitializeGraph():void =
        option:
            set TournamentGraph[GetSession()] = tournament_graph{ActivePlayers := AllPlayers}
            set StageList[GetSession()] = stagelist{}
        InitializeBases()


    InitializeBases():void =
        SetStages()
        for:
            Stage:Stages
            StageList[GetSession()].Add(Stage)
            # Intentionally complicated cuz I'm that guy ;)
            Base:TournamentGraph[GetSession()].Add(Stage.GetBases())
        do:
            set Base.Stage = Stage
            Base.Initialize()

    # Sets the Stages depending on the total number of players in map
    SetStages():void =
        defer:
            set Stages += array{Hub}
            for(Stage:array{Finals, SemiFinals, QuaterFinals, Preliminary}):
                set Stage.Devices = Devices
                # Personal preference for aesthetics
                for(Base:Stage.GetBases(), Barrier:Base.Barriers):
                    Barrier.Enable()
        if(AllPlayers.Length <= 2):
            set Stages = array{Finals}
        else if(AllPlayers.Length <= 4):
            set Stages = array:
                Finals, SemiFinals
        else if(AllPlayers.Length <= 8):
            set Stages = array:
                Finals, SemiFinals, QuaterFinals
        else:
            set Stages = array:
                Finals, SemiFinals, QuaterFinals, Preliminary

    # Called when player leaves map
    OnPlayerLeavingMap(Agent:agent)<transacts>:void =
        option:
            Player := player[Agent]
            set AllPlayers = AllPlayers.RemoveAllElements(Player)
            TournamentGraph[GetSession()].RemovePlayer(Player)

# Returns the PlayerRemovedEvent of the fort_playspace
GetPlayerRemovedEvent():listenable(player) =
    GM := GameManager{}
    GM.GetPlayspace().PlayerRemovedEvent()

# Gets a list of all players in the map excluding spectators
GetPlayers()<transacts>:[]player =
    GM := GameManager{}
    for:
        Player:GM.GetPlayspace().GetPlayers()
        not Player.IsSpectator[]
    do {Player}

# Starts the Timer and only shows it to "Players"
(Timer:timer_device).Starts(Players:[]player):void =
    for(Player:Players) do Timer.Start(Player)

(HudDevice:hud_message_device).ShowMessage(Agent:agent, Text:string):void =
    HudDevice.Show(Agent, ToMessage(Text), ?DisplayTime := 3.0)

        
IsEven(Number:int)<transacts>:logic = logic{Ceil(Number / 2) * 2 = Number}

ToMessage<localizes>(Text:string):message = "{Text}"
ToMessage<localizes>(Text:string, Player:player):message = "{Text} {Player}"
PlayerName<localizes>(Player:player):message = "{Player}"
