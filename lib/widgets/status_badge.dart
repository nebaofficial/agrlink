import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final StatusType type;

  const StatusBadge({
    super.key,
    required this.status,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors['background'],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        _getLocalizedStatus(context, status),
        style: TextStyle(
          color: colors['text'],
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Map<String, Color> _getStatusColors() {
    switch (type) {
      case StatusType.product:
        switch (status.toUpperCase()) {
          case 'AVAILABLE':
            return {
              'background': const Color(0xFFDCFCE7),
              'text': const Color(0xFF166534),
            };
          case 'RESERVED':
            return {
              'background': const Color(0xFFFEF3C7),
              'text': const Color(0xFF92400E),
            };
          case 'SOLD':
            return {
              'background': const Color(0xFFE5E7EB),
              'text': const Color(0xFF374151),
            };
          default:
            return {
              'background': const Color(0xFFF3F4F6),
              'text': const Color(0xFF6B7280),
            };
        }

      case StatusType.order:
        switch (status.toUpperCase()) {
          case 'COMPLETED':
            return {
              'background': const Color(0xFFDCFCE7),
              'text': const Color(0xFF166534),
            };
          case 'IN_TRANSIT':
          case 'ACCEPTED':
            return {
              'background': const Color(0xFFDBEAFE),
              'text': const Color(0xFF1E40AF),
            };
          case 'PENDING':
            return {
              'background': const Color(0xFFFEF3C7),
              'text': const Color(0xFF92400E),
            };
          case 'CANCELLED':
            return {
              'background': const Color(0xFFFEE2E2),
              'text': const Color(0xFF991B1B),
            };
          default:
            return {
              'background': const Color(0xFFF3F4F6),
              'text': const Color(0xFF6B7280),
            };
        }

      case StatusType.delivery:
        switch (status.toUpperCase()) {
          case 'DELIVERED':
          case 'CONFIRMED':
            return {
              'background': const Color(0xFFDCFCE7),
              'text': const Color(0xFF166534),
            };
          case 'IN_TRANSIT':
          case 'PICKED_UP':
            return {
              'background': const Color(0xFFDBEAFE),
              'text': const Color(0xFF1E40AF),
            };
          case 'ASSIGNED':
            return {
              'background': const Color(0xFFFEF3C7),
              'text': const Color(0xFF92400E),
            };
          default:
            return {
              'background': const Color(0xFFF3F4F6),
              'text': const Color(0xFF6B7280),
            };
        }
    }
  }

  String _getLocalizedStatus(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    final upperStatus = status.toUpperCase();

    switch (type) {
      case StatusType.product:
        switch (upperStatus) {
          case 'AVAILABLE':
            return l10n.statusAvailable;
          case 'RESERVED':
            return l10n.statusReserved;
          case 'SOLD':
            return l10n.statusSold;
          default:
            return status;
        }
      case StatusType.order:
        switch (upperStatus) {
          case 'PENDING':
            return l10n.statusPending;
          case 'ACCEPTED':
            return l10n.statusAccepted;
          case 'IN_TRANSIT':
            return l10n.statusInTransit;
          case 'DELIVERED':
            return l10n.statusDelivered;
          case 'CANCELLED':
            return l10n.statusCancelled;
          default:
            return status;
        }
      case StatusType.delivery:
        switch (upperStatus) {
          case 'ASSIGNED':
            return l10n.statusAccepted; // Reuse or add statusAssigned
          case 'PICKED_UP':
          case 'IN_TRANSIT':
            return l10n.statusInTransit;
          case 'DELIVERED':
          case 'CONFIRMED':
            return l10n.statusDelivered;
          default:
            return status;
        }
    }
  }

  String _formatStatus(String status) {
    return status
        .toLowerCase()
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

enum StatusType {
  product,
  order,
  delivery,
}
