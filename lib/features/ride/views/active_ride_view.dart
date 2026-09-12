import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_colors.dart';
import '../view_models/ride_view_model.dart';

class ActiveRideView extends ConsumerStatefulWidget {
  final String rideId;
  const ActiveRideView({super.key, required this.rideId});

  @override
  ConsumerState<ActiveRideView> createState() => _ActiveRideViewState();
}

class _ActiveRideViewState extends ConsumerState<ActiveRideView> {
  final TextEditingController _otpController = TextEditingController();
  GoogleMapController? _mapController;
  
  BitmapDescriptor? _bikeIcon;
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _currentPosition;
  double _currentHeading = 0.0;
  
  Timer? _arrivedTimer;
  DateTime? _arrivedTime;
  String _previousStatus = '';

  @override
  void initState() {
    super.initState();
    _loadBikeIcon();
    _startLocationTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rideViewModelProvider.notifier).getRideDetails(widget.rideId);
      ref.read(rideViewModelProvider.notifier).startPolling(widget.rideId);
    });
  }

  Future<void> _loadBikeIcon() async {
    _bikeIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/images/bike_marker.png',
    );
    if (mounted) setState(() {});
  }

  void _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final initialPos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(initialPos.latitude, initialPos.longitude);
        _currentHeading = initialPos.heading;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 16));
    }

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2,
      ),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _currentHeading = position.heading;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(_currentPosition!),
        );
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _arrivedTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  String _formatDistance(double meters) {
    if (meters > 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  String _formatEta(double meters) {
    // Assume average city speed of 30 km/h = 8.33 m/s
    final minutes = (meters / 8.33 / 60).ceil();
    if (minutes <= 0) return '1 min';
    if (minutes > 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return '${hours}h ${mins}m';
    }
    return '$minutes mins';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rideViewModelProvider);
    final ride = state.activeRide;

    if (ride == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primaryPink)),
      );
    }

    final status = ride['status'] as String;
    final pickup = ride['pickup'];
    final drop = ride['drop'];
    final passenger = ride['passenger'];

    if (status == 'rider_arrived' && _previousStatus != 'rider_arrived') {
      _arrivedTime = ride['arrivedAt'] != null 
          ? DateTime.parse(ride['arrivedAt']) 
          : (ride['updatedAt'] != null ? DateTime.parse(ride['updatedAt']) : DateTime.now());
      _arrivedTimer?.cancel();
      _arrivedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() {});
      });
    }
    _previousStatus = status;

    String distanceText = '';
    String etaText = '';
    
    if (_currentPosition != null) {
      if (status == 'accepted' && pickup != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude, _currentPosition!.longitude,
          pickup['latitude'], pickup['longitude'],
        );
        distanceText = _formatDistance(distanceInMeters);
        etaText = _formatEta(distanceInMeters);
      } else if ((status == 'started' || status == 'in_progress') && drop != null) {
        final distanceInMeters = Geolocator.distanceBetween(
          _currentPosition!.latitude, _currentPosition!.longitude,
          drop['latitude'], drop['longitude'],
        );
        distanceText = _formatDistance(distanceInMeters);
        etaText = _formatEta(distanceInMeters);
      }
    }

    final markers = <Marker>{};
    if (_currentPosition != null && _bikeIcon != null) {
      markers.add(Marker(
        markerId: const MarkerId('rider'),
        position: _currentPosition!,
        icon: _bikeIcon!,
        anchor: const Offset(0.5, 0.5),
        rotation: _currentHeading,
        zIndex: 2, // ignore: deprecated_member_use
      ));
    }
    if (pickup != null) {
      markers.add(Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(pickup['latitude'], pickup['longitude']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ));
    }
    if (drop != null) {
      markers.add(Marker(
        markerId: const MarkerId('drop'),
        position: LatLng(drop['latitude'], drop['longitude']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
      ));
    }

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition ?? (pickup != null 
                  ? LatLng(pickup['latitude'], pickup['longitude']) 
                  : const LatLng(23.2599, 77.4126)),
              zoom: 16,
            ),
            markers: markers,
            polylines: pickup != null && drop != null ? {
              Polyline(
                polylineId: const PolylineId('route'),
                color: AppColors.successGreen,
                width: 4,
                points: [
                  LatLng(pickup['latitude'], pickup['longitude']),
                  LatLng(drop['latitude'], drop['longitude'])
                ],
              ),
            } : {},
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            onMapCreated: (c) {
              _mapController = c;
              if (_currentPosition != null) {
                c.animateCamera(CameraUpdate.newLatLngZoom(_currentPosition!, 16));
              }
            },
            padding: const EdgeInsets.only(bottom: 300), // padding for bottom sheet
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: const Icon(Icons.arrow_back),
                ),
              ),
            ),
          ),

          // Bottom Info Sheet
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4))],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),

                  // Passenger Info
                  Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.lightPink,
                          border: Border.all(color: AppColors.primaryPink, width: 2),
                        ),
                        child: const Icon(Icons.person, color: AppColors.primaryPink),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(passenger?['name'] ?? 'Passenger', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (status != 'completed' && status != 'payment_completed')
                              Text(passenger?['phoneNumber'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (status != 'completed' && status != 'payment_completed')
                        IconButton(
                          icon: const Icon(Icons.phone, color: AppColors.successGreen),
                          onPressed: () {
                            if (passenger?['phoneNumber'] != null) {
                              launchUrl(Uri.parse('tel:${passenger['phoneNumber']}'));
                            }
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.successGreen.withValues(alpha: 0.1),
                          ),
                        ),
                    ],
                  ),

                  if ((status == 'accepted' || status == 'started' || status == 'in_progress') && distanceText.isNotEmpty && etaText.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text('Distance', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(distanceText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          Container(height: 30, width: 1, color: Colors.grey[300]),
                          Column(
                            children: [
                              const Text('ETA', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(etaText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryPink)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Address Info
                  if (status == 'accepted' || status == 'rider_arrived') ...[
                    Row(
                      children: [
                        const Icon(Icons.my_location, color: AppColors.primaryPink, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('PICKUP', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                  if (status == 'rider_arrived' && _arrivedTime != null)
                                    Text('Waiting: ${_formatDuration(DateTime.now().difference(_arrivedTime!))}', 
                                      style: const TextStyle(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text(pickup?['address'] ?? 'Loading...', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ] else if (status == 'started' || status == 'in_progress') ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppColors.successGreen, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('DROP-OFF', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                              Text(drop?['address'] ?? 'Loading...', style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Actions based on status
                  _buildActionArea(status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionArea(String status) {
    final vm = ref.read(rideViewModelProvider.notifier);
    final state = ref.watch(rideViewModelProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryPink));
    }

    if (status == 'accepted') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPink,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => vm.markArrived(widget.rideId),
        child: const Text("I've Arrived at Pickup", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }

    if (status == 'rider_arrived') {
      return Column(
        children: [
          TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '----',
              counterText: '',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (_otpController.text.length == 4) {
                vm.startRide(widget.rideId, _otpController.text);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter 4-digit OTP')));
              }
            },
            child: const Text("Verify OTP & Start Ride", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    if (status == 'started' || status == 'in_progress') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryPink,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => vm.completeRide(widget.rideId),
        child: const Text("Complete Ride", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }

    if (status == 'completed') {
      final ride = state.activeRide;
      final fare = ride?['finalFare'] ?? ride?['estimatedFare'] ?? 0;
      
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.lightPink, borderRadius: BorderRadius.circular(12)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Fare to Collect', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                Text('₹$fare', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final success = await vm.confirmCashPayment(widget.rideId);
              if (success && mounted) {
                context.go('/home');
              }
            },
            child: const Text("Cash Collected → Done", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      );
    }

    return const SizedBox();
  }
}
