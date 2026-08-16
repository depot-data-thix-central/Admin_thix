class PendingEnterpriseCertification {
  final String userId;
  final String? displayName;
  final String? thixId;
  final String paymentId;
  final double amountUsd;
  final double amountCdf;
  final DateTime? paidAt;
  final String? requestId;
  final String? reason;

  const PendingEnterpriseCertification({
    required this.userId,
    this.displayName,
    this.thixId,
    required this.paymentId,
    required this.amountUsd,
    required this.amountCdf,
    this.paidAt,
    this.requestId,
    this.reason,
  });

  factory PendingEnterpriseCertification.fromMap(Map<String, dynamic> m) {
    return PendingEnterpriseCertification(
      userId: m['user_id'].toString(),
      displayName: m['display_name']?.toString(),
      thixId: m['thix_id']?.toString(),
      paymentId: m['payment_id'].toString(),
      amountUsd: (m['amount_usd'] as num?)?.toDouble() ?? 0,
      amountCdf: (m['amount_cdf'] as num?)?.toDouble() ?? 0,
      paidAt: m['paid_at'] != null ? DateTime.tryParse(m['paid_at'].toString()) : null,
      requestId: m['request_id']?.toString(),
      reason: m['reason']?.toString(),
    );
  }
}
