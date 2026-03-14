import 'package:flutter/material.dart';
import 'native_media_viewer.dart';
import '../theme/app_theme.dart';

class NativeDocViewer {
  static void show(BuildContext context, String url, String title, {bool isVideo = false, bool isImage = false}) {
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
