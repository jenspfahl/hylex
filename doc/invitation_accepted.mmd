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
