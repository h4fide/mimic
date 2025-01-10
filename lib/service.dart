// This code is just example code to show how mimic app work
// This code is not working and just for educational purpose

import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ignore: non_constant_identifier_names
final Map<String, dynamic> CONFIG = {
  'base_url': 'https://app.ofppt-langues.ma',
  'heartbeat_settings': {
    'min_interval': 5,
    'max_interval': 45
  },
  'user_agents': [
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  ]
};

class PlatformActivitySimulator {
  final String? authToken;
  final String? deviceId;
  final String baseUrl;
  bool _isRunning = false;
  Timer? _heartbeatTimer;
  final Random _random = Random();

  PlatformActivitySimulator({this.authToken, this.deviceId})
      : baseUrl = CONFIG['base_url'] {
    // Logger.root.level = Level.ALL;
  }


  Map<String, String> _getDefaultHeaders() {
    return {
      'accept': '*/*',
      'content-type': 'application/json',
      'User-Agent': (CONFIG['user_agents'] as List).first,
      'x-auth-token': authToken ?? '',
      'x-device-id': deviceId ?? ''
    };
  }

  Future<bool> sendHeartbeat(String eventType) async {
    final String endpoint = '$baseUrl/gw/eventapi/main/api/event/internal/events';
    final payload = {
      'action': 'platform.application.$eventType',
      'timeZone': 'UTC'
    };

    try {
      for (int attempt = 0; attempt < 3; attempt++) {
        try {
          final response = await http.post(
            Uri.parse(endpoint),
            headers: _getDefaultHeaders(),
            body: jsonEncode(payload),
          );
          
          return response.statusCode == 200;
        } catch (e) {
          if (attempt == 2) rethrow;
          await Future.delayed(Duration(seconds: pow(2, attempt).toInt()));
        }
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  void start() {
    if (_isRunning) return;
    _isRunning = true;
    _runHeartbeat();
  }

  void stop() {
    _isRunning = false;
    _heartbeatTimer?.cancel();
    sendHeartbeat('dead').then((_) {
    });
  }

  void _runHeartbeat() async {
    while (_isRunning) {
      await sendHeartbeat('alive');
      
      final interval = _random.nextDouble() * 
          (CONFIG['heartbeat_settings']['max_interval'] - 
           CONFIG['heartbeat_settings']['min_interval']) +
          CONFIG['heartbeat_settings']['min_interval'];
      
      await Future.delayed(Duration(seconds: interval.toInt()));
    }
  }
}

void main() {
  final simulator = PlatformActivitySimulator(
    authToken: 'your_auth_token_here',
    deviceId: 'your_device_id_here'
  );
  
  simulator.start();
  
  Future.delayed(const Duration(minutes: 1), () {
    simulator.stop();
  });
}