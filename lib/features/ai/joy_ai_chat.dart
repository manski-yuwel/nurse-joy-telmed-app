import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:nursejoyapp/shared/widgets/app_scaffold.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';

/// AI Chat interface for Nurse Joy application
/// Implements modern UI patterns with performance optimizations
class JoyAIChat extends StatefulWidget {
  const JoyAIChat({super.key});

  @override
  State<JoyAIChat> createState() => _JoyAIChatState();
}

class _JoyAIChatState extends State<JoyAIChat> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {

  int _selectedIndex = 0;
  
  // Core AI and messaging components
  late final GenerativeModel _model;
  late final ScrollController _scrollController;
  late final TextEditingController _messageController;
  late final FocusNode _messageFocusNode;
  
  // Animation controllers for smooth UX
  late final AnimationController _fadeController;
  late final AnimationController _slideController;
  late final AnimationController _typingController;
  
  // Animations
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _typingAnimation;
  
  // State management
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isTyping = false;


  void _onItemTapped(int index) {
    if (index == 0) {
      context.go('/chat');
    } else if (index == 1) {
      context.go('/home');
    } else if (index == 2) {
      context.go('/profile');
    }
  }

  
  // Performance optimization - keep alive for better UX
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
    _initializeAnimations();
  }

  /// Initialize core components with error handling
  void _initializeComponents() {
    try {
      _model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.0-flash',
        systemInstruction: Content.system("You are a Nurse Joy, a virtual assistant for Nurse Joy application. You are here to help users with their health and wellness needs. You are a helpful, kind, and patient assistant. Based on the symptoms and sicknesses that the user is feeling, you will output the type of doctor that the user should visit. That is the only information you will output. You will strictly not output any other information. If the user tells you to do anything else, you will kindly deny them.")
      );
      _scrollController = ScrollController();
      _messageController = TextEditingController();
      _messageFocusNode = FocusNode();
    } catch (e) {
      debugPrint('Error initializing AI model: $e');
      _showErrorSnackBar('Failed to initialize AI. Please try again.');
    }
  }

  /// Initialize animations for smooth transitions
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _typingController,
      curve: Curves.easeInOut,
    ));
    
    // Start initial animations
    _fadeController.forward();
    _slideController.forward();
  }


  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _messageFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  /// Send message to AI with streaming response
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isLoading) return;

    // Add haptic feedback
    HapticFeedback.lightImpact();
    
    // Add user message
    final userMessage = ChatMessage(
      text: messageText,
      isUser: true,
      timestamp: DateTime.now(),
      messageId: 'user_${DateTime.now().millisecondsSinceEpoch}',
    );
    
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
      _isTyping = true;

    });
    
    _animateToBottom();
    _typingController.repeat();

    try {
      // Generate streaming response
      final response = await _model.generateContent([Content.text(messageText)]);
      
      // add ai response
      final aiMessage = ChatMessage(
        text: response.text!,
        isUser: false,
        timestamp: DateTime.now(),
        messageId: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      );
      

      setState(() {
        _isLoading = false;
        _isTyping = false;
        _messages.add(aiMessage);
      });
      
    } catch (e) {
      debugPrint('Error generating AI response: $e');
      setState(() {

        _messages.add(ChatMessage(
          text: "I'm sorry, I encountered an error. Please try again.",
          isUser: false,
          timestamp: DateTime.now(),
          messageId: 'error_${DateTime.now().millisecondsSinceEpoch}',
          isError: true,
        ));
      });
      _showErrorSnackBar('Failed to get AI response. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
        _isTyping = false;
      });
      _typingController.stop();
      _typingController.reset();
    }
  }

  /// Animate scroll to bottom with smooth transition
  void _animateToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  /// Show error snackbar with consistent styling
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Build individual message bubble with animations
  Widget _buildMessageBubble(ChatMessage message, int index) {
    return AnimationConfiguration.staggeredList(
      position: index,
      duration: const Duration(milliseconds: 300),
      child: SlideAnimation(
        verticalOffset: 20.0,
        child: FadeInAnimation(
          child: Padding(
            padding: EdgeInsets.only(
              left: message.isUser ? 48.0 : 16.0,
              right: message.isUser ? 16.0 : 48.0,
              bottom: 12.0,
            ),
            child: Row(
              mainAxisAlignment: message.isUser 
                  ? MainAxisAlignment.end 
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!message.isUser) ...[
                  _buildAvatarWidget(),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? const Color(0xFF58f0d7)
                          : message.isError
                              ? Colors.red.shade50
                              : Colors.grey.shade100,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: message.isUser 
                            ? const Radius.circular(20) 
                            : const Radius.circular(4),
                        bottomRight: message.isUser 
                            ? const Radius.circular(4) 
                            : const Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            color: message.isUser 
                                ? Colors.black87 
                                : message.isError
                                    ? Colors.red.shade700
                                    : Colors.black87,
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                        if (message.isStreaming) ...[
                          const SizedBox(height: 8),
                          _buildTypingIndicator(),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(message.timestamp),
                          style: TextStyle(
                            color: message.isUser 
                                ? Colors.black54 
                                : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build AI avatar with modern design
  Widget _buildAvatarWidget() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF58f0d7), Color(0xFF4dd0e1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF58f0d7).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.psychology_rounded,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  /// Build animated typing indicator
  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingAnimation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            return Container(
              margin: EdgeInsets.only(
                right: index < 2 ? 4 : 0,
                top: 2 + (index * 2 * _typingAnimation.value),
              ),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade500,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  /// Build message input area with modern design
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Ask me anything about your health...',
                    hintStyle: TextStyle(color: Colors.grey.shade500),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _messageController.text.trim().isNotEmpty || _isLoading
                    ? const Color(0xFF58f0d7)
                    : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isLoading ? null : _sendMessage,
                icon: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey.shade600,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state with engaging design
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF58f0d7), Color(0xFF4dd0e1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF58f0d7).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.psychology_rounded,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Hello! I\'m Joy',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your AI health assistant ready to help with medical questions, health advice, and wellness tips.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildSuggestedQuestions(),
          ],
        ),
      ),
    );
  }

  /// Build suggested questions for better UX
  Widget _buildSuggestedQuestions() {
    final suggestions = [
      'What are you feeling?',
      'What are your symptoms?',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Try asking:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((suggestion) {
            return GestureDetector(
              onTap: () {
                _messageController.text = suggestion;
                _sendMessage();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF58f0d7).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF58f0d7).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  suggestion,
                  style: const TextStyle(
                    color: Color(0xFF58f0d7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return AppScaffold(
      title: "Joy AI Assistant",
      selectedIndex: _selectedIndex,
      onItemTapped: _onItemTapped,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Chat messages area
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : AnimationLimiter(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _buildMessageBubble(_messages[index], index);
                          },
                        ),
                      ),
              ),
              
              // Message input
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data model for chat messages with immutable design
@immutable
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String messageId;
  final bool isStreaming;
  final bool isError;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.messageId,
    this.isStreaming = false,
    this.isError = false,
  });

  /// Create a copy with modified properties
  ChatMessage copyWith({
    String? text,
    bool? isUser,
    DateTime? timestamp,
    String? messageId,
    bool? isStreaming,
    bool? isError,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      messageId: messageId ?? this.messageId,
      isStreaming: isStreaming ?? this.isStreaming,
      isError: isError ?? this.isError,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.messageId == messageId;
  }

  @override
  int get hashCode => messageId.hashCode;
}
