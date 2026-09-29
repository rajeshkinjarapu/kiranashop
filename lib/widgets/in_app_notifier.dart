import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../providers/auth_provider.dart';

class InAppNotifier extends StatefulWidget {
  final Widget child;

  const InAppNotifier({super.key, required this.child});

  @override
  State<InAppNotifier> createState() => _InAppNotifierState();
}

class _InAppNotifierState extends State<InAppNotifier> {
  StreamSubscription? _sub;
  String? _userId;
  final Set<String> _seenIds = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final newUserId = auth.user?.id;

    if (newUserId != _userId) {
      _userId = newUserId;
      _sub?.cancel();
      if (_userId != null) {
        // Initial fetch, just mark all current ones as seen so they don't popup
        FirestoreService().notificationsStream(_userId!).first.then((initialList) {
          if (!mounted) return;
          for (var n in initialList) {
            _seenIds.add(n.id);
          }
          // Now listen for real-time changes
          _sub = FirestoreService().notificationsStream(_userId!).listen((list) {
            if (!mounted) return;
            for (var n in list) {
              if (!_seenIds.contains(n.id) && !n.isRead) {
                _seenIds.add(n.id);
                _showHeroBanner(n);
              }
            }
          });
        });
      }
    }
  }

  void _showHeroBanner(NotificationModel notification) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0265DC).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_active_rounded, color: Color(0xFF0265DC)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notification.message,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      entry.remove();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    
    // Auto remove after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
