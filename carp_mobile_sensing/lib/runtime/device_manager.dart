/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */
part of runtime;

/// A [DeviceRegistry] handles runtime managenent of all devices used in a
/// study configuration.
class DeviceRegistry {
  static final DeviceRegistry _instance = DeviceRegistry._();

  /// Get the singleton [DeviceRegistry].
  factory DeviceRegistry() => _instance;
  DeviceRegistry._();

  /// The list of devices running on this phone as part of a study.
  /// Mapped to their device type.
  /// Note that this model entails that only one device of the same
  /// type can be connected to a Device Manager (i.e., phone).
  final Map<String, DeviceManager> devices = {};
  Study _study;
  Study get study => _study;

  /// Initialize the device manager by specifying the running [Study].
  /// and the stream of [Datum] events to handle.
  Future initialize(Study study, Stream<Datum> data) async {
    _study = study;
    //data.listen(onDatum, onError: onError, onDone: onDone);

    _study.connectedDevices.forEach((device) async {
      DeviceManager _manager = create(device.deviceType);
      info('Creating device manager $_manager');
      await _manager.initialize(device, data);
      devices[device.deviceType] = _manager;
    });

    //addEvent(DataManagerEvent(DataManagerEventTypes.INITIALIZED));
  }

  /// Create an instance of a device manager based on the device type.
  ///
  /// This methods search the [SamplingPackageRegistry] for a [DeviceManager]
  /// which has a probe of the specified [type].
  DeviceManager create(String deviceType) {
    DeviceManager _deviceManager;

    SamplingPackageRegistry().packages.forEach((package) {
      if (package.deviceType == deviceType) {
        _deviceManager = package.deviceManager;
      }
    });

    // if (_deviceManager != null) {
    //   register(type, _deviceManager);
    //   _group.add(_deviceManager.events);
    // }
    return _deviceManager;
  }
}

/// A [DeviceManager] handles a device on runtime.
abstract class DeviceManager {
  final StreamController<DeviceStatus> _eventController =
      StreamController.broadcast();

  /// The stream of status events for this device.
  Stream<DeviceStatus> get deviceEvents => _eventController.stream;

  /// A unique runtime id of this device.
  String get id;

  /// The number of measures collected by this device.
  //int get samplingSize;

  DeviceStatus _status = DeviceStatus.unknown;

  /// The runtime status of this device.
  DeviceStatus get status => _status;

  /// Change the runtime status of this device.
  set status(DeviceStatus newStatus) {
    _status = newStatus;
    _eventController.add(newStatus);
  }

  DeviceDescriptor _descriptor;

  /// The device description for this device as specified in the
  /// [Study] protocol.
  DeviceDescriptor get descriptor => _descriptor;

  /// The runtime battery level of this device.
  int get batteryLevel;

  /// Initialize the device manager by specifying the [DeviceDescriptor].
  /// and the stream of [Datum] events to handle.
  Future initialize(DeviceDescriptor descriptor, Stream<Datum> data) async {
    info('Initializing device manager, descriptor: $_descriptor');
    _descriptor = descriptor;
    // data.listen(onDatum, onError: onError, onDone: onDone);

    // addEvent(DataManagerEvent(DataManagerEventTypes.INITIALIZED));
  }
}

class SmartphoneDeviceManager extends DeviceManager {
  String get id => DeviceInfo().deviceID;

  Future initialize(DeviceDescriptor descriptor, Stream<Datum> data) async {
    await super.initialize(descriptor, data);
    BatteryProbe()
      ..events.listen(
          (datum) => _batteryLevel = (datum as BatteryDatum).batteryLevel)
      ..initialize(Measure(
        type: MeasureType(NameSpace.CARP, DeviceSamplingPackage.BATTERY),
      ))
      ..resume();
    status = DeviceStatus.connected;
  }

  int _batteryLevel = 0;
  int get batteryLevel => _batteryLevel;
}

abstract class BTLEDeviceManager extends DeviceManager {
  /// The Bluetooth address of this BTLE device in the form
  /// `00:04:79:00:0F:4D`.
  String get macAddress;
}

/// Different status for a device.
enum DeviceStatus {
  /// The state of the device is unknown.
  unknown,

  /// The device is in an errorous state.
  error,

  /// The device is disconnected.
  disconnected,

  /// The device is connected.
  connected,

  /// The device is sampling measures.
  sampling,
}
