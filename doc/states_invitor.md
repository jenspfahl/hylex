stateDiagram-v2

    [*] --> RemoteOpponentInvited: SendInvite->
    RemoteOpponentInvited --> RemoteOpponentAccepted: ->AcceptInvite
    RemoteOpponentInvited --> InvitationRejected: ->RejectInvite
    InvitationRejected --> [*]
    RemoteOpponentAccepted --> WaitForOpponent: Move->
    RemoteOpponentAccepted --> Resigned: Resign->
    ReadyToMove --> WaitForOpponent: Move->
    WaitForOpponent --> ReadyToMove: ->Move
    ReadyToMove --> Lost: Move->
    ReadyToMove --> Won: Move->
    ReadyToMove --> Resigned: Resign->
    WaitForOpponent --> Lost: ->Move
    WaitForOpponent --> Won: ->Move
    WaitForOpponent --> OpponentResigned: ->Resign    
    Lost --> [*]
    Won --> [*]
    Resigned --> [*]
    OpponentResigned --> [*]