import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class UserStopReminder extends StatefulWidget {
  const UserStopReminder({super.key});

  @override
  State<UserStopReminder> createState() => _UserStopReminderState();
}

class _UserStopReminderState extends State<UserStopReminder> {
  String? _currentUserPhone;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, DocumentSnapshot> _eventCache = {};

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 200,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: 150,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    width: double.infinity,
                    height: 35,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
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


  Future<void> _getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null && user.phoneNumber != null) {
      setState(() {
        _currentUserPhone = user.phoneNumber;
      });
    }
  }

  Future<void> _stopReminder(String notificationId) async {
    try {
      await _firestore
          .collection('scheduledEventNotifications')
          .doc(notificationId)
          .update({
        'status': 'stop',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder stopped successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<DocumentSnapshot>> _fetchAllEvents(List<String> eventIds) async {
    final futures = eventIds.map((id) => _firestore.collection('Events').doc(id).get());
    return await Future.wait(futures);
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
  }

  String _formatTime(Timestamp timestamp) {
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  Future<void> _showConfirmationDialog(String notificationId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 8,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.notification_important_outlined,
                  color: Colors.orange[700],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Stop Reminder',
                  style: GoogleFonts.urbanist(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Are you sure you want to stop this reminder? This action cannot be undone.',
              style: GoogleFonts.urbanist(
                fontSize: 15,
                height: 1.4,
                color: Colors.grey[700],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.urbanist(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red[700],
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.red.withOpacity(0.2))),
             ),
              child: Text(
                'Stop',
                style: GoogleFonts.urbanist(
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _stopReminder(notificationId);
              },
            ),
          ],

        );
      },
    );
  }

  Color _getStatusBackgroundColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.green.withOpacity(0.1);
      case 'stop':
        return Colors.red.withOpacity(0.1);
      case 'completed':
        return Colors.blue.withOpacity(0.1);
      default:
        return Colors.grey.withOpacity(0.1);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.green;
      case 'stop':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      appBar: AppBar(
        title: Text(
          'My Event Reminders',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xff1F75EC),
        foregroundColor: Colors.white,
        elevation: 0,
      
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('scheduledEventNotifications')
            .orderBy('createdAt', descending: true)
            .where('type', isEqualTo: 'reminder')
            .where('userId', isEqualTo: _currentUserPhone)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(12),
              itemCount: 3,
              itemBuilder: (context, index) => _buildShimmerCard(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No active reminders',
                    style: GoogleFonts.urbanist(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final notifications = snapshot.data!.docs;
          final eventIds = notifications.map((doc) => doc['eventId'] as String).toList();
          
          return FutureBuilder<List<DocumentSnapshot>>(
            future: _fetchAllEvents(eventIds),
            builder: (context, eventsSnapshot) {
              if (eventsSnapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) => _buildShimmerCard(),
                );
              }

              if (!eventsSnapshot.hasData) {
                return Center(child: Text('Failed to load events'));
              }

              _eventCache.clear();
              for (var doc in eventsSnapshot.data!) {
                _eventCache[doc.id] = doc;
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  final notificationId = notification.id;
                  final eventId = notification['eventId'];
                  final status = notification['status'];
                  final isScheduled = status == 'scheduled';
                  final eventData = _eventCache[eventId]?.data() as Map<String, dynamic>?;
                  
                  if (eventData == null) {
                    return const SizedBox();
                  }

                  final eventDate = eventData['eventdate'] as Timestamp?;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event name and status in same row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  eventData['name'] ?? 'Event Name',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusBackgroundColor(status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: GoogleFonts.urbanist(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getStatusTextColor(status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Location
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  eventData['location'] ?? 'Location not specified',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Date and time
                          if (eventDate != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(eventDate),
                                  style: GoogleFonts.urbanist(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.access_time,
                                  size: 12,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTime(eventDate),
                                  style: GoogleFonts.urbanist(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          // Stop reminder button
                          if (isScheduled)
                            SizedBox(
                              width: double.infinity,
                              height: 35,
                              child: ElevatedButton(
                                onPressed: () => _showConfirmationDialog(notificationId),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'STOP REMINDER',
                                  style: GoogleFonts.urbanist(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}