import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/ai_service.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  final List<String> _quickQuestions = [
    'What crops are best to plant this season?',
    'How can I improve my soil quality?',
    'Current market prices for vegetables',
    'Tips for organic farming',
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userName = authProvider.user?.fullName.split(' ').first ?? 'Farmer';

    _messages.add(ChatMessage(
      content: '''Hello $userName! 👋

I'm your AgriSupply AI Assistant. I can help you with:

🌱 **Crop Management**
Get advice on planting, growing, and harvesting

📊 **Market Insights**
Current prices and demand trends

🌤️ **Weather Updates**
Weather forecasts for your region

🐛 **Pest & Disease Control**
Identify and treat crop issues

💡 **Best Practices**
Tips for improving yield and quality

How can I help you today?''',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(final String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        content: message,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      final aiService = AIService();
      final response = await aiService.chat(message);

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            content: response,
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add(ChatMessage(
            content: 'Sorry, I encountered an error. Please try again.',
            isUser: false,
            timestamp: DateTime.now(),
            isError: true,
          ));
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(final BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Powered by AgriSupply AI',
                  style: TextStyle(fontSize: 11, color: AppColors.grey600),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.grey900,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(Icons.refresh),
            tooltip: 'New Chat',
          ),
          PopupMenuButton<String>(
            onSelected: (final value) {
              switch (value) {
                case 'history':
                  _showChatHistory();
                  break;
                case 'settings':
                  _showSettings();
                  break;
              }
            },
            itemBuilder: (final context) => [
              const PopupMenuItem(
                value: 'history',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 12),
                    Text('Chat History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (final context, final index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // Quick Questions
          if (_messages.length <= 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Questions',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickQuestions.map((final question) {
                      return GestureDetector(
                        onTap: () => _sendMessage(question),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.grey200),
                          ),
                          child: Text(
                            question,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.grey700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

          // Input
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: _showAttachmentOptions,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.grey500,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Ask me anything about farming...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _sendMessage(_messageController.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.smart_toy,
            size: 80,
            color: AppColors.grey300,
          ),
          const SizedBox(height: 16),
          Text(
            'Your AI Farming Assistant',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Ask me anything about farming!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(final ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: AppColors.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primaryGreen
                    : message.isError
                        ? AppColors.error.withOpacity(0.1)
                        : AppColors.grey100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: message.isUser
                          ? Colors.white
                          : message.isError
                              ? AppColors.error
                              : AppColors.grey900,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: message.isUser
                          ? Colors.white.withOpacity(0.7)
                          : AppColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.grey200,
              child: Icon(Icons.person, size: 18, color: AppColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: AppColors.primaryGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(final int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (final context, final value, final child) {
        return Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.grey400,
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  String _formatTime(final DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _clearChat() {
    showDialog<void>(
      context: context,
      builder: (final context) => AlertDialog(
        title: const Text('New Chat'),
        content: const Text('Start a new conversation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  void _showChatHistory() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (final context) => Container(
        padding: const EdgeInsets.all(24),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: AppColors.grey400),
                  SizedBox(height: 8),
                  Text(
                    'No previous chats',
                    style: TextStyle(color: AppColors.grey600),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (final context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Assistant Settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Voice Messages'),
              subtitle: const Text('Enable voice input and output'),
              value: false,
              onChanged: (final value) {},
            ),
            SwitchListTile(
              title: const Text('Auto-save Chats'),
              subtitle: const Text('Save conversation history'),
              value: true,
              onChanged: (final value) {},
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Language'),
              subtitle: const Text('English'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (final context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Attach',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: AppColors.primaryGreen,
                  onTap: () {
                    Navigator.pop(context);
                    // Handle camera
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: 'Gallery',
                  color: AppColors.secondaryOrange,
                  onTap: () {
                    Navigator.pop(context);
                    // Handle gallery
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.location_on,
                  label: 'Location',
                  color: AppColors.info,
                  onTap: () {
                    Navigator.pop(context);
                    // Handle location
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required final IconData icon,
    required final String label,
    required final Color color,
    required final VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
}
