import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import '../screens/native_media_viewer.dart';
import '../theme/app_theme.dart';

class NativeDocViewer {
  static Future<void> show(BuildContext context, String url, String title, {bool isVideo = false, bool isImage = false}) async {
    // Si no es un video ni una imagen, queremos forzar descarga / apertura externa
    if (!isVideo && !isImage) {
      try {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Descargando archivo para abrirlo...')),
          );
        }
        
        final tempDir = await getTemporaryDirectory();
        final fileName = url.split('/').last;
        final savePath = '${tempDir.path}/$fileName';
        
        final dio = Dio();
        await dio.download(url, savePath);
        
        final result = await OpenFilex.open(savePath);
        
        if (result.type != ResultType.done && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No hay app instalada para este archivo. ${result.message}')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al preparar el archivo: $e')),
          );
        }
      }
      return; 
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    Expanded(
                      child: Text(
                        title, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download), 
                      onPressed: () {
                        // Future: implement download
                      }
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: NativeMediaViewer(
                  url: url,
                  isVideo: isVideo,
                  isImage: isImage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
