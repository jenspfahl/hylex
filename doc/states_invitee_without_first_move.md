    stateDiagram-v2
    
        [*] --> Initialised
        Initialised --> InvitationPending: ->SendInvite
        InvitationPending --> InvitationAccepted_WaitForOpponent: AcceptInvite->
        InvitationPending --> InvitationRejected: RejectInvite->
        InvitationRejected --> [*]
        InvitationAccepted_WaitForOpponent --> ReadyToMove: Move->
        InvitationAccepted_WaitForOpponent --> OpponentResigned: Resign->
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