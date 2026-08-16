import 'support_ticket.dart';

class SupportTicketPage {
  final List<SupportTicket> tickets;
  final int currentPage;
  final int lastPage;
  final int total;

  const SupportTicketPage({
    required this.tickets,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory SupportTicketPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>;
    final items = json['tickets'] as List<dynamic>;
    return SupportTicketPage(
      tickets: items
          .map((e) => SupportTicket.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentPage: pagination['current_page'] as int,
      lastPage: pagination['last_page'] as int,
      total: pagination['total'] as int,
    );
  }
}
