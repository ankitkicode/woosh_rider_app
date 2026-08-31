import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import 'dart:io';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? socket;

  // Use the same URL base as ApiService
  String get _socketUrl {
    return 'https://wooshride.in';
  }

  void connect() {
    if (socket != null && socket!.connected) return;

    socket = IO.io(_socketUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build()
    );

    socket!.connect();

    socket!.onConnect((_) {
      print('[Socket] Connected to backend');
    });

    socket!.onDisconnect((_) {
      print('[Socket] Disconnected from backend');
    });
  }

  void emitStatusChanged(String riderId, bool isOnline, {double? lat, double? lng}) {
    if (socket == null || !socket!.connected) return;
    socket!.emit('rider:status_changed', {
      'riderId': riderId,
      'isOnline': isOnline,
      'latitude': lat,
      'longitude': lng,
    });
  }

  void emitLocationUpdate(String riderId, double lat, double lng, {String? rideId}) {
    if (socket == null || !socket!.connected) return;
    socket!.emit('rider:update_location', {
      'riderId': riderId,
      'latitude': lat,
      'longitude': lng,
      if (rideId != null) 'rideId': rideId,
    });
  }

  void disconnect() {
    socket?.disconnect();
  }
}
