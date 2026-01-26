import 'dart:io';

class LocalFileDataSource {
  Future<List<File>> scanDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      return [];
    }
    final List<FileSystemEntity> entities = await dir.list().toList();
    return entities.whereType<File>().where((file) {
      final path = file.path.toLowerCase();
      return path.endsWith('.wav') || 
             path.endsWith('.mp3') || 
             path.endsWith('.m4a') || 
             path.endsWith('.aac');
    }).toList();
  }
}
