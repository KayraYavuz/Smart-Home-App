import 'package:flutter/foundation.dart';

/// TTLock API'sinden dönen bir şifre nesnesini temsil eder.
@immutable
class Passcode {
  final int keyboardPwdId;
  final int lockId;
  final String keyboardPwd;
  final String keyboardPwdName;
  final int keyboardPwdType;
  final int? startDate;
  final int? endDate;
  final String? senderUsername;

  const Passcode({
    required this.keyboardPwdId,
    required this.lockId,
    required this.keyboardPwd,
    required this.keyboardPwdName,
    required this.keyboardPwdType,
    this.startDate,
    this.endDate,
    this.senderUsername,
  });

  /// JSON verisinden bir Passcode nesnesi oluşturur.
  factory Passcode.fromJson(Map<String, dynamic> json) {
    // API bazen tipi String olarak dönebiliyor, bu yüzden güvenli çevrim yapıyoruz.
    final keyboardPwdTypeString = json['keyboardPwdType']?.toString();
    
    return Passcode(
      keyboardPwdId: json['keyboardPwdId'] as int,
      lockId: json['lockId'] as int,
      keyboardPwd: json['keyboardPwd'] as String,
      keyboardPwdName: json['keyboardPwdName'] as String,
      keyboardPwdType: keyboardPwdTypeString != null ? int.parse(keyboardPwdTypeString) : -1,
      startDate: json['startDate'] as int?,
      endDate: json['endDate'] as int?,
      senderUsername: json['senderUsername'] as String?,
    );
  }

  @override
  String toString() {
    return 'Passcode(id: $keyboardPwdId, name: $keyboardPwdName, code: $keyboardPwd)';
  }
}
