import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/app_colors.dart';
import '../../../data/services/socket_service.dart';
import '../../../data/services/location_foreground_service.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(rideViewModelProvider.notifier).getRideDetails(widget.rideId);
      ref.read(rideViewModelProvider.notifier).startPolling(widget.rideId);
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
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

    final markers = <Marker>{};
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
              target: pickup != null 
                  ? LatLng(pickup['latitude'], pickup['longitude']) 
                  : const LatLng(23.2599, 77.4126),
              zoom: 14,
            ),
            markers: markers,
            polylines: pickup != null && drop != null ? {
              Polyline(
                polylineId: const PolylineId('route'),
                color: AppColors.primaryPink,
                width: 4,
                points: [
                  LatLng(pickup['latitude'], pickup['longitude']),
                  LatLng(drop['latitude'], drop['longitude'])
                ],
              ),
            } : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (c) => _mapController = c,
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
                              const Text('PICKUP', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
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
