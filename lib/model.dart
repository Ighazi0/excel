class InvoiceResponse {
  final Invoice invoice;
  final String publicKey;

  InvoiceResponse({
    required this.invoice,
    required this.publicKey,
  });

  factory InvoiceResponse.fromJson(Map<String, dynamic> json) {
    return InvoiceResponse(
      invoice: Invoice.fromJson(json['invoice']),
      publicKey: json['publicKey'],
    );
  }
}

class Invoice {
  final String invoiceId;
  final String status;

  Invoice({
    required this.invoiceId,
    required this.status,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceId: json['invoiceId'].toString(),
      status: json['status'].toString(),
    );
  }
}
