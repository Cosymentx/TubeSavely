import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tubesavely/app/data/models/download_task_model.dart';
import 'package:tubesavely/app/data/models/video_model.dart';

class DownloadService extends GetxService {
  final RxList<DownloadTaskModel> tasks = <DownloadTaskModel>[].obs;
  final Map<String, Task> _taskCache = {};

  Future<DownloadService> init() async {
    FileDownloader().updates.listen((update) {
      _taskCache[update.task.taskId] = update.task;
      final index = tasks.indexWhere((task) => task.id == update.task.taskId);
      if (index != -1) {
        final existingTask = tasks[index];
        if (update is TaskStatusUpdate) {
          tasks[index] = existingTask.copyWith(
            status: _convertStatus(update.status),
          );
        } else if (update is TaskProgressUpdate) {
          tasks[index] = existingTask.copyWith(
            downloadedBytes: (update.expectedFileSize * update.progress).toInt(),
            totalBytes: update.expectedFileSize,
          );
        }
      }
    });
    return this;
  }

  DownloadStatus _convertStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.enqueued:
        return DownloadStatus.pending;
      case TaskStatus.running:
        return DownloadStatus.downloading;
      case TaskStatus.paused:
        return DownloadStatus.paused;
      case TaskStatus.complete:
        return DownloadStatus.completed;
      case TaskStatus.canceled:
        return DownloadStatus.canceled;
      case TaskStatus.failed:
      case TaskStatus.notFound:
        return DownloadStatus.failed;
      default:
        return DownloadStatus.pending;
    }
  }

  Future<String> getDefaultDownloadPath() async => (await getApplicationCacheDirectory()).path;

  Future<DownloadTaskModel?> enqueueNewTask(
    VideoModel video, {
    required String quality,
    required String format,
    String? savePath,
  }) async {
    try {
      final String taskId = DateTime.now().millisecondsSinceEpoch.toString();
      String downloadUrl = '';
      if (video.qualities.isNotEmpty) {
        final selectedQuality = video.qualities.firstWhere(
          (q) => q.label == quality,
          orElse: () => video.qualities.first,
        );
        downloadUrl = selectedQuality.url;
      } else if (video.formats.isNotEmpty) {
        final selectedFormat = video.formats.firstWhere(
          (f) => f.label == format,
          orElse: () => video.formats.first,
        );
        downloadUrl = selectedFormat.url;
      }

      if (downloadUrl.isEmpty) {
        downloadUrl = video.url;
      }

      // 移除非法字符，保留中文、英文和常规符号
      String cleanTitle = video.title
          .replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]+'), '_')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (cleanTitle.length > 80) {
        cleanTitle = cleanTitle.substring(0, 80).trim();
      }
      final String fileName = '${cleanTitle}_$quality.$format';

      final DownloadTaskModel taskModel = DownloadTaskModel(
        id: taskId,
        videoId: video.id ?? '',
        title: video.title,
        url: downloadUrl,
        thumbnail: video.thumbnail,
        platform: video.platform,
        quality: quality,
        format: format,
        savePath: savePath,
        status: DownloadStatus.pending,
        createdAt: DateTime.now(),
      );

      tasks.add(taskModel);

      // 确保 downloadDirectory 是目录而非文件路径
      String downloadDirectory;
      if (savePath != null && Directory(savePath).existsSync()) {
        downloadDirectory = savePath;
      } else if (savePath != null && savePath.endsWith('.$format')) {
        downloadDirectory = File(savePath).parent.path;
      } else {
        downloadDirectory = savePath ?? await getDefaultDownloadPath();
      }

      final DownloadTask bgTask = DownloadTask(
        taskId: taskId,
        url: downloadUrl,
        filename: fileName,
        directory: downloadDirectory,
        baseDirectory: BaseDirectory.applicationDocuments,
        updates: Updates.statusAndProgress,
        requiresWiFi: false, // This should come from settings
        retries: 3,
        allowPause: true,
        metaData: taskId,
      );

      await FileDownloader().enqueue(bgTask);
      return taskModel;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<bool> pauseTask(String taskId) async {
    final task = _taskCache[taskId];
    if (task != null) {
      return await FileDownloader().pause(task as DownloadTask);
    }
    return false;
  }

  Future<bool> resumeTask(String taskId) async {
    final task = _taskCache[taskId];
    if (task != null) {
      return await FileDownloader().resume(task as DownloadTask);
    }
    return false;
  }

  Future<bool> cancelTask(String taskId) async {
    return await FileDownloader().cancelTaskWithId(taskId);
  }

  Future<bool> deleteTask(String taskId) async {
    await cancelTask(taskId);
    tasks.removeWhere((task) => task.id == taskId);
    _taskCache.remove(taskId);
    return true;
  }
}