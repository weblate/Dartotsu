import 'dart:io';

import 'package:path/path.dart' as p;

import '../../Core/Downloads/ChapterFetcher.dart';
import '../../Core/NetworkManager/NetworkManager.dart';
import '../../Core/Preferences/StorageManager.dart';
import '../../Core/State/State.dart';

String imageFileName(String name) {
  final clean = name
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  return clean.isEmpty ? 'image' : clean;
}

Future<File> _namedTarget(File source, String name) async {
  final temp = (await StorageManager.getTmpDirectory())!;
  final head = await source.openRead(0, 16).expand((b) => b).toList();
  final ext = sniffImageExtension(head) ?? 'jpg';
  final target = File(p.join(temp.path, '${imageFileName(name)}.$ext'));
  if (await target.exists()) await target.delete();
  return target;
}

Future<File> downloadImage(String url, {required String name}) async {
  final temp = (await StorageManager.getTmpDirectory())!;
  final part = File(p.join(temp.path, 'img_${url.hashCode.abs()}.part'));
  await find<NetworkManager>().download(url, part.path);
  return part.rename((await _namedTarget(part, name)).path);
}

Future<File> namedImageCopy(File source, {required String name}) async =>
    source.copy((await _namedTarget(source, name)).path);

Future<File> saveImageFile(File source, {required String name}) async {
  final dir = await StorageManager.getDirectory(subPath: 'images');
  if (dir == null) throw const FileSystemException('No storage available');
  final ext = p.extension(source.path);
  final base = imageFileName(name);
  var target = File(p.join(dir.path, '$base$ext'));
  for (var i = 2; await target.exists(); i++) {
    target = File(p.join(dir.path, '$base ($i)$ext'));
  }
  return source.copy(target.path);
}
