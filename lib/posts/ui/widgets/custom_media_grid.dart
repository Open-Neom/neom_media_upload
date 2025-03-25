import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:neom_commons/core/utils/app_color.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';

class CustomMediaGrid extends StatefulWidget {
  const CustomMediaGrid({Key? key}) : super(key: key);

  @override
  State<CustomMediaGrid> createState() => _CustomMediaGridState();
}

class _CustomMediaGridState extends State<CustomMediaGrid> {
  final ScrollController _scrollController = ScrollController();

  /// Lista de álbumes (directorios)
  List<AssetPathEntity> _albums = [];

  /// Álbum seleccionado
  AssetPathEntity? _selectedAlbum;

  /// Lista de archivos cargados (fotos y videos)
  List<AssetEntity> _mediaList = [];

  /// Variables de paginación
  bool _isLastPage = false;
  bool _isLoading = false;
  int _currentPage = 0;
  final int _pageSize = 50;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadAlbums();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Detecta si estamos cerca del final para cargar más
  void _onScroll() {
    if (!_isLoading &&
        !_isLastPage &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreAssets();
    }
  }

  /// Pide permisos y carga la lista de álbumes
  Future<void> _loadAlbums() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (result.isAuth) {
      final albumList = await PhotoManager.getAssetPathList(
        type: RequestType.all, // Fotos y videos
      );
      setState(() {
        _albums = albumList;
      });

      if (albumList.isNotEmpty) {
        // Selecciona el primer álbum por defecto
        _selectAlbum(albumList.first);
      }
    } else {
      debugPrint('Permiso denegado o no concedido');
      // Muestra un mensaje o maneja el caso de permiso denegado
    }
  }

  /// Cambia de álbum y reinicia la paginación
  void _selectAlbum(AssetPathEntity album) {
    setState(() {
      _selectedAlbum = album;
      _mediaList.clear();
      _currentPage = 0;
      _isLastPage = false;
    });
    _loadMoreAssets();
  }

  /// Carga más assets (paginación)
  Future<void> _loadMoreAssets() async {
    if (_selectedAlbum == null || _isLoading || _isLastPage) return;

    setState(() => _isLoading = true);

    final newAssets = await _selectedAlbum!.getAssetListPaged(
      page: _currentPage,
      size: _pageSize,
    );

    // Si se devuelven menos de _pageSize, ya no hay más
    if (newAssets.length < _pageSize) {
      _isLastPage = true;
    }

    setState(() {
      _mediaList.addAll(newAssets);
      _currentPage++;
      _isLoading = false;
    });
  }

  /// Bottom sheet para tomar foto o grabar video
  Future<void> _pickFromCamera() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(context, 'photo'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Grabar video'),
                onTap: () => Navigator.pop(context, 'video'),
              ),
            ],
          ),
        );
      },
    );

    if (choice == 'photo') {
      final XFile? photo = await ImagePicker().pickImage(
        source: ImageSource.camera,
      );
      if (photo != null) {
        debugPrint('Foto tomada: ${photo.path}');
        // Maneja la foto (subirla, editarla, etc.)
      }
    } else if (choice == 'video') {
      final XFile? video = await ImagePicker().pickVideo(
        source: ImageSource.camera,
      );
      if (video != null) {
        debugPrint('Video grabado: ${video.path}');
        // Maneja el video (reproducirlo, subirlo, etc.)
      }
    }
  }

  /// Muestra ícono de "play" y duración si es un video
  List<Widget> _buildVideoOverlays(AssetEntity asset) {
    final duration = Duration(seconds: asset.duration);
    final minutes =
    duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
    duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return [
      const Positioned(
        bottom: 5,
        right: 5,
        child: Icon(Icons.play_circle_fill, color: Colors.white),
      ),
      Positioned(
        bottom: 5,
        left: 5,
        child: Container(
          color: Colors.black54,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            '$minutes:$seconds',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = _mediaList.length;

    return Scaffold(
      // --- APP BAR PERSONALIZADO ---
      backgroundColor: AppColor.main50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Nueva Publicación'),
        centerTitle: true,
        actions: [
          // Ícono de cámara para foto/video
          IconButton(
            icon: const Icon(Icons.camera_alt),
            onPressed: _pickFromCamera,
          ),
        ],
        backgroundColor: AppColor.getMain(),
      ),

      // --- CONTENIDO ---
      body: Column(
        children: [
          // Barra superior para elegir álbum (directorio)
          if (_albums.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Texto o ícono para representar la galería
                  const Icon(Icons.folder),
                  const SizedBox(width: 8),
                  // Dropdown de álbumes
                  DropdownButton<AssetPathEntity>(
                    value: _selectedAlbum,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: AppColor.main75,
                    onChanged: (album) {
                      if (album != null) {
                        _selectAlbum(album);
                      }
                    },
                    items: _albums.map((album) {
                      return DropdownMenuItem<AssetPathEntity>(
                        value: album,
                        child: Text(album.name),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Grid con scroll infinito
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              itemCount: itemCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,   // 3 columnas
                crossAxisSpacing: 2, // Espacio horizontal
                mainAxisSpacing: 2,  // Espacio vertical
              ),
              itemBuilder: (context, index) {
                final asset = _mediaList[index];
                return FutureBuilder<Uint8List?>(
                  future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData) {
                      final bytes = snapshot.data!;
                      return GestureDetector(
                        onTap: () async {
                          final file = await asset.file;
                          if (file != null) {
                            debugPrint('Archivo seleccionado: ${file.path}');
                            // Aquí podrías abrir un editor, reproducir video, etc.
                          }
                        },
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.memory(bytes, fit: BoxFit.cover),
                            ),
                            if (asset.type == AssetType.video)
                              ..._buildVideoOverlays(asset),
                          ],
                        ),
                      );
                    }
                    return Container(color: Colors.grey);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
