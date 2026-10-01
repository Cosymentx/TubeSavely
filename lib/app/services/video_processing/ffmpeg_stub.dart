// 临时的FFmpeg存根实现，用于解决编译问题
// 这个文件提供了FFmpeg相关类的基本实现，避免编译错误

class FFmpegKit {
  static Future<FFmpegSession> executeAsync(
    String command,
    Function(FFmpegSession) completeCallback, [
    Function(dynamic)? logCallback,
    Function(dynamic)? statisticsCallback,
  ]) async {
    // 临时实现：直接返回失败
    final session = FFmpegSession();
    completeCallback(session);
    return session;
  }

  static Future<FFmpegSession> execute(String command) async {
    return FFmpegSession();
  }
}

class FFmpegKitConfig {
  static List<String> parseArguments(String command) {
    // 简单的命令解析
    return command.split(' ').where((arg) => arg.isNotEmpty).toList();
  }
}

class FFprobeKit {
  static Future<MediaInformationSession> getMediaInformation(
      String path) async {
    return MediaInformationSession();
  }
}

class FFmpegSession {
  Future<ReturnCode?> getReturnCode() async {
    return ReturnCode._failure();
  }
}

class MediaInformationSession {
  MediaInformation? getMediaInformation() {
    return null;
  }
}

class MediaInformation {
  String? getSize() => '0';
  String? getDuration() => '0';
  String? getBitrate() => '0';
  String? getFormat() => 'unknown';
  List<StreamInformation> getStreams() => [];
}

class StreamInformation {
  String getType() => 'unknown';
  int? getWidth() => null;
  int? getHeight() => null;
  String? getCodec() => null;
  String? getAverageFrameRate() => null;
}

class ReturnCode {
  final int _value;

  ReturnCode._(this._value);

  factory ReturnCode._success() => ReturnCode._(0);
  factory ReturnCode._failure() => ReturnCode._(1);

  static bool isSuccess(ReturnCode? code) {
    return code?._value == 0;
  }

  int getValue() => _value;
}

class Statistics {
  int getTime() => 0;
  int getSize() => 0;
}
