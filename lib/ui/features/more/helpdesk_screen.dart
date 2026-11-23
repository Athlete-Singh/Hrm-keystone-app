import 'package:flutter/material.dart';

import '../../../domain/models/employee_models.dart';
import '../../core/theme/keystone_theme.dart';
import '../../core/widgets/keystone_corner_actions.dart';
import '../../core/widgets/keystone_ui.dart';
import '../../viewmodels/app_state.dart';

class HelpdeskScreen extends StatelessWidget {
  const HelpdeskScreen({super.key, required this.appState});

  final AppState appState;

  Future<void> _showCreateTicketSheet(BuildContext context) async {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'HR';
    String priority = 'MEDIUM';
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Raise support request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(labelText: 'Subject *', hintText: 'e.g. Reimbursement receipt query'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: const [
                          DropdownMenuItem(value: 'HR', child: Text('HR')),
                          DropdownMenuItem(value: 'IT', child: Text('IT')),
                          DropdownMenuItem(value: 'Finance', child: Text('Finance')),
                          DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                        ],
                        onChanged: (v) => setModal(() => category = v ?? 'HR'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: priority,
                        decoration: const InputDecoration(labelText: 'Priority'),
                        items: const [
                          DropdownMenuItem(value: 'LOW', child: Text('Low')),
                          DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                          DropdownMenuItem(value: 'HIGH', child: Text('High')),
                          DropdownMenuItem(value: 'URGENT', child: Text('Urgent')),
                        ],
                        onChanged: (v) => setModal(() => priority = v ?? 'MEDIUM'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description *'),
                ),
                const SizedBox(height: 14),
                KeystoneGradientButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (subjectCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) return;
                          setModal(() => submitting = true);
                          try {
                            await appState.createTicket(
                              subject: subjectCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              category: category,
                              priority: priority,
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                          } finally {
                            setModal(() => submitting = false);
                          }
                        },
                  busy: submitting,
                  label: 'Submit ticket',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTicketDetail(BuildContext context, HelpdeskTicket ticket) {
    final replyCtrl = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  KeystoneBadge(label: '${ticket.category} · ${ticket.priority}', tone: BadgeTone.indigo),
                  const Spacer(),
                  KeystoneBadge(
                    label: ticket.status,
                    tone: ticket.status == 'RESOLVED' || ticket.status == 'CLOSED'
                        ? BadgeTone.emerald
                        : BadgeTone.ochre,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(ticket.subject, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(ticket.description, style: const TextStyle(fontSize: 13.5, color: KeystoneColors.muted)),
              if (ticket.comments.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (final c in ticket.comments) ...[
                  Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: KeystoneColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.authorName,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: KeystoneColors.pineDeep),
                        ),
                        const SizedBox(height: 2),
                        Text(c.comment, style: const TextStyle(fontSize: 13, color: KeystoneColors.ink)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: replyCtrl,
                      decoration: const InputDecoration(hintText: 'Write a follow-up…'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      if (replyCtrl.text.trim().isEmpty) return;
                      await appState.addTicketComment(
                        ticketId: ticket.id,
                        comment: replyCtrl.text.trim(),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Reply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final tickets = appState.tickets;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text('Help & support'),
            actions: [
              TextButton.icon(
                onPressed: () => _showCreateTicketSheet(context),
                icon: const Icon(Icons.add_rounded, size: 18, color: KeystoneColors.pine),
                label: const Text('New', style: TextStyle(color: KeystoneColors.pine, fontWeight: FontWeight.w700)),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 14, left: 4),
                child: KeystoneCornerActions(
                  appState: appState,
                  compact: true,
                ),
              ),
            ],
          ),
          body: KeystoneBackdrop(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  if (tickets.isEmpty)
                    KeystoneEmptyState(
                      icon: Icons.support_agent_rounded,
                      accentColor: KeystoneColors.pine,
                      tintColor: KeystoneColors.pineTint,
                      title: 'No support tickets',
                      message: 'Need help with HR, IT hardware, or payroll? Open a ticket.',
                      action: KeystoneGradientButton(
                        onPressed: () => _showCreateTicketSheet(context),
                        label: 'Create ticket',
                      ),
                    )
                  else
                    for (var i = 0; i < tickets.length; i++) ...[
                      if (i > 0) const SizedBox(height: 9),
                      KeystoneCard(
                        borderRadius: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        onTap: () => _showTicketDetail(context, tickets[i]),
                        child: Row(
                          children: [
                            const KeystoneIconBadge(
                              icon: Icons.confirmation_number_rounded,
                              background: KeystoneColors.indigoTint,
                              color: KeystoneColors.indigo,
                              size: 38,
                              iconSize: 18,
                              radius: 11,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tickets[i].subject,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '${tickets[i].category} · ${tickets[i].priority}',
                                    style: const TextStyle(fontSize: 12, color: KeystoneColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            KeystoneBadge(
                              label: tickets[i].status,
                              tone: tickets[i].status == 'RESOLVED' || tickets[i].status == 'CLOSED'
                                  ? BadgeTone.emerald
                                  : BadgeTone.ochre,
                            ),
                          ],
                        ),
                      ),
                    ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
