import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class EventMessagesPage extends StatefulWidget {
  final String eventId;
  
  const EventMessagesPage({super.key, required this.eventId});

  @override
  State<EventMessagesPage> createState() => _EventMessagesPageState();
}

class _EventMessagesPageState extends State<EventMessagesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _currentUserPhone;

  @override
  void initState() {
    super.initState();
    _getCurrentUserPhone();
  }

  Future<void> _getCurrentUserPhone() async {
    final user = _auth.currentUser;
    if (user != null && user.phoneNumber != null) {
      setState(() {
        _currentUserPhone = user.phoneNumber;
      });
    }
  }
Color _getCategoryColor(String category) {
  switch (category.toLowerCase()) {
    case 'music':
      return const Color(0xFF9C27B0); // Purple
    case 'sports':
      return const Color(0xFFF44336); // Red
    case 'food':
      return const Color(0xFF4CAF50); // Green
    case 'art':
      return const Color(0xFF2196F3); // Blue
    case 'business':
      return const Color(0xFFFF9800); // Orange
    case 'education':
      return const Color(0xFF607D8B); // Blue Grey
    default:
      return const Color(0xff1F75EC); // Default blue
  }
}
  @override
  Widget build(BuildContext context) {
    if (_currentUserPhone == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xff1F75EC)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }
return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [

SliverAppBar(
  expandedHeight: 60, // Reduced from 100 to make it more compact
  collapsedHeight: 60, // Explicitly set collapsed height
  floating: false,
  pinned: true,
  automaticallyImplyLeading: false,
  elevation: 2,
  backgroundColor: const Color(0xff1F75EC),
  titleSpacing: 0, // Reduce spacing around title
  toolbarHeight: 60, // Control the toolbar height
  title: StreamBuilder<DocumentSnapshot>(
    stream: _firestore.collection('Events').doc(widget.eventId).snapshots(),
    builder: (context, eventSnapshot) {
      if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
        return const Text(
          "Loading...",
          style: TextStyle(
            color: Colors.white,
            fontSize: 16, // Slightly smaller font when loading
          ),
        );
      }

      final event = eventSnapshot.data!;
      final name = event['name'] ?? '';

      return Padding(
        padding: const EdgeInsets.only(left: 8.0), // Add slight padding
        child: Text(
          name,
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.w600, // Slightly less bold
            fontSize: 16,
            color: Colors.white,
          ),
          maxLines: 1, // Only one line to save space
          overflow: TextOverflow.ellipsis,
        ),
      );
    },
  ),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20), // Smaller icon
    onPressed: () => Navigator.of(context).pop(),
    padding: EdgeInsets.zero, // Remove extra padding
  ),
),
   // Event Details Section (below the image)
          SliverToBoxAdapter(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('Events').doc(widget.eventId).snapshots(),
              builder: (context, eventSnapshot) {
                if (eventSnapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    margin: const EdgeInsets.all(16),
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
                  return Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(child: Text('Event not found')),
                  );
                }

                final event = eventSnapshot.data!;
                final description = event['description'] ?? '';
                final location = event['location'] ?? '';
                final category = event['category'] ?? ''; // Get the category field
                final timestamp = event['eventdate'] as Timestamp?;
                final dateTime = timestamp?.toDate() ?? DateTime.now();
                final formattedDate = DateFormat('dd MMM yyyy').format(dateTime);
                final formattedTime = DateFormat('hh:mm a').format(dateTime);
         
      return Container(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8.0),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                 // Event Description Section
   if (description.isNotEmpty) ...[
  Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade100.withOpacity(0.5),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'About This Event',
              style: GoogleFonts.urbanist(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            if (category.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  category.toUpperCase(),
                  style: GoogleFonts.urbanist(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        // Date and Time Row
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 16,
              color: Colors.blue.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              '$formattedDate at $formattedTime',
              style: GoogleFonts.urbanist(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Location Row
        if (location.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.red.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location,
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        // Description Text
        Text(
          description,
          style: GoogleFonts.urbanist(
            fontSize: 12,
            color: Colors.grey.shade700,
            height: 1.5,
          ),
        ),
      ],
    ),
  ),
],
                ],
              ),
              
             
            ],
          ),
        ),
      );
    },
            ),
          ),

          // Messages Section Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xff1F75EC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.message,
                      color: Color(0xff1F75EC),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Event Messages',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Messages List
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('Users')
                .doc(_currentUserPhone)
                .collection('NOTIFICATIONS')
                .where('eventId', isEqualTo: widget.eventId)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'Error loading messages: ${snapshot.error}',
                      style: GoogleFonts.urbanist(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.message_outlined,
                            size: 24,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet',
                          style: GoogleFonts.urbanist(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Messages about this event will appear here',
                          style: GoogleFonts.urbanist(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final messages = snapshot.data!.docs;

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final msg = messages[index];
                    final messageText = msg['message'] ?? '';
                    final timestamp = msg['timestamp'] as Timestamp?;
                    final formattedTime = timestamp != null
                        ? DateFormat('dd MMM, hh:mm a').format(timestamp.toDate())
                        : '';

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xff1F75EC), Color(0xff4A90E2)],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xff1F75EC).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      messageText,
                                      style: GoogleFonts.urbanist(
                                        fontSize: 12,
                                        height: 1.4,
                                        color: const Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 10,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          formattedTime,
                                          style: GoogleFonts.urbanist(
                                            fontSize: 10,
                                            color: Colors.grey.shade500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: messages.length,
                ),
              );
            },
          ),

          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );

  }
}