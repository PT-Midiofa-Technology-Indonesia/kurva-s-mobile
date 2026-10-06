class DeliveryOrderData {
  const DeliveryOrderData({
    required this.deliveryOrderId,
    required this.documentNumber,
    required this.source,
    required this.sourceLabel,
    required this.status,
    required this.orderType,
    this.syncState,
  });

  final String deliveryOrderId;
  final String documentNumber;
  final String source;
  final String sourceLabel;
  final String status;
  final String orderType;
  final String? syncState;
}

const openDeliveryOrders = [
  DeliveryOrderData(
    deliveryOrderId: 'fallback-open-1',
    documentNumber: 'DO/WH-JKT/2024/0045',
    source: 'JNE Express',
    sourceLabel: 'Vendor',
    status: 'Open',
    orderType: 'Purchase Order',
  ),
  DeliveryOrderData(
    deliveryOrderId: 'fallback-open-2',
    documentNumber: 'DO/WH-JKT/2024/0046',
    source: 'Lalamove',
    sourceLabel: 'Warehouse A',
    status: 'In Transit',
    orderType: 'Transfer Warehouse',
  ),
];

const closedDeliveryOrders = [
  DeliveryOrderData(
    deliveryOrderId: 'fallback-closed-1',
    documentNumber: 'DO/WH-JKT/2024/0041',
    source: 'SiCepat',
    sourceLabel: 'Vendor',
    status: 'Close',
    orderType: 'Purchase Order',
  ),
  DeliveryOrderData(
    deliveryOrderId: 'fallback-closed-2',
    documentNumber: 'DO/WH-JKT/2024/0042',
    source: 'Warehouse B',
    sourceLabel: 'Internal',
    status: 'Close',
    orderType: 'Transfer Warehouse',
  ),
];
