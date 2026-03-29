import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task_item.dart';
import '../providers/task_provider.dart';
import '../screens/task_edit_screen.dart';

class TaskCard extends StatelessWidget {
  final TaskItem task;
  
  const TaskCard({super.key, required this.task});

  Widget _buildHighlightedTitle(BuildContext context, String title, String query) {
    if (query.isEmpty) {
      return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
    }
    
    final lowerTitle = title.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    if (!lowerTitle.contains(lowerQuery)) {
      return Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18));
    }

    final startIndex = lowerTitle.indexOf(lowerQuery);
    final endIndex = startIndex + query.length;

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
        children: [
          TextSpan(text: title.substring(0, startIndex)),
          TextSpan(
            text: title.substring(startIndex, endIndex),
            style: const TextStyle(backgroundColor: Colors.yellow, color: Colors.black),
          ),
          TextSpan(text: title.substring(endIndex)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final isBlocked = provider.isTaskBlocked(task);
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Card(
      elevation: isBlocked ? 0 : 2,
      color: isBlocked ? theme.disabledColor.withOpacity(0.1) : theme.cardColor,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskEditScreen(task: task),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildHighlightedTitle(context, task.title, provider.searchQuery),
                  ),
                  _buildStatusChip(task.status),
                ],
              ),
              const SizedBox(height: 8),
              if (isBlocked) ...[
                Row(
                  children: [
                    Icon(Icons.lock_clock, size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 4),
                    Text(
                      'Blocked until prerequisite is Done',
                      style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                task.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isBlocked ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5) : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(task.dueDate),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isBlocked ? theme.colorScheme.primary.withOpacity(0.5) : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: theme.colorScheme.error,
                    visualDensity: VisualDensity.compact,
                    onPressed: () {
                      provider.deleteTask(task.id!);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'To-Do':
        color = Colors.grey;
        break;
      case 'In Progress':
        color = Colors.blue;
        break;
      case 'Done':
        color = Colors.green;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
