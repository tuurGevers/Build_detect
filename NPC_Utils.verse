using { /Fortnite.com/AI }
using { /Verse.org/Simulation }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Verse.org/Random }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation/Tags }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/UI }
using { /Verse.org/Assets }
using { /Fortnite.com/Devices/CreativeAnimation }


NPCTag := class(tag){}
GetSeenPlayers<public>(Player:fort_character, Characters:[]fort_character, Range:float, FOV:float)<transacts>:[]fort_character=
    var ReturningPlayers: []fort_character = array{}
    for( NPC : Characters):
        if(Player.CheckNPCInVisionCone(Range, FOV, NPC.GetTransform().Translation) = true or ManhattenDistance(Player.GetTransform().Translation, NPC.GetTransform().Translation) < 200.0):
            set ReturningPlayers += array{NPC}

    return ReturningPlayers

#wrapper class to fetch players outside of creative_devices
FetchPlayers := class(creative_device):
    FGetPlayers()<transacts>: []player=
        return GetPlayspace().GetPlayers()

#IsPlayerInRange is a function that checks if a player is within a certain range of the NPC.
(NPC:fort_character).IsPlayerInRange<public>(Players:[]agent, MaxRange:float)<transacts>: ?agent=
    if(NPC.IsActive[]):
        NpcLocation := NPC.GetTransform().Translation
        for(Player:Players):
            if(FC:=Player.GetFortCharacter[]):
                PlayerLocation := FC.GetTransform().Translation
                if(ManhattenDistance(NpcLocation, PlayerLocation) < MaxRange):
                    return option{Player}
    return false


#get all players in range
(NPC:fort_character).GetPlayersInRange<public>(Players:[]agent, MaxRange:float)<transacts>: []agent=
    var PlayersInRange : []agent = array{}
    if(NPC.IsActive[]):
        NpcLocation := NPC.GetTransform().Translation
        for(Player:Players):
            if(FC:=Player.GetFortCharacter[]):
                PlayerLocation := FC.GetTransform().Translation
                if(ManhattenDistance(NpcLocation, PlayerLocation) < MaxRange):
                    set PlayersInRange += array{Player}
    # Print("Players in range: {PlayersInRange.Length}")
    return PlayersInRange
#get all players in range
(NPC:fort_character).GetPlayersBetweenRanges<public>(Players:[]agent,MinRange:float, MaxRange:float)<transacts>: []agent=
    var PlayersInRange : []agent = array{}
    if(NPC.IsActive[]):
        NpcLocation := NPC.GetTransform().Translation
        for(Player:Players):
            if(FC:=Player.GetFortCharacter[]):
                PlayerLocation := FC.GetTransform().Translation
                Dist:=ManhattenDistance(NpcLocation, PlayerLocation)
                Print("distance: {Dist}")
                if(Dist< MaxRange and Dist > MinRange):
                    set PlayersInRange += array{Player}
    # Print("Players in range: {PlayersInRange.Length}")
    return PlayersInRange
    
# NavigateToPlayer is a function that makes the NPC navigate to the player within a max amount of time.
(NPC:fort_character).NavigateToPlayer<public>(Player:agent, MaxTime:float)<suspends>: logic=
    var IsInTime : logic = true
    if(FC:=Player.GetFortCharacter[]):
        if(Navigatable := NPC.GetNavigatable[]):
            navTarget := MakeNavigationTarget(Player)
            if(NPC.IsActive[]):
                Res := race:
                    Navigatable.NavigateTo(navTarget)
                    CountDown(MaxTime, Navigatable)
                if(Res = false):
                    set IsInTime = false
                if(NPC.IsActive[]):
                    Navigatable.StopNavigation()

    return IsInTime

