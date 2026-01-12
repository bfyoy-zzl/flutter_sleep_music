// 1. 场景列表元数据 (对应 prebuilt_scene_config.json)
class SceneMeta {
  final String title;
  final String desp;
  final String engTitle;
  final String engDesp;
  final String imagePath;
  // cropPicSmall 和 cropPicLarge 暂时略过，UI适配时再细化

  SceneMeta({
    required this.title,
    required this.desp,
    required this.engTitle,
    required this.engDesp,
    required this.imagePath,
  });

  factory SceneMeta.fromJson(Map<String, dynamic> json) {
    return SceneMeta(
      title: json['title'] ?? '',
      desp: json['desp'] ?? '',
      engTitle: json['engTitle'] ?? '',
      engDesp: json['engDesp'] ?? '',
      imagePath: json['imagePath'] ?? '',
    );
  }
}

// 2. 具体场景的音频配置 (对应 夏雨.json 等)
class SceneAudioConfig {
  final String audioName; // 对应 assets/audio/下的文件名 (无后缀)
  final bool isLineAudio; // 是否是底噪 (循环)
  final bool isPointAudio; // 是否是点缀音
  final int frequency; // 点缀音频率
  final List<String> names; // 点缀音的具体文件名列表 (如 ["青蛙1", "青蛙2"])
  final double volume;

  SceneAudioConfig({
    required this.audioName,
    required this.isLineAudio,
    required this.isPointAudio,
    required this.frequency,
    required this.names,
    required this.volume,
  });

  factory SceneAudioConfig.fromJson(Map<String, dynamic> json) {
    return SceneAudioConfig(
      audioName: json['audioName'] ?? '',
      isLineAudio: json['isLineAudio'] ?? false,
      isPointAudio: json['isPointAudio'] ?? false,
      frequency: json['frequency'] ?? 0,
      names: List<String>.from(json['names'] ?? []),
      volume: (json['volume'] ?? 1.0).toDouble(),
    );
  }
}

// 3. 自选模式的图标配置 (对应 prebuilt_icon_config.json / prebuilt_dot_icon_config.json)
class WhiteNoiseItem {
  final String title;
  final String engTitle;
  final String icon; // 图标文件名
  final String colorParam; // 渐变色参数 "#FF...;#FF..."
  final double volume;
  final List<AudioSourceInfo> audioUrls;
  final int type; // 1: 底噪, 2: 点缀音 (根据来源判断)
  final int frequency; // 【新增】点缀音播放频率（平均间隔秒数），默认为10

  WhiteNoiseItem({
    required this.title,
    required this.engTitle,
    required this.icon,
    required this.colorParam,
    required this.volume,
    required this.audioUrls,
    required this.type,
    required this.frequency, // 【新增】构造函数入参
  });

  factory WhiteNoiseItem.fromJson(Map<String, dynamic> json, int type) {
    // 容错处理：解析音量 (可能是 String 也可能是 num)
    var vol = json['volume'];
    double volumeVal = 1.0;
    if (vol is String) {
      volumeVal = double.tryParse(vol) ?? 1.0;
    } else if (vol is num) {
      volumeVal = vol.toDouble();
    }

    // 容错处理：解析频率 (默认为 10)
    var freq = json['frequency'];
    int frequencyVal = 10;
    if (freq is int) {
      frequencyVal = freq;
    } else if (freq is String) {
      frequencyVal = int.tryParse(freq) ?? 10;
    }

    return WhiteNoiseItem(
      title: json['title'] ?? '',
      engTitle: json['engTitle'] ?? '',
      icon: json['icon'] ?? '',
      colorParam: json['colorParam'] ?? '#FFcccccc;#FF999999',
      volume: volumeVal,
      audioUrls: (json['audioUrls'] as List?)
          ?.map((e) => AudioSourceInfo.fromJson(e))
          .toList() ?? [],
      type: type,
      frequency: frequencyVal, // 【新增】赋值
    );
  }
}

class AudioSourceInfo {
  final String url; // 音频文件名
  final int duration;

  AudioSourceInfo({required this.url, required this.duration});

  factory AudioSourceInfo.fromJson(Map<String, dynamic> json) {
    return AudioSourceInfo(
      url: json['url'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }
}