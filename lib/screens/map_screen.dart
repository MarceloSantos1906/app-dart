// lib/screens/map_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/models.dart';
import 'photo_detail_screen.dart';

class MapScreen extends StatefulWidget {
  final List<PhotoModel> photos;
  final int initialIndex;

  const MapScreen({Key? key, required this.photos, this.initialIndex = 0})
    : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  LatLng get _initialCenter {
    if (widget.photos.isEmpty) return LatLng(0, 0);
    final p =
        widget.photos[widget.initialIndex.clamp(0, widget.photos.length - 1)];
    return LatLng(p.latitude, p.longitude);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        _mapController.move(_initialCenter, 15.5);
      } catch (e) {
        debugPrint('Erro ao mover mapa no init: $e');
      }
    });
  }

  void _onMarkerTap(int index) {
    final photo = widget.photos[index];
    final point = LatLng(photo.latitude, photo.longitude);
    _mapController.move(point, 16.0);
    showModalBottomSheet(
      context: context,
      builder: (_) => _buildMarkerBottomSheet(photo),
      isScrollControlled: false,
    );
  }

  Widget _buildMarkerBottomSheet(PhotoModel photo) {
    final f = File(photo.path);
    final exists = f.existsSync();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: exists
                  ? Image.file(f, width: 84, height: 84, fit: BoxFit.cover)
                  : Container(
                      width: 84,
                      height: 84,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    photo.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B4EFF),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        PhotoDetailScreen(photo: photo, onDelete: () => {}),
                  ),
                );
              },
              child: const Text('Abrir'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[];
    for (var i = 0; i < widget.photos.length; i++) {
      final p = widget.photos[i];
      markers.add(
        Marker(
          point: LatLng(p.latitude, p.longitude),
          width: 48,
          height: 48,
          child: GestureDetector(
            onTap: () => _onMarkerTap(i),
            child: Container(
              alignment: Alignment.center,
              child: const Icon(Icons.location_on, color: Colors.red, size: 36),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa - Local das fotos'),
        backgroundColor: const Color(0xFF6B4EFF),
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(initialCenter: _initialCenter, initialZoom: 15.5),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.exemplo.geouniao',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6B4EFF),
        child: const Icon(Icons.my_location),
        onPressed: () async {
          if (widget.photos.isNotEmpty) {
            final p = widget
                .photos[widget.initialIndex.clamp(0, widget.photos.length - 1)];
            _mapController.move(LatLng(p.latitude, p.longitude), 16.0);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nenhuma foto para centralizar')),
            );
          }
        },
      ),
    );
  }
}
