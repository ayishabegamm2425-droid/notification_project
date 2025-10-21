import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  
  static Future<bool> get isConnected async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _hasConnection(result);
    } catch (e) {
      return false;
    }
  }

  static Stream<bool> get connectionStream {
    return _connectivity.onConnectivityChanged.map(
      (results) => _hasConnection(results),
    );
  }

  static bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((result) => 
      result == ConnectivityResult.mobile || 
      result == ConnectivityResult.wifi ||
      result == ConnectivityResult.ethernet ||
      result == ConnectivityResult.vpn
    );
  }
}

class NoInternetOverlay extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetOverlay({
    super.key, 
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              'assets/lottie/nointernet.json',
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              repeat: true,
            ),
            const SizedBox(height: 30),
            Text(
              "No Internet Connection",
              style:GoogleFonts.urbanist(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Please check your connection and try again",
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:  Text(
                "RETRY",
                style: GoogleFonts.urbanist(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectivityWrapper extends StatefulWidget {
  final Widget child;
  final Widget? noConnectionWidget;
  final bool showOverlay;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.noConnectionWidget,
    this.showOverlay = true,
  });

  @override
  State<ConnectivityWrapper> createState() => _ConnectivityWrapperState();

  static _ConnectivityWrapperState? of(BuildContext context) {
    return context.findAncestorStateOfType<_ConnectivityWrapperState>();
  }
}

class _ConnectivityWrapperState extends State<ConnectivityWrapper> {
  bool _isConnected = true;
  bool _showingDialog = false;


  Future<void> retryConnection() async {
    final isConnected = await ConnectivityService.isConnected;
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
      if (isConnected && _showingDialog) {
        _hideNoConnectionScreen();
      } else if (!isConnected && !_showingDialog) {
        _showNoConnectionScreen();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _checkInitialConnection();
    _listenToConnectionChanges();
  }

  void _checkInitialConnection() async {
    final isConnected = await ConnectivityService.isConnected;
    if (mounted) {
      setState(() {
        _isConnected = isConnected;
      });
      if (!isConnected && widget.showOverlay) {
        _showNoConnectionScreen();
      }
    }
  }

  void _listenToConnectionChanges() {
    ConnectivityService.connectionStream.listen((isConnected) {
      if (mounted) {
        setState(() {
          _isConnected = isConnected;
        });

        if (!isConnected && widget.showOverlay && !_showingDialog) {
          _showNoConnectionScreen();
        } else if (isConnected && _showingDialog) {
          _hideNoConnectionScreen();
        }
      }
    });
  }

  void _showNoConnectionScreen() {
    if (!_showingDialog && mounted) {
      _showingDialog = true;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => NoInternetOverlay(
            onRetry: _retryConnection,
          ),
          fullscreenDialog: true,
        ),
      ).then((_) {
        _showingDialog = false;
      });
    }
  }

  void _hideNoConnectionScreen() {
    if (_showingDialog && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _retryConnection() async {
    final isConnected = await ConnectivityService.isConnected;
    if (isConnected && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected && widget.noConnectionWidget != null) {
      return widget.noConnectionWidget!;
    }
    return widget.child;
  }
}