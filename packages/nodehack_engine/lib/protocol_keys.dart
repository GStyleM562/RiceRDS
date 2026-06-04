/// Claves del protocolo PVP (los strings del campo `t`). Viven en el motor
/// compartido para que cliente (app) y servidor usen EXACTAMENTE los mismos
/// nombres — una sola fuente de verdad. (El transporte/encode vive en cada lado.)
library;

/// Mensajes Cliente → Servidor.
class C2S {
  static const hello = 'hello'; // {name}
  static const createRoom = 'createRoom'; // {deck}
  static const joinRoom = 'joinRoom'; // {code, deck}
  static const submitPlay = 'submitPlay'; // {rutinaUid, declared?, subUids}
  static const nextRoundAck = 'nextRoundAck'; // {}
  static const reconnect = 'reconnect'; // {token}
  static const leave = 'leave'; // {}
}

/// Mensajes Servidor → Cliente.
class S2C {
  static const roomCreated = 'roomCreated'; // {code, token, playerIndex}
  static const matchStart = 'matchStart'; // {hand, ramBase, public, oppName}
  static const oppReady = 'oppReady'; // {}
  static const reveal = 'reveal'; // {yourPlay, oppPlay, result, public}
  static const acquire = 'acquire'; // {hand, ramBase, public, acquiredN, acquiredRut, acquiredSub}
  static const oppDisconnected = 'oppDisconnected'; // {}
  static const oppReconnected = 'oppReconnected'; // {}
  static const gameOver = 'gameOver'; // {outcome}
  static const error = 'error'; // {message}
}
