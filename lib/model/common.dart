



import '../l10n/app_localizations.dart';

enum PlayerType {
  LocalUser,
  LocalAi,
  RemoteUser,
  ;

  String getName(AppLocalizations l10n) {
    return switch(this) {
      PlayerType.LocalUser => l10n.player_localUser,
      PlayerType.LocalAi => l10n.player_localAi,
      PlayerType.RemoteUser => l10n.player_remoteUser
    };
  }
}

enum Role {
  Chaos, 
  Order;

  Role get opponentRole => this == Role.Chaos ? Role.Order : Role.Chaos;
}

// Who sent the initial invite?
enum Actor {
  // for single play
  Single,
  // Who invites another
  Invitor,
  // Who gets invited
  Invitee;

  Actor opponentActor() => this == Invitor ? Invitee : this == Invitee ? Invitor : Single;

  Role? getActorRoleFor(PlayOpener? playOpener) {
    if (this == Actor.Invitor && playOpener == PlayOpener.Invitor) {
      return Role.Chaos;
    }
    else if (this == Actor.Invitor && playOpener == PlayOpener.Invitee) {
      return Role.Order;
    }
    else if (this == Actor.Invitee && playOpener == PlayOpener.Invitor) {
      return Role.Order;
    }
    else if (this == Actor.Invitee && playOpener == PlayOpener.Invitee) {
      return Role.Chaos;
    }
    else {
      return null;
    }
  }
}


enum Operation {
  SendInvite,  //0000
  AcceptInvite, //0001
  RejectInvite, //0010
  Move, //0011,
  Resign, //0100
  FullState, //0101
  unused0110, //0110
  unused0111, //0111
  unused1000, //1000
  unused1001, //1001
  unused1010, //1010
  unused1011, //1011
  unused1100, //1100
  unused1101, //1101
  unused1110, //1110
  unused1111, //1111
  // stuck to 4 bits, don't add more
} 

enum PlayMode {
  HyleX,    //00
  Classic,  //01
  unused10, //10 TODO could be with no random chip withdrawal
  unused11; //11
  // stuck to 2 bits, don't add more

  String getName(AppLocalizations l10n) => switch (this) {
    PlayMode.HyleX => l10n.playMode_hylex,
    PlayMode.Classic => l10n.playMode_classic,
    PlayMode.unused10 => throw UnimplementedError(),
    PlayMode.unused11 => throw UnimplementedError(),
  };
} 

enum PlayOpener {
  Invitor, //00
  Invitee,  //01
  InviteeChooses,  //10
  unused11,  //11
  // stuck to 2 bits, don't add more

} 

enum PlaySize {
  Size5x5(5, 20), //000
  Size7x7(7, 10), //001
  Size9x9(9, 5), //010
  Size11x11(11, 2), //011
  Size13x13(13, 1), //100
  Size4x4(4, 25), //101
  Size3x3(3, 4), //110
  Size2x2(2, 1) //111
  // stuck to 3 bits, don't add more

  ;

  final int dimension;
  final int chaosPointsPerChip;

  const PlaySize(this.dimension, this.chaosPointsPerChip);

  static PlaySize fromDimension(int dimension) {
    switch (dimension) {
      case 2: return PlaySize.Size2x2;
      case 3: return PlaySize.Size3x3;
      case 4: return PlaySize.Size4x4;
      case 5: return PlaySize.Size5x5;
      case 7: return PlaySize.Size7x7;
      case 9: return PlaySize.Size9x9;
      case 11: return PlaySize.Size11x11;
      case 13: return PlaySize.Size13x13;
      default: throw Exception("Unsupported dimension: $dimension");
    }
  }
} 

