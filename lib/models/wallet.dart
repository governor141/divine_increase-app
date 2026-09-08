import 'package:cloud_firestore/cloud_firestore.dart';

/// A user's wallet, from `wallets/{uid}` — the document ID is the user's
/// Firebase Auth UID.
class Wallet {
  final num balance;
  final DateTime? updatedAt;

  const Wallet({required this.balance, this.updatedAt});

  factory Wallet.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Wallet(
      balance: (data['balance'] ?? 0) as num,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// A funding request from `walletFundingRequests` — a user's request to
/// add money to their wallet via bank transfer, pending admin approval.
class FundingRequest {
  final String id;
  final num amount;
  final String method;
  final String status;
  final DateTime? createdAt;

  const FundingRequest({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    this.createdAt,
  });

  factory FundingRequest.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return FundingRequest(
      id: doc.id,
      amount: (data['amount'] ?? 0) as num,
      method: (data['method'] ?? '') as String,
      status: (data['status'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
