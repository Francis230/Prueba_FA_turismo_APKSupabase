import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:prueba_apkturismo_sbfr/core/services/supabase_service.dart';

class EditSitePage extends StatefulWidget {
  final Map<String, dynamic> site;
  const EditSitePage({super.key, required this.site});

  @override
  State<EditSitePage> createState() => _EditSitePageState();
}

class _EditSitePageState extends State<EditSitePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  bool _isLoading = false;
  bool _updatePhotos = false;
  bool _updateLocation = false;

  List<String> _existingPhotos = [];
  List<String> _photosToKeep = [];
  List<XFile> _newPhotos = [];

  double? _newLatitude;
  double? _newLongitude;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.site['title']);
    _descriptionController = TextEditingController(text: widget.site['description']);
    _existingPhotos = List<String>.from(
      (widget.site['photos'] as List).map((p) => p['image_url']),
    );
    _photosToKeep = List.from(_existingPhotos);
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      if ((_photosToKeep.length + picked.length) > 5) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Máximo 5 fotos permitidas.'),
        ));
        return;
      }
      setState(() => _newPhotos.addAll(picked));
    }
  }

  Future<void> _pickImageFromCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      if ((_photosToKeep.length + _newPhotos.length + 1) > 5) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Máximo 5 fotos permitidas.'),
        ));
        return;
      }
      setState(() => _newPhotos.add(photo));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Seleccionar desde galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Tomar una foto'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _newLatitude = position.latitude;
        _newLongitude = position.longitude;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener ubicación: $e')),
      );
    }
  }

  Future<void> _updateSite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final supabase = context.read<SupabaseService>();
    final siteId = widget.site['id'];

    try {
      await supabase.updateSite(
        siteId: siteId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: _updateLocation && _newLatitude != null ? _newLatitude : null,
        longitude: _updateLocation && _newLongitude != null ? _newLongitude : null,
      );

      if (_updatePhotos) {
        await supabase.updatePartialSitePhotos(
          siteId: siteId,
          photosToKeep: _photosToKeep,
          newPhotos: _newPhotos,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sitio actualizado con éxito')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Sitio')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título del Sitio',
                        prefixIcon: Icon(LucideIcons.mapPin),
                      ),
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'El título es requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: Icon(LucideIcons.fileText),
                      ),
                      maxLines: 5,
                      validator: (value) =>
                          (value == null || value.isEmpty) ? 'La descripción es requerida' : null,
                    ),
                    const Divider(height: 32),

                    SwitchListTile(
                      title: const Text('¿Actualizar las fotos?'),
                      value: _updatePhotos,
                      secondary: const Icon(LucideIcons.imagePlus),
                      onChanged: (value) => setState(() => _updatePhotos = value),
                    ),
                    if (_updatePhotos) ...[
                      const Text('Fotos actuales:'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _existingPhotos.map((url) {
                          final isKept = _photosToKeep.contains(url);
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  url,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: IconButton(
                                  icon: Icon(
                                    isKept ? Icons.check_box : Icons.check_box_outline_blank,
                                    color: isKept ? const Color.fromARGB(255, 18, 201, 24) : const Color.fromARGB(255, 0, 0, 0),
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (isKept) {
                                        _photosToKeep.remove(url);
                                      } else {
                                        if (_photosToKeep.length + _newPhotos.length < 5) {
                                          _photosToKeep.add(url);
                                        }
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: PopupMenuButton<String>(
                          color: const Color.fromARGB(255, 0, 0, 0),
                          onSelected: (value) {
                            if (value == 'camera') {
                              _pickImageFromCamera();
                            } else {
                              _pickImageFromGallery();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'camera',
                              child: ListTile(
                                leading: Icon(Icons.photo_camera),
                                title: Text('Tomar con cámara'),
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'gallery',
                              child: ListTile(
                                leading: Icon(Icons.photo_library),
                                title: Text('Elegir desde galería'),
                              ),
                            ),
                          ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.amber[700],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.add_a_photo, color: Colors.black),
                                SizedBox(width: 8),
                                Text('Agregar foto', style: TextStyle(color: Colors.black)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_newPhotos.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: _newPhotos.map((photo) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(photo.path),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            );
                          }).toList(),
                        ),
                    ],

                    const SizedBox(height: 24),

                    SwitchListTile(
                      title: const Text('¿Actualizar ubicación actual?'),
                      value: _updateLocation,
                      secondary: const Icon(LucideIcons.locateFixed),
                      onChanged: (value) async {
                        setState(() => _updateLocation = value);
                        if (value) await _getCurrentLocation();
                      },
                    ),
                    if (_updateLocation && _newLatitude != null && _newLongitude != null)
                      Text(
                        'Nueva ubicación: ($_newLatitude, $_newLongitude)',
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),

                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(LucideIcons.save),
                      label: const Text('Guardar Cambios'),
                      onPressed: _updateSite,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
