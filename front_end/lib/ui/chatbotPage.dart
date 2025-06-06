import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatbotPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? userId;

  const ChatbotPage({
    super.key,
    this.userData,
    this.userId,
  });

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _conversationHistory = "";
  
  // Gemini API Configuration
  static const String apiKey = 'AIzaSyDkBpM0BNslRzNzPYPgNyu-xmqzd1tIpN4';
  static const String apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Load chat history from SharedPreferences
  Future<void> _loadChatHistory() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = widget.userId ?? 'guest';
      final savedMessages = prefs.getStringList('chat_messages_$userId') ?? [];
      final savedHistory = prefs.getString('conversation_history_$userId') ?? "";
      
      if (savedMessages.isNotEmpty) {
        final List<ChatMessage> loadedMessages = [];
        
        for (var messageJson in savedMessages) {
          final messageMap = jsonDecode(messageJson);
          loadedMessages.add(ChatMessage(
            text: messageMap['text'],
            isUser: messageMap['isUser'],
            timestamp: DateTime.parse(messageMap['timestamp']),
          ));
        }
        
        setState(() {
          _messages.addAll(loadedMessages);
          _conversationHistory = savedHistory;
        });
      } else {
        _addWelcomeMessage();
      }
    } catch (e) {
      print('Error loading chat history: $e');
      _addWelcomeMessage();
    }
    
    setState(() {
      _isLoading = false;
    });
    
    _scrollToBottom();
  }

  // Save chat history to SharedPreferences
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = widget.userId ?? 'guest';
      
      final List<String> messagesToSave = _messages.map((message) {
        return jsonEncode({
          'text': message.text,
          'isUser': message.isUser,
          'timestamp': message.timestamp.toIso8601String(),
        });
      }).toList();
      
      await prefs.setStringList('chat_messages_$userId', messagesToSave);
      await prefs.setString('conversation_history_$userId', _conversationHistory);
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  void _addWelcomeMessage() {
    final String username = widget.userData?['username'] ?? 'there';
    _messages.add(
      ChatMessage(
        text: "Hi $username! 👋 I'm your yoga assistant. How can I help you today?",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    
    _saveChatHistory();
  }

  Future<void> _sendMessage() async {
    final String message = _messageController.text.trim();
    if (message.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(
          text: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Update conversation history with user message
      _updateConversationHistory(message, true);
      
      // Get AI response with retry mechanism
      final response = await _getGeminiResponseWithRetry(message);
      
      setState(() {
        _messages.add(
          ChatMessage(
            text: response,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
      
      // Update conversation history with AI response
      _updateConversationHistory(response, false);
      
      // Save chat history
      _saveChatHistory();
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Sorry, I'm having trouble connecting right now. Please try again! 😅",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
      
      _saveChatHistory();
    }

    _scrollToBottom();
  }

  void _updateConversationHistory(String message, bool isUser) {
    // Keep only the last 6 messages in the conversation history to avoid token limits
    if (_messages.length > 6) {
      final recentMessages = _messages.sublist(_messages.length - 6);
      _conversationHistory = recentMessages.map((msg) {
        return "${msg.isUser ? 'User' : 'Assistant'}: ${msg.text}";
      }).join("\n\n");
    } else {
      _conversationHistory += "\n\n${isUser ? 'User' : 'Assistant'}: $message";
    }
  }

  // Retry mechanism for API calls
  Future<String> _getGeminiResponseWithRetry(String userMessage, {int retryCount = 0}) async {
    try {
      final response = await _getGeminiResponse(userMessage);
      
      // Check if response seems incomplete (ends abruptly)
      if (_isResponseIncomplete(response) && retryCount < 2) {
        print('Response seems incomplete, retrying...');
        return await _getGeminiResponseWithRetry(userMessage, retryCount: retryCount + 1);
      }
      
      return response;
    } catch (e) {
      if (retryCount < 2) {
        print('API call failed, retrying... (attempt ${retryCount + 1})');
        await Future.delayed(Duration(seconds: 1));
        return await _getGeminiResponseWithRetry(userMessage, retryCount: retryCount + 1);
      }
      throw e;
    }
  }

  bool _isResponseIncomplete(String response) {
    // Check for signs of incomplete response
    final trimmed = response.trim();
    
    // If response ends with incomplete sentence patterns
    final incompletePatterns = [
      RegExp(r'\w+\s*$'), // Ends with a word followed by space
      RegExp(r':\s*$'), // Ends with colon
      RegExp(r',\s*$'), // Ends with comma
      RegExp(r'yang\s*$'), // Ends with "yang"
      RegExp(r'untuk\s*$'), // Ends with "untuk"
      RegExp(r'dengan\s*$'), // Ends with "dengan"
      RegExp(r'adalah\s*$'), // Ends with "adalah"
    ];
    
    // Check if response is too short for a detailed question
    if (trimmed.length < 50) return true;
    
    // Check for incomplete patterns
    for (var pattern in incompletePatterns) {
      if (pattern.hasMatch(trimmed)) {
        return true;
      }
    }
    
    return false;
  }

  Future<String> _getGeminiResponse(String userMessage) async {
    try {
      // Determine response parameters
      final responseConfig = _determineResponseConfig(userMessage);
      
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': _buildPrompt(userMessage),
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': responseConfig['maxTokens'],
            'stopSequences': [], // Remove any stop sequences that might cut off responses
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if response was blocked or incomplete
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('No response generated');
        }
        
        final candidate = data['candidates'][0];
        
        // Check for finish reason
        final finishReason = candidate['finishReason'];
        if (finishReason == 'SAFETY') {
          return "I apologize, but I can't provide that information. Let me help you with yoga-related questions instead! 🧘‍♀️";
        }
        
        final text = candidate['content']['parts'][0]['text'];
        final cleanedText = _cleanResponse(text);
        
        print('API Response length: ${cleanedText.length}');
        print('Finish reason: $finishReason');
        
        return cleanedText;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get response: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting Gemini response: $e');
      throw e;
    }
  }

  Map<String, dynamic> _determineResponseConfig(String message) {
    // Analyze message to determine appropriate response configuration
    final wordCount = message.split(' ').length;
    final hasQuestionMark = message.contains('?');
    final hasDetailWords = message.toLowerCase().contains('detail') || 
                          message.toLowerCase().contains('explain') || 
                          message.toLowerCase().contains('bagaimana') ||
                          message.toLowerCase().contains('cara') ||
                          message.toLowerCase().contains('jelaskan') ||
                          message.toLowerCase().contains('tips') ||
                          message.toLowerCase().contains('langkah') ||
                          message.toLowerCase().contains('daftar') ||
                          message.toLowerCase().contains('rekomendasi');
    
    // For detailed questions, allow longer responses
    if ((wordCount > 10 && hasQuestionMark) || hasDetailWords) {
      return {
        'maxTokens': 400,
        'responseType': 'detailed'
      };
    } else if (wordCount > 6 || hasQuestionMark) {
      return {
        'maxTokens': 250,
        'responseType': 'medium'
      };
    } else {
      return {
        'maxTokens': 150,
        'responseType': 'short'
      };
    }
  }

  String _buildPrompt(String userMessage) {
    final String username = widget.userData?['username'] ?? 'friend';
    
    return '''
You are a friendly yoga assistant for AmalaYoga app. 

CRITICAL INSTRUCTIONS:
- ALWAYS complete your sentences and thoughts
- NEVER end responses abruptly or mid-sentence
- If discussing multiple points, finish each point completely
- End with a natural conclusion or question
- Use emojis sparingly (1-2 per response)

RESPONSE GUIDELINES:
- For detailed questions: provide complete explanations with 3-4 key points
- For simple questions: give concise but complete answers
- Always maintain a warm, encouraging tone

Context: User $username is asking about yoga.

Previous conversation:
$_conversationHistory

User's latest message: $userMessage

Respond naturally about:
- Yoga poses and techniques
- Breathing exercises  
- Meditation tips
- Class recommendations
- Beginner guidance
- Wellness advice

IMPORTANT: Make sure to complete your response fully. Do not cut off mid-sentence.
''';
  }

  String _cleanResponse(String response) {
    // Remove excessive formatting and keep it conversational
    return response
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .trim();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChatHistory() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to clear all chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              
              final prefs = await SharedPreferences.getInstance();
              final userId = widget.userId ?? 'guest';
              await prefs.remove('chat_messages_$userId');
              await prefs.remove('conversation_history_$userId');
              
              setState(() {
                _messages.clear();
                _conversationHistory = "";
              });
              
              _addWelcomeMessage();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2C5530),
        foregroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yoga Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearChatHistory,
            tooltip: 'Clear chat history',
          ),
        ],
        elevation: 2,
      ),
      // PERBAIKAN UTAMA: Menambahkan resizeToAvoidBottomInset
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        // PERBAIKAN: Menambahkan SafeArea untuk menghindari area sistem
        child: _isLoading && _messages.isEmpty
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2C5530),
                ),
              )
            : Column(
                children: [
                  // Chat Messages
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isLoading) {
                          return _buildTypingIndicator();
                        }
                        return _buildMessageBubble(_messages[index]);
                      },
                    ),
                  ),

                  // PERBAIKAN: Message Input dengan SafeArea dan padding yang lebih baik
                  SafeArea(
                    top: false, // Hanya melindungi bagian bawah
                    child: Container(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                        bottom: MediaQuery.of(context).viewInsets.bottom > 0 
                            ? 8 // Padding lebih kecil saat keyboard muncul
                            : 16, // Padding normal saat keyboard tersembunyi
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, -1),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              constraints: const BoxConstraints(
                                maxHeight: 120, // Batasi tinggi maksimal input
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: TextField(
                                controller: _messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Ask me about yoga...',
                                  hintStyle: TextStyle(color: Colors.grey),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: null, // Memungkinkan multiple lines
                                minLines: 1, // Minimal 1 baris
                                textCapitalization: TextCapitalization.sentences,
                                onSubmitted: (_) => _sendMessage(),
                                // PERBAIKAN: Scroll otomatis saat mengetik
                                onChanged: (text) {
                                  // Auto scroll saat user mengetik pesan panjang
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (_scrollController.hasClients) {
                                      _scrollController.animateTo(
                                        _scrollController.position.maxScrollExtent,
                                        duration: const Duration(milliseconds: 100),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 48, // Ukuran tetap untuk tombol
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C5530),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: IconButton(
                              onPressed: _isLoading ? null : _sendMessage,
                              icon: Icon(
                                _isLoading ? Icons.hourglass_empty : Icons.send,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2C5530),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Enhanced message container with better constraints
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75, // Dikurangi untuk memberikan ruang lebih
                minWidth: 50,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? const Color(0xFF2C5530)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Using SelectableText with proper text wrapping
                  SelectableText(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: message.isUser 
                          ? Colors.white70 
                          : Colors.grey.shade500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFA3BE8C),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 16,
              ),
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
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF2C5530),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.smart_toy,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
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

  Widget _buildDot(int index) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 6,
          height: 6 + (value * 3 * ((index % 3 + 1) / 3)),
          decoration: BoxDecoration(
            color: Colors.grey.shade400,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime timestamp) {
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
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
