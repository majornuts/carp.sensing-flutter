// GENERATED CODE - DO NOT MODIFY BY HAND

part of device;

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceDatum _$DeviceDatumFromJson(Map<String, dynamic> json) => DeviceDatum(
      json['platform'] as String?,
      json['device_id'] as String?,
      deviceName: json['device_name'] as String?,
      deviceModel: json['device_model'] as String?,
      deviceManufacturer: json['device_manufacturer'] as String?,
      operatingSystem: json['operating_system'] as String?,
      hardware: json['hardware'] as String?,
    )
      ..id = json['id'] as String?
      ..timestamp = DateTime.parse(json['timestamp'] as String)
      ..sdk = json['sdk'] as String?
      ..release = json['release'] as String?;

Map<String, dynamic> _$DeviceDatumToJson(DeviceDatum instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['timestamp'] = instance.timestamp.toIso8601String();
  writeNotNull('platform', instance.platform);
  writeNotNull('device_id', instance.deviceId);
  writeNotNull('hardware', instance.hardware);
  writeNotNull('device_name', instance.deviceName);
  writeNotNull('device_manufacturer', instance.deviceManufacturer);
  writeNotNull('device_model', instance.deviceModel);
  writeNotNull('operating_system', instance.operatingSystem);
  writeNotNull('sdk', instance.sdk);
  writeNotNull('release', instance.release);
  return val;
}

BatteryDatum _$BatteryDatumFromJson(Map<String, dynamic> json) => BatteryDatum(
      json['battery_level'] as int?,
      json['battery_status'] as String?,
    )
      ..id = json['id'] as String?
      ..timestamp = DateTime.parse(json['timestamp'] as String);

Map<String, dynamic> _$BatteryDatumToJson(BatteryDatum instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['timestamp'] = instance.timestamp.toIso8601String();
  writeNotNull('battery_level', instance.batteryLevel);
  writeNotNull('battery_status', instance.batteryStatus);
  return val;
}

FreeMemoryDatum _$FreeMemoryDatumFromJson(Map<String, dynamic> json) =>
    FreeMemoryDatum(
      json['free_physical_memory'] as int?,
      json['free_virtual_memory'] as int?,
    )
      ..id = json['id'] as String?
      ..timestamp = DateTime.parse(json['timestamp'] as String);

Map<String, dynamic> _$FreeMemoryDatumToJson(FreeMemoryDatum instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['timestamp'] = instance.timestamp.toIso8601String();
  writeNotNull('free_physical_memory', instance.freePhysicalMemory);
  writeNotNull('free_virtual_memory', instance.freeVirtualMemory);
  return val;
}

ScreenDatum _$ScreenDatumFromJson(Map<String, dynamic> json) => ScreenDatum(
      json['screen_event'] as String?,
    )
      ..id = json['id'] as String?
      ..timestamp = DateTime.parse(json['timestamp'] as String);

Map<String, dynamic> _$ScreenDatumToJson(ScreenDatum instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['timestamp'] = instance.timestamp.toIso8601String();
  writeNotNull('screen_event', instance.screenEvent);
  return val;
}

TimezoneDatum _$TimezoneDatumFromJson(Map<String, dynamic> json) =>
    TimezoneDatum(
      json['timezone'] as String,
    )
      ..id = json['id'] as String?
      ..timestamp = DateTime.parse(json['timestamp'] as String);

Map<String, dynamic> _$TimezoneDatumToJson(TimezoneDatum instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['timestamp'] = instance.timestamp.toIso8601String();
  val['timezone'] = instance.timezone;
  return val;
}
