import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/fcm_service.dart';

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});