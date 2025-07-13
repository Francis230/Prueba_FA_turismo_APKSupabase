// 1. lib/sites/add_site_page.dart
// Formulario completo para que los "Publicadores" creen nuevos sitios.

import 'dart:io';
import 'package:prueba_apkturismo_sbfr/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class AddSitePage extends StatefulWidget {
  const AddSitePage({super.key});

  @override
  State<AddSitePage> createState() => _AddSitePageState();
}

class _AddSitePageState extends State<AddSitePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<XFile> _selectedImages = [];
  Position? _currentPosition;
  bool _isLoading = false;

  /// Muestra un menú para elegir entre Cámara y Galería.
  void _showImageSourceActionSheet(BuildContext context) {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ya has alcanzado el límite de 5 fotos.')));
      return;
    }
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Elegir de la Galería'),
              onTap: () {
                Navigator.of(context).pop();
                _selectImagesFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Tomar Foto'),
              onTap: () {
                Navigator.of(context).pop();
                _takePhotoWithCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Abre la galería para seleccionar varias imágenes.
  Future<void> _selectImagesFromGallery() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles);
          if (_selectedImages.length > 5) {
            _selectedImages = _selectedImages.sublist(0, 5);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Límite de 5 fotos alcanzado.')));
          }
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al seleccionar imágenes: $e')));
    }
  }

  /// Abre la cámara para tomar una foto.
  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(pickedFile);
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al tomar la foto: $e')));
    }
  }

  /// Obtiene la ubicación actual del dispositivo.
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('El servicio de GPS está desactivado.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Permiso de ubicación denegado.');
      }
      if (permission == LocationPermission.deniedForever) throw Exception('Permiso de ubicación denegado permanentemente.');
      
      _currentPosition = await Geolocator.getCurrentPosition();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Valida el formulario y publica el sitio.
  Future<void> _publishSite() async {
    if (_formKey.currentState!.validate()) {
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, obtén la ubicación del sitio.')));
        return;
      }
      if (_selectedImages.length < 5) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes subir exactamente 5 fotografías.')));
        return;
      }
      setState(() => _isLoading = true);
      try {
        await context.read<SupabaseService>().publishNewSite(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          latitude: _currentPosition!.latitude,
          longitude: _currentPosition!.longitude,
          photos: _selectedImages,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Sitio publicado con éxito!'), backgroundColor: Colors.green));
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al publicar el sitio: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Añadir Nuevo Sitio')),
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
                      decoration: const InputDecoration(labelText: 'Título del Sitio'),
                      validator: (value) => (value == null || value.isEmpty) ? 'El título es requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                      maxLines: 4,
                      validator: (value) => (value == null || value.isEmpty) ? 'La descripción es requerida' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.location_on),
                      label: const Text('Obtener Ubicación Actual'),
                      onPressed: _getCurrentLocation,
                    ),
                    if (_currentPosition != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Ubicación obtenida: Lat: ${_currentPosition!.latitude.toStringAsFixed(4)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(4)}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Añadir Fotografías'),
                      onPressed: () => _showImageSourceActionSheet(context),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${_selectedImages.length} de 5 fotos seleccionadas.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedImages.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _selectedImages.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(_selectedImages[index].path),
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _publishSite,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
                      child: const Text('Publicar Sitio'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}