

import 'package:hyle_x/model/play.dart';

enum PlayerType {
  LocalUser, 
  LocalAi, 
  RemoteUser
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
  SendInvite,  //000
  AcceptInvite, //001
  RejectInvite, //010
  Move, //011,
  Resign, //100
  unused101, //101
  unused110, //110
  unused111 //111
  // stuck to 3 bits, don't add more
} 

enum PlayMode {
  HyleX,    //00
  Classic,  //01
  unused10, //10
  unused11, //11
  // stuck to 2 bits, don't add more
} 

enum PlayOpener {
  Invitor, //00
  Invitee,  //01
  InvitedPlayerChooses,  //10
  unused11,  //11
  // stuck to 2 bits, don't add more

} 

enum PlaySize {
  Size5x5, //000
  Size7x7, //001
  Size9x9, //010
  Size11x11, //011
  Size13x13, //100
  unused101, //101
  unused110, //110
  unused111 //111
  ;
  // stuck to 3 bits, don't add more

  int toDimension() {
    switch (this) {
      case PlaySize.Size5x5: return 5;
      case PlaySize.Size7x7: return 7;
      case PlaySize.Size9x9: return 9;
      case PlaySize.Size11x11: return 11;
      case PlaySize.Size13x13: return 13;
      default: throw Exception("Unused: $this");
    }
  }

  static PlaySize fromDimension(int dimension) {
    switch (dimension) {
      case 5: return PlaySize.Size5x5;
      case 7: return PlaySize.Size7x7;
      case 9: return PlaySize.Size9x9;
      case 11: return PlaySize.Size11x11;
      case 13: return PlaySize.Size13x13;
      default: throw Exception("Unsupported dimension: $dimension");
    }
  }
} 

