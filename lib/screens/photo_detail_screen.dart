// lib/screens/photo_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'map_screen.dart'; // Certifique-se de que este arquivo exista em lib/screens/map_screen.dart

class PhotoDetailScreen extends StatelessWidget {
  final PhotoModel photo;
  final VoidCallback onDelete;

  const PhotoDetailScreen({
    Key? key,
    required this.photo,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy HH:mm');
    final file = File(photo.path);
    final exists = file.existsSync();
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: exists
                        ? Image.file(File(photo.path), fit: BoxFit.contain)
                        : const Icon(Icons.broken_image, size: 80, color: Colors.white30),
                  ),
                ),

                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(photo.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 6),
                      Text(photo.description),
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${photo.latitude.toStringAsFixed(6)}  Lon: ${photo.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text('Data: ${df.format(photo.timestamp)}', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              label: const Text('Excluir', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirmar'),
                                    content: const Text('Deseja excluir esta foto?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          onDelete();
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.map_rounded, color: Colors.white),
                              label: const Text('Ver no mapa', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6B4EFF),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => MapScreen(photos: [photo], initialIndex: 0),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            Positioned(
              top: topPadding + 8,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}