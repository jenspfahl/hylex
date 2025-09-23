# HyleX

A Hyle (Entropy) board game clone


--- Still in development ---

Single player against AI is playable.

Multiplayer is playable too but not error free so far ! ---

Download the latest test version here for testing: https://hyleX.jepfa.de/hylex.apk

## Implementation


### Multiplayer

#### Invitation state transitions


How to read:

Boxes are PlayStates, arrows are allowed transitions. Text on arrows are Operations triggering the transitions.

`->Operation` means an incoming/received operation from a message.
`Operation->` means an outgoing/sent operation from a message.

##### State model from the perspective of an invitor (initiator of an invitation):

```mermaid
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
```


##### State model from the perspective of the invitee (receiver of an invitation):


###### Invitee has to perform first move:

```mermaid
    stateDiagram-v2
    
        [*] --> InvitationPending: ->SendInvite
        InvitationPending --> InvitationAccepted_ReadyToMove
        InvitationPending --> InvitationRejected: RejectInvite->
        InvitationRejected --> [*]
        InvitationAccepted_ReadyToMove --> InvitationAccepted_WaitForOpponent: AcceptInvite(with move)->
        InvitationAccepted_ReadyToMove --> Resigned: Resign->
        ReadyToMove --> WaitForOpponent: Move->
        InvitationAccepted_WaitForOpponent --> ReadyToMove: ->Move
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
```


###### Invitee has to await first move from invitor:

```mermaid
    stateDiagram-v2
    
        [*] --> InvitationPending: ->SendInvite
        InvitationPending --> InvitationAccepted_WaitForOpponent: AcceptInvite->
        InvitationPending --> InvitationRejected: RejectInvite->
        InvitationRejected --> [*]
        InvitationAccepted_WaitForOpponent --> ReadyToMove: ->Move
        InvitationAccepted_WaitForOpponent --> OpponentResigned: ->Resign
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
```


#### Play state transitions

How to read:

Boxes are PlayStates, arrows are allowed transitions, indicating the direction. Text on arrows are Operations triggering the transitions.


##### Sequence flow if an invitation gets rejected:

```mermaid
sequenceDiagram

    actor Local as Invitor
    actor Remote as Invitee

    Local->>+Remote: <SendInvite>
    Note over Local: [RemoteOpponentInvited]
    Note over Remote: [InvitationPending]
    Remote-->>-Local: <RejectInvite>
    Note over Local: [InvitationRejected]
    Note over Remote: [InvitationRejected]
```



##### Sequence flow if an invitation gets accepted:

```mermaid
sequenceDiagram

    actor Local as Invitor
    actor Remote as Invitee

    Local->>+Remote: <SendInvite>
    Note over Local: [RemoteOpponentInvited]
    Note over Remote: [InvitationPending]


    alt Invitor starts
        Remote-->>-Local: <AcceptInvite>

        Note over Remote: [InvitationAccepted_WaitForOpponent]
        Note over Local: [RemoteOpponentAccepted]

    else Invitee starts with initial move

        Note over Remote: [InvitationAccepted_ReadyToMove]
        Remote-->>Local: <AcceptInvite with Move>
        Note over Remote: [InvitationAccepted_WaitForOpponent]


        Note over Local: [RemoteOpponentAccepted]
    

    end



    loop actual play
        Local->>+Remote: <Move>
        Note over Local: [WaitForOpponent]
        Note over Remote: [ReadyToMove]


        Remote->>-Local: <Move>
        Note over Remote: [WaitForOpponent]
        Note over Local: [ReadyToMove]
    end

```




