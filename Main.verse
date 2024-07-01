
using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Game }
using { /Fortnite.com/Animation/PlayAnimation }
using { /Verse.org/Assets }
using { /Fortnite.com/Devices }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Verse.org/Simulation/Tags }

#struct to hold the 5 points as distance between raycast and hitlocation
Points := struct:
    P1:float
    P2:float
    P3:float
    P4:float
    P5:float

# A Verse-authored creative device that can be placed in a level
Main := class(creative_device):
    @editable BuildingRaycastAsset:creative_prop_asset = DefaultCreativePropAsset
    @editable BuildClears:[]explosive_device = array{}

    #huds
    @editable HudFloor: hud_message_device = hud_message_device{}
    @editable HudCone: hud_message_device = hud_message_device{}
    @editable HudStairs: hud_message_device = hud_message_device{}
    @editable HudWall: hud_message_device = hud_message_device{}

    #points for the 4 different building types
    FloorPoints :Points= Points{P1:=336.0, P2:=336.0, P3:=336.0, P4:=336.0, P5:=336.0}
    ConePoints : Points =Points{P1:=331.0, P2:=331.0, P3:=331.0, P4:=331.0, P5:=150.0}
    StairsPoints: Points = Points{P1:=355.0, P2:=60.0, P3:=210.0, P4:=60.0, P5:=355.0}
    WallPoints: Points = Points{P1:=0.0, P2:=0.0, P3:=-1.0, P4:=-1.0, P5:=-1.0}

    #escape for wall 
    var FetchesEnded:int = 0

    var First:logic=false
    OnBegin<override>()<suspends>:void=
        loop:
            Sleep(0.2)
            set FetchesEnded =0
            #launch all casts and wait untill tehy are all finished
            Res: tuple(float, float, float, float, float):=
                sync:
                    SpawnAndCheck(vector3{X:=0.0, Y:=0.0, Z:=350.0})
                    SpawnAndCheck(vector3{X:=244.0, Y:=244.0, Z:=350.0})
                    SpawnAndCheck(vector3{X:=244.0, Y:=-244.0, Z:=350.0})
                    SpawnAndCheck(vector3{X:=-244.0, Y:=-244.0, Z:=350.0})
                    SpawnAndCheck(vector3{X:=-244.0, Y:=244.0, Z:=350.0})

            #get best match
            Type:=GetBestMatch(Res)
            Print("Best match {Type}")
            case(Type):
                "FloorPoints" => HudFloor.Show()
                "ConePoints" => HudCone.Show()
                "StairsPoints" => HudStairs.Show()
                "WallPoints" => HudWall.Show()
                _ => Print("No match above 80% similarity")

            #clear builds consistently
            if(Player:=GetPlayers()[0]):
                for(BC:BuildClears):
                    BC.Reset()
                if(First= true):
                    if(BuildClear:=BuildClears[0]):
                        BuildClear.Reset()
                        Sleep(0.4)
                        BuildClear.Explode(Player)
                        set First = false
                else:
                    if(BuildClear:=BuildClears[1]):
                        BuildClear.Reset()
                        Sleep(0.4)
                        BuildClear.Explode(Player)
                        set First = true

    #spawn raycast and checks distance between raycast and hitlocation
    SpawnAndCheck(Pos:vector3)<suspends>:float=
        MaybeRP:= SpawnRaycastPropWithTransform(BuildingRaycastAsset, transform{
            Translation:=Pos,
            Scale:=vector3{X:=1.0, Y:=1.0, Z:=1.0},
            Rotation:=IdentityRotation().ApplyPitch(DegreesToRadians(-90.0))
        })

        if(ARP:=MaybeRP?):
            var Timer:float= 0.0
            loop:
                Sleep(0.2)
                if(FetchesEnded>=2):
                    set Timer+=0.2
                    if(Timer>=0.4):
                        ARP.GracefullDispose()
                        set FetchesEnded+=1
                        return -1.0
                if(ARP.OutputProp.GetTransform().Scale.X = 2.0):
                    # Print("Parent transform {ARP.Parent.GetTransform().Translation}")
                    # Print("Hit location transform {ARP.HitLocationProp.GetTransform().Translation}")
                    ZDist:= ARP.Parent.GetTransform().Translation.Z - ARP.HitLocationProp.GetTransform().Translation.Z
                    Print("ZDIST {ZDist}")
                    ARP.GracefullDispose()
                    set FetchesEnded+=1
                    return ZDist
        set FetchesEnded+=1          
        return -1.0

    #get best match based on similarity
    GetBestMatch(Res:tuple(float, float, float, float, float)):string=
        PointsList := map{"FloorPoints"=> FloorPoints, "ConePoints" => ConePoints, "StairsPoints" => StairsPoints, "WallPoints" => WallPoints}
        var BestMatch :string = ""
        var BestScore :float = 0.0

        for (PointsName -> PointStruct : PointsList):
            Score := CalculateSimilarity(Res, PointStruct)
            if( Score > BestScore):
                set BestScore = Score
                set BestMatch = PointsName

        if (BestScore >= 80.0):
            return BestMatch
        else:
            return "No match above 80% similarity"

    #calculate similarity between two sets of points
    CalculateSimilarity(Res:tuple(float, float, float, float, float), PointStruct:Points):float=
        ResList := array{Res(0), Res(1), Res(2), Res(3), Res(4)}
        PointList := array{PointStruct.P1, PointStruct.P2, PointStruct.P3, PointStruct.P4, PointStruct.P5}
        min_distance := CalculateMinimumDistance(ResList, PointList)
        
        MaxDistance := Sqrt(Pow((350.0 - 0.0), 2.0) * 5)
        Similarity := 100.0 - (min_distance / MaxDistance * 100.0)
        Print("similarity {Similarity}")
        return Similarity


    #calculate minimum distance between two sets of points
    CalculateMinimumDistance(ResList:[]float, PointList:[]float):float=
        var min_distance :float = 99999999999.0
        for (perm : Permutations(PointList)):
            if:
                distance := Sqrt(
                    Pow((ResList[0] - perm[0]), 2.0) +
                    Pow((ResList[1] - perm[1]), 2.0) +
                    Pow((ResList[2] - perm[2]), 2.0) +
                    Pow((ResList[3] - perm[3]), 2.0) +
                    Pow((ResList[4] - perm[4]), 2.0)
                )
                if (distance < min_distance):
                    set min_distance = distance
        return min_distance

    #get all permutations of a list so we can calculate points out of order 
    Permutations(list:[]float)<transacts>:[][]float=
        if (list.Length = 0):
            return array{array{}}
        
        var result :[][]float = array{}

        for (i:=0 .. list.Length - 1):
            var rest :[]float = array{}
            if:
                set rest += list.Slice[0,i]
                set rest += list.Slice[(i+1),list.Length]

                for (perm : Permutations(rest)):
                    if(set result += array{array{list[i]} + perm}){}
        
        return result
