/// Batalat — Order models
class OrderSummary {
  final int id;
  final String orderNumber;
  final String status;
  final String statusDisplay;
  final String paymentStatus;
  final double total;
  final int itemsCount;
  final DateTime createdAt;

  const OrderSummary({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.statusDisplay,
    this.paymentStatus = 'pending',
    required this.total,
    this.itemsCount = 0,
    required this.createdAt,
  });

  bool get isCurrent =>
      status != 'delivered' && status != 'cancelled';

  String get dateLabel {
    final d = createdAt.toLocal();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      statusDisplay: json['status_display'] as String? ?? '',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      total: _parseDouble(json['total']),
      itemsCount: json['items_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class OrderItemLine {
  final int id;
  final String itemType;
  final String itemName;
  final double unitPrice;
  final int quantity;
  final double totalPrice;
  final Map<String, dynamic> extraDetails;

  const OrderItemLine({
    required this.id,
    required this.itemType,
    required this.itemName,
    required this.unitPrice,
    required this.quantity,
    required this.totalPrice,
    this.extraDetails = const {},
  });

  List<String> get optionLines {
    final opts = extraDetails['options'];
    if (opts is! List) return const [];
    return opts.map((e) {
      if (e is Map) {
        final name = e['name']?.toString() ?? '';
        final text = e['text']?.toString() ?? '';
        final price = e['additional_price']?.toString() ?? '';
        var line = name;
        if (price.isNotEmpty && price != '0' && price != '0.00') {
          line += ' (+$price)';
        }
        if (text.isNotEmpty) line += ' — $text';
        return line;
      }
      return e.toString();
    }).where((e) => e.isNotEmpty).toList();
  }

  factory OrderItemLine.fromJson(Map<String, dynamic> json) {
    return OrderItemLine(
      id: json['id'] as int,
      itemType: json['item_type'] as String? ?? 'product',
      itemName: json['item_name'] as String? ?? '',
      unitPrice: _parseDouble(json['unit_price']),
      quantity: json['quantity'] as int? ?? 1,
      totalPrice: _parseDouble(json['total_price']),
      extraDetails: Map<String, dynamic>.from(
        (json['extra_details'] as Map?) ?? const {},
      ),
    );
  }
}

class OrderStatusEvent {
  final String status;
  final String statusDisplay;
  final String note;
  final DateTime createdAt;

  const OrderStatusEvent({
    required this.status,
    required this.statusDisplay,
    this.note = '',
    required this.createdAt,
  });

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      status: json['status'] as String? ?? '',
      statusDisplay: json['status_display'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class OrderDetail {
  final int id;
  final String orderNumber;
  final String status;
  final String statusDisplay;
  final String paymentStatus;
  final String paymentStatusDisplay;
  final String paymentMethod;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double total;
  final String deliveryAddressText;
  final String deliveryCity;
  final String deliveryRegion;
  final String notes;
  final DateTime createdAt;
  final List<OrderItemLine> items;
  final List<OrderStatusEvent> statusHistory;

  const OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.statusDisplay,
    this.paymentStatus = 'pending',
    this.paymentStatusDisplay = '',
    this.paymentMethod = 'cod',
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.discountAmount = 0,
    required this.total,
    this.deliveryAddressText = '',
    this.deliveryCity = '',
    this.deliveryRegion = '',
    this.notes = '',
    required this.createdAt,
    this.items = const [],
    this.statusHistory = const [],
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      id: json['id'] as int,
      orderNumber: json['order_number'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      statusDisplay: json['status_display'] as String? ?? '',
      paymentStatus: json['payment_status'] as String? ?? 'pending',
      paymentStatusDisplay: json['payment_status_display'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? 'cod',
      subtotal: _parseDouble(json['subtotal']),
      deliveryFee: _parseDouble(json['delivery_fee']),
      discountAmount: _parseDouble(json['discount_amount']),
      total: _parseDouble(json['total']),
      deliveryAddressText: json['delivery_address_text'] as String? ?? '',
      deliveryCity: json['delivery_city'] as String? ?? '',
      deliveryRegion: json['delivery_region'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => OrderItemLine.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      statusHistory: (json['status_history'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((e) => OrderStatusEvent.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

double _parseDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}
