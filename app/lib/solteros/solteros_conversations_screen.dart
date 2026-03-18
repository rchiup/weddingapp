import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../ui/app_theme.dart';
import '../ui/custom_card.dart';
import 'solteros_provider.dart';

class SolterosConversationsScreen extends StatelessWidget {
  const SolterosConversationsScreen({super.key});

  String _formatLastMessageAt(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '';
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final solteros = context.watch<SolterosProvider>();
    final conversations = solteros.conversations;

    return RefreshIndicator(
      onRefresh: solteros.refreshStatus,
      child: conversations.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(AppSpacing.x2),
              children: const [
                SizedBox(height: 80),
                Center(
                  child: Text(
                    'Aún no tienes chats abiertos.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.x2),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.x1),
              itemBuilder: (context, index) {
                final item = conversations[index];
                final hasUnread = item.unreadCount > 0;
                final lastTime = _formatLastMessageAt(item.lastMessageAt);
                return CustomCard(
                  onTap: () => context.push('/solteros/dm/${item.otherUserId}'),
                  padding: const EdgeInsets.all(AppSpacing.x1_5),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x1_5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.otherName,
                                    style: AppTextStyles.title.copyWith(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (lastTime.isNotEmpty)
                                  Text(
                                    lastTime,
                                    style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.lastMessage.isEmpty ? 'Sin mensajes aún' : item.lastMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.subtitle.copyWith(
                                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                                color: hasUnread ? AppColors.textPrimary : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x1),
                      if (hasUnread)
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        Icon(
                          Icons.chevron_right,
                          color: AppColors.textPrimary.withOpacity(0.35),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

