// lib/screens/home_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:camera/camera.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import '../models/models.dart';
import 'auth_screen.dart';
import 'camera_full_screen.dart';
import 'photo_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final CameraDescription camera;
  const HomeScreen({Key? key, required this.camera}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Box<PhotoModel> get photosBox => Hive.box<PhotoModel>('photos');
  Box<UserModel> get usersBox => Hive.box<UserModel>('users');
  Box get settings => Hive.box('settings');

  UserModel? get currentUser {
    final id = settings.get('currentUserId') as String?;
    if (id == null) return null;
    return usersBox.get(id);
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await settings.delete('currentUserId');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  Future<void> _takePhotoAndAddDetails() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Usuário não encontrado')));
      return;
    }

    debugPrint('[HomeScreen] Opening CameraFullScreen');
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraFullScreen(camera: widget.camera),
        fullscreenDialog: true,
      ),
    );

    debugPrint('[HomeScreen] returned from camera with result: $result');

    if (result == null) return;

    final XFile image = result['image'];
    final Position position = result['position'];

    if (!mounted) return;
    final detailsResult = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        final nameController = TextEditingController();
        final descController = TextEditingController();
        bool isPublic = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Detalhes da Foto',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Foto',
                        hintText: 'Ex: Obra Centro',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Detalhes do local...',
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        const Text('Tornar pública'),
                        const Spacer(),
                        Switch(
                          value: isPublic,
                          activeColor: const Color(0xFF6B4EFF),
                          onChanged: (v) => setState(() => isPublic = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    debugPrint('[HomeScreen] Dialog Cancel pressed');
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6B4EFF),
                  ),
                  onPressed: () {
                    debugPrint('[HomeScreen] Dialog Save pressed');
                    Navigator.of(dialogContext).pop({
                      'name': nameController.text.trim(),
                      'description': descController.text.trim(),
                      'isPublic': isPublic,
                    });
                  },
                  child: const Text('Salvar Foto'),
                ),
              ],
            );
          },
        );
      },
    );

    if (detailsResult == null) return;

    final id = const Uuid().v4();
    final photoModel = PhotoModel(
      id: id,
      path: image.path,
      latitude: position.latitude,
      longitude: position.longitude,
      name: (detailsResult['name'] as String).isEmpty
          ? 'Sem nome'
          : detailsResult['name'] as String,
      description: (detailsResult['description'] as String).isEmpty
          ? 'Sem descrição'
          : detailsResult['description'] as String,
      timestamp: DateTime.now(),
      ownerId: currentUser!.id,
      isPublic: detailsResult['isPublic'] as bool,
    );

    await photosBox.put(id, photoModel);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto salva com sucesso!'),
        backgroundColor: Colors.green,
      ),
    );

    setState(() {});
  }

  Future<void> _deletePhoto(PhotoModel photo) async {
    try {
      await photosBox.delete(photo.id);
      final f = File(photo.path);
      if (await f.exists()) await f.delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Foto excluída')));
    } catch (e) {
      debugPrint('Erro ao excluir: $e');
    }
  }

  List<PhotoModel> _getUserPhotos() {
    final uid = currentUser?.id;
    if (uid == null) return [];
    return photosBox.values
        .where((p) => p.ownerId == uid)
        .toList()
        .reversed
        .toList();
  }

  List<PhotoModel> _getCommunityPhotos() {
    return photosBox.values.where((p) => p.isPublic).toList().reversed.toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20,
              left: 25,
              right: 25,
              bottom: 25,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8E76FF), Color(0xFF6B4EFF)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bem-vindo ao GeoUnião',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Image.asset('assets/logo_geo_uniao.png', height: 40),
                        const SizedBox(width: 10),
                        Text(
                          user?.username ?? 'Visitante',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _logout,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF6B4EFF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF6B4EFF),
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Minhas Fotos'),
              Tab(text: 'Comunidade'),
            ],
          ),

          Expanded(
            child: ValueListenableBuilder(
              valueListenable: photosBox.listenable(),
              builder: (context, Box<PhotoModel> box, _) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPhotoGrid(_getUserPhotos(), isMine: true),
                    _buildPhotoGrid(_getCommunityPhotos(), isMine: false),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 65,
        width: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF8E76FF), Color(0xFF6B4EFF)],
          ),
          borderRadius: BorderRadius.circular(35),
        ),
        child: FloatingActionButton.extended(
          onPressed: _takePhotoAndAddDetails,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
          icon: const Icon(Icons.camera_alt, color: Colors.white, size: 26),
          label: const Text(
            'Tirar Foto',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(List<PhotoModel> photos, {required bool isMine}) {
    if (photos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 10),
            Text(
              'Nenhuma foto encontrada',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 80),
      itemCount: photos.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final p = photos[index];
        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PhotoDetailScreen(
                photo: p,
                onDelete: () {
                  if (isMine || p.ownerId == currentUser?.id) {
                    _deletePhoto(p);
                    if (Navigator.of(context).canPop())
                      Navigator.of(context).pop();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Apenas o dono pode excluir esta foto'),
                      ),
                    );
                  }
                },
              ),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        File(p.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
                  child: Column(
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMine
                            ? (p.isPublic ? 'Pública' : 'Privada')
                            : 'Por: ${usersBox.get(p.ownerId)?.username ?? 'Anônimo'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
