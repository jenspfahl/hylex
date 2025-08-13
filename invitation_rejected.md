sequenceDiagram

    actor Local as Invitor
    actor Remote as Invitee

    Local->>+Remote: <SendInvite>
    Note over Local: [RemoteOpponentInvited]
    Note over Remote: [InvitationPending]
    Remote-->>-Local: <RejectInvite>
    Note over Local: [InvitationRejected]
    Note over Remote: [InvitationRejected]