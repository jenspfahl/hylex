stateDiagram-v2

    [*] --> Initialised
    Initialised --> InvitationPending: ->SendInvite
    InvitationPending --> InvitationAccepted: AcceptInvite->
    InvitationPending --> InvitationRejected: RejectInvite->
    InvitationRejected --> [*]
    InvitationAccepted --> ReadyToMove: ->Move
    InvitationAccepted --> OpponentResigned: ->Resign
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