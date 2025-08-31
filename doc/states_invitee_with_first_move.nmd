    stateDiagram-v2
    
        [*] --> InvitationPending: ->SendInvite
        InvitationPending --> InvitationAccepted_ReadyToMove: AcceptInvite->
        InvitationPending --> InvitationRejected: RejectInvite->
        InvitationRejected --> [*]
        InvitationAccepted_ReadyToMove --> WaitForOpponent: Move->
        InvitationAccepted_ReadyToMove --> Resigned: Resign->
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