# NavigateToLocation is a function that makes the NPC navigate to a location within a max amount of time.
(NPC:fort_character).NavigateToLocation<public>(Location:vector3, MaxTime:float)<suspends>: logic=
    var IsInTime : logic = true
    if(Navigatable := NPC.GetNavigatable[]):
        navTarget := MakeNavigationTarget(Location)
        if(NPC.IsActive[]):
            Res := race:
                Navigatable.NavigateTo(navTarget)
                CountDown(MaxTime, Navigatable)
            if(Res = false):
                set IsInTime = false
            if(NPC.IsActive[]):
                Navigatable.StopNavigation()

    return IsInTime

# NavigateToRandomLocation is a function that makes the NPC navigate to a random location within a max amount of time.
(NPC:fort_character).NavigateToRandomLocation<public>(MaxTime:float, MaxOffset:float)<suspends>: logic=
    var IsInTime : logic = true
    if(Navigatable := NPC.GetNavigatable[]):
        RandomLocation := GetRandomVectorWithOffset(NPC.GetTransform().Translation, MaxOffset, ?ChangeZ:=false)
        navTarget := MakeNavigationTarget(RandomLocation)
        # spawn. CountDown(MaxTime, Navigatable)
        if(NPC.IsActive[]):
            Res := race:
                Navigatable.NavigateTo(navTarget)
                CountDown(MaxTime, Navigatable)
            if(Res = false):
                set IsInTime = false
            if(NPC.IsActive[]):
                Navigatable.StopNavigation()

    return IsInTime

(NPC:fort_character).GetDistance<public>(Player:agent)<transacts>:float=
    if(FC:=Player.GetFortCharacter[]):
        return ManhattenDistance(NPC.GetTransform().Translation, FC.GetTransform().Translation)
    return 0.0

# CountDown is a function that suspends the execution for a given amount of time used with the maxtime in other functions.
CountDown<public>(MaxTime:float , nav:navigatable)<suspends>: logic=
    Sleep(MaxTime)
    return false
    
# GetAnimationByName<public>(Name:string)<transacts>:animation_sequence=
#         return case(Name):

#             #Saw Animations
#             "saw_attack" =>  A1_BossAnimations.Attack_Hand_PwR
#             "saw_attack2" =>  A1_BossAnimations.Saw_kick_Anim
#             "saw_attack3" =>  A1_BossAnimations.DodgeF
#             "saw_Movement" =>  A1_BossAnimations.DodgeF
#             "saw_SpecialAttack" =>  A1_BossAnimations.long_nose_dive
#             "saw_hit" => A1_BossAnimations.Dodge_InPlace_Evade_Back
#             "saw_death" => A1_BossAnimations.BossDeath
#             "saw_SharkTeeth" =>C1_Animation_VFX.Saw_SharkTeeth_Throw_SK_SawTeeth1_Anim

#             #Choppy Animations
#             "choppy_attack" =>  A1_BossAnimations.Attack1
#             "choppy_attack2" =>  A1_BossAnimations.Attack3
#             "choppy_attack3" =>  A1_BossAnimations.AS_Combo_Attack_04_03_End_Seq
#             "choppy_SpecialAttack" =>  A1_BossAnimations.Choppy_SpecialSpin
#             "choppy_hit" =>  A1_BossAnimations.AS_Hit_Combat_F_Seq
            

#             #Smokey Animations
#             "smokey_attack" =>  A1_BossAnimations.ARPG_Unarmed_Anim_UE_Attack_Dodge_A
#             "smokey_attack2" =>  A1_BossAnimations.ARPG_Unarmed_Anim_UE_Attack_Combo_B5
#             "smokey_attack3" =>  A1_BossAnimations.ARPG_Unarmed_Anim_UE_Attack_Combo_B5
#             "smokey_SpecialAttack" =>  A1_BossAnimations.ARPG_Unarmed_Anim_UE_Attack_Combo_D
#             "smokey_hit" =>  A1_BossAnimations.ARPG_Unarmed_Anim_UE_Guard_Hit3
            
#             #Sandman Animations
#             "sandman_hit" =>  A1_BossAnimations.Fighter_Guard_hit
#             "sandman_attack" =>  A1_BossAnimations.Fighter_ComboA_1
#             "sandman_attack2" =>  A1_BossAnimations.Fighter_ComboA_2
#             "sandman_attack3" =>  A1_BossAnimations.Fighter_Uppercut_charge_release
#             "sandman_SpecialAttack" =>  A1_BossAnimations.SandMan_SandErupt
#             "sandman_Tornado" =>  C1_Animation_VFX.SandMan_Special_Animation
#             "sandman_sandSummon" =>  A1_BossAnimations.Fighter_Taunt
#             "sandman_RangedAOE"=> A1_BossAnimations.Ranged_SandErruption_SandMan
#             "sandman_BasicMelee" =>  C1_Animation_VFX.BaseAttack_SandMan
#             "sandman_HeavyMelee" =>  C1_Animation_VFX.HeavyMeleeStrikes_Sandman_SandMan
#             "sandman_Move" => C1_Animation_VFX.SandMovement_Sandman_SandMan_FixHook1_Anim
#             _=> A1_BossAnimations.Attack_Hand_PwR

#gets all players in game
GetPlayers<public>()<transacts>: []player=
    return FetchPlayers{}.FGetPlayers()

#gets all fort characters in game
GetFortCharacters<public>()<transacts>:[]fort_character=
        Players:= GetPlayers()
        var FCs : []fort_character = array{}
        for(Player:Players):
            if(FC:= Player.GetFortCharacter[]):
                set FCs += array{FC}
        return FCs

###RAYCASTING###
                    
# Function to calculate the length of a vector (Euclidean distance)
(V:vector3).VectorLength<public>()<transacts>:float=
    return Sqrt(V.X*V.X + V.Y*V.Y + V.Z*V.Z)

# Function to normalize a vector
(V:vector3).Normalize<public>()<transacts>:vector3=
    Length := V.VectorLength()
    if (Length > 0.0):
        return V / Length
    return V

# Function to check if a point is within the vision cone
IsPointInVisionCone<public>(Point:vector3, Apex:vector3, Direction:vector3, Radius:float, FOVAngle:float)<transacts>:logic=
    ApexToPoint := Point - Apex

    # Check if the point is within the radius
    if (ApexToPoint.VectorLength() > Radius):
        return false

    # Normalize the direction and ApexToPoint vectors
    NormalizedDirection := Direction.Normalize()
    NormalizedApexToPoint := ApexToPoint.Normalize()

    # Calculate the dot product
    dotProduct :float= DotProduct(NormalizedDirection, NormalizedApexToPoint)

    # Calculate the angle between the direction and ApexToPoint vector
    Angle := ArcCos(dotProduct) * (180.0 / PiFloat)  # Convert radians to degrees

    # Check if the angle is within the FOV
    if(Angle <= (FOVAngle / 2.0)):
        return true

    return false

# Example usage of the vision cone function
(NPC:fort_character).CheckNPCInVisionCone<public>(distance:float, FOVAngle:float, PointToCheck:vector3)<transacts>:logic=
    NPCPosition := NPC.GetTransform().Translation
    NPCForward := NPC.GetTransform().Rotation.GetLocalForward()

    IsInCone := IsPointInVisionCone(PointToCheck, NPCPosition, NPCForward, distance, FOVAngle)

    return IsInCone

RotateVectorAroundZAxis<public>(Vector:vector3, Angle:float):vector3=
        Radians := Angle * (PiFloat / 180.0)
        CosTheta := Cos(Radians)
        SinTheta := Sin(Radians)

        RotatedX := Vector.X * CosTheta - Vector.Y * SinTheta
        RotatedY := Vector.X * SinTheta + Vector.Y * CosTheta

        return vector3{X := RotatedX, Y := RotatedY, Z := Vector.Z}

    # Function to calculate the end point of the vision cone at a given angle
CalculateVisionConePoint<public>(Apex:vector3, Direction:vector3, Radius:float, Angle:float):vector3=
        RotatedDirection := RotateVectorAroundZAxis(Direction, Angle)
        return Apex + (RotatedDirection.Normalize() * Radius)
 