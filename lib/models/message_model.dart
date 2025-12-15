import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String messageId;
  final String senderId;
  final String content;
  final DateTime timestamp;

  Message({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'] ?? '',
      senderId: json['senderId'] ?? '',
      content: json['content'] ?? '',
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

//https://console.firebase.google.com/v1/r/project/startup-corner-4ab7b/firestore/indexes?create_composite=Cldwcm9qZWN0cy9zdGFydHVwLWNvcm5lci00YWI3Yi9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvY2hhdF9yb29tcy9pbmRleGVzL18QARoQCgxwYXJ0aWNpcGFudHMYARoYChRsYXN0TWVzc2FnZVRpbWVzdGFtcBACGgwKCF9fbmFtZV9fEAI