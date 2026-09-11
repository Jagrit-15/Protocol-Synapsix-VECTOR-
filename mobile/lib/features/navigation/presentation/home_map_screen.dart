import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared_widgets/gnss_status_badge.dart';
import 'pipeline_providers.dart';

import '../../../core/utils/tile_cache_provider.dart';
import '../domain/gnss_status.dart';

class HomeMapScreen extends ConsumerStatefulWidget {
  const HomeMapScreen({super.key});

  @override
  ConsumerState<HomeMapScreen> createState() => _HomeMapScreenState();
}

class _HomeMapScreenState extends ConsumerState<HomeMapScreen> {
  final MapController _mapController = MapController();
  bool _mapReady = false;
  bool _liveMode = false;
  CachedTileProvider? _cachedTileProvider;

  @override
  void initState() {
    super.initState();
    TileCacheProvider.build().then((p) {
      if (mounted) setState(() => _cachedTileProvider = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_liveMode ? 'Home / Map (Live)' : 'Home / Map (Demo)'),
        actions: [
          IconButton(
            tooltip: 'Sensor debug screen',
            onPressed: () => Navigator.of(context).pushNamed('/sensor-debug'),
            icon: const Icon(Icons.bug_report),
          ),
          IconButton(
            tooltip: _liveMode ? 'Switch to demo' : 'Switch to live GPS',
            onPressed: () => setState(() => _liveMode = !_liveMode),
            icon: Icon(_liveMode ? Icons.smart_toy : Icons.gps_fixed),
          ),
          IconButton(
            tooltip: 'Turn-by-turn',
            onPressed: () => Navigator.of(context).pushNamed('/navigate'),
            icon: const Icon(Icons.navigation),
          ),
        ],
      ),
      body: _liveMode ? _buildLiveMap() : _buildDemoMap(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              break;
            case 1:
              Navigator.of(context).pushNamed('/trips');
            case 2:
              Navigator.of(context).pushNamed('/settings');
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: 'Map'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Trips'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildLiveMap() {
    final live = ref.watch(liveLocationProvider);

    ref.listen(liveLocationProvider, (_, next) {
      if (!_mapReady || !next.hasFix) return;
      _mapController.move(
        LatLng(next.lat!, next.lon!),
        _mapController.camera.zoom,
      );
    });

    final center = live.hasFix
        ? LatLng(live.lat!, live.lon!)
        : const LatLng(AppConstants.demoOriginLat, AppConstants.demoOriginLon);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 17,
            onMapReady: () => _mapReady = true,
          ),
          children: [
            TileLayer(
              urlTemplate: AppConstants.osmTileUrl,
              userAgentPackageName: AppConstants.osmUserAgent,
              tileProvider: _cachedTileProvider,
            ),
            if (live.hasFix)
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 20,
                    height: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          child: GnssStatusBadge(
            status: live.hasFix ? GnssStatus.good : GnssStatus.deadReckoningActive,
          ),
        ),
        if (!live.hasFix)
          const Positioned(
            left: 12,
            right: 12,
            bottom: 24,
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text('Waiting for GPS fix...'),
              ),
            ),
          ),
        if (live.hasFix)
          Positioned(
            left: 12,
            right: 12,
            bottom: 24,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Lat ${live.lat!.toStringAsFixed(6)}, '
                  'Lon ${live.lon!.toStringAsFixed(6)}\n'
                  'Accuracy +/-${live.accuracyM?.toStringAsFixed(1) ?? '?'} m',
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDemoMap() {
    final controller = ref.watch(demoScenarioProvider);
    final snap = controller.snapshot;
    final center = LatLng(snap.snapped.lat, snap.snapped.lon);

    ref.listen(demoScenarioProvider, (_, next) {
      if (!_mapReady) return;
      final p = next.snapshot.snapped;
      _mapController.move(LatLng(p.lat, p.lon), _mapController.camera.zoom);
    });

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(
              AppConstants.demoOriginLat,
              AppConstants.demoOriginLon,
            ),
            initialZoom: 16,
            onMapReady: () => _mapReady = true,
          ),
          children: [
            TileLayer(
              urlTemplate: AppConstants.osmTileUrl,
              userAgentPackageName: AppConstants.osmUserAgent,
              tileProvider: _cachedTileProvider,
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: snap.pose.covarianceMajor,
                  useRadiusInMeter: true,
                  color: Colors.teal.withValues(alpha: 0.18),
                  borderStrokeWidth: 1.5,
                  borderColor: Colors.teal,
                ),
              ],
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 16,
                  height: 16,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          child: GnssStatusBadge(status: snap.gnssStatus),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 24,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Motion: ${snap.motion.stateLabel.name}  '
                    '(${(snap.motion.confidence * 100).round()}%)',
                  ),
                  Text(
                    'Cov major ${snap.pose.covarianceMajor.toStringAsFixed(1)} m  -  '
                    'ellipse grows in tunnel, shrinks on GNSS reacquire',
                  ),
                  if (snap.lastError != null)
                    Text(
                      snap.lastError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}