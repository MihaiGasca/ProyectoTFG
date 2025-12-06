import 'package:flutter/material.dart';

class ChatMessage {
  final String id;
  final String content;
  final String sender;
  final String createdAt;
  final bool isMine;

  ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    required this.createdAt,
    required this.isMine,
  });

  factory ChatMessage.fromMap(Map map, String myId) {
    return ChatMessage(
      id: map['id'],
      content: map['contenido'],
      sender: map['remitente_id'],
      createdAt: map['created_at'],
      isMine: map['remitente_id'] == myId,
    );
  }
}
