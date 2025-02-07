/*
 * Copyright 2018 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of carp_backend;

/// Stores CAMS data points in the CARP backend.
///
/// Every time a CARP json data object is created, it is uploaded to CARP.
/// Hence, this interface only works when the device is online.
/// If offline data storage and forward is needed, use the [CarpUploadMethod.FILE]
/// or [CarpUploadMethod.BATCH_DATA_POINT] instead. These methods will buffer files for upload, if offline.
class CarpDataManager extends AbstractDataManager {
  bool _initialized = false;
  late CarpDataEndPoint carpEndPoint;
  late FileDataManager fileDataManager;

  CarpDataManager() : super() {
    // Initialization of serialization
    CarpMobileSensing();

    // register for de-serialization
    FromJsonFactory().register(CarpDataEndPoint(
      uploadMethod: CarpUploadMethod.FILE,
      name: '',
      uri: '',
    ));
  }

  String get type => DataEndPointTypes.CARP;

  Future initialize(
    DataEndPoint dataEndPoint,
    MasterDeviceDeployment deployment,
    Stream<DataPoint> data,
  ) async {
    super.initialize(dataEndPoint, deployment, data);
    assert(dataEndPoint is CarpDataEndPoint);
    carpEndPoint = dataEndPoint as CarpDataEndPoint;

    if ((carpEndPoint.uploadMethod == CarpUploadMethod.FILE) ||
        (carpEndPoint.uploadMethod == CarpUploadMethod.BATCH_DATA_POINT)) {
      // make sure that files are not zipped if using batch upload
      assert(
          carpEndPoint.uploadMethod == CarpUploadMethod.BATCH_DATA_POINT
              ? carpEndPoint.zip == false
              : true,
          'Files uploaded to CARP must not be zipped.');

      // Create a [FileDataManager] and wrap it.
      fileDataManager = new FileDataManager();

      // merge the file data manager's events into this CARP data manager's event stream
      fileDataManager.events.listen((event) => addEvent(event));

      // listen to data manager events, but only those from the file manager and only closing events
      // on a close event, upload the file to CARP
      fileDataManager.events
          .where((event) => event.runtimeType == FileDataManagerEvent)
          .where((event) => event.type == FileDataManagerEventTypes.FILE_CLOSED)
          .listen((event) =>
              _uploadDatumFileToCarp((event as FileDataManagerEvent).path));

      // initialize the file data manager
      fileDataManager.initialize(dataEndPoint, deployment, data);
    }
    _initialized = true;
    await user; // This will trigger authentication to the CARP server
  }

  /// The currently signed in user.
  ///
  /// If a user is already autheticated to the [CarpService], then this account
  /// is used for uploading the data to CARP.
  ///
  /// If the user is not authenticated, this method will try to authenticate
  /// the user based on the configuration (uri, client_id, client_secret) and
  /// credentials (username and password) specified in [carpEndPoint].
  Future<CarpUser?> get user async {
    // check if the CARP webservice has already been configured and the user is logged in.
    if (!CarpService().authenticated) {
      info('$runtimeType - No user is authenticated. '
          'Trying to authenticate based on configuration and credentials specified in the carpEndPoint.');
      if (!CarpService().isConfigured) {
        CarpService().configure(CarpApp(
          studyDeploymentId: studyDeploymentId,
          name: carpEndPoint.name,
          uri: Uri.parse(carpEndPoint.uri.toString()),
          oauth: OAuthEndPoint(
              clientID: carpEndPoint.clientId.toString(),
              clientSecret: carpEndPoint.clientSecret.toString()),
        ));
      }
      await CarpService().authenticate(
        username: carpEndPoint.email.toString(),
        password: carpEndPoint.password.toString(),
      );
      info("CarpDataManager - signed in user: ${CarpService().currentUser}");
    }

    return CarpService().currentUser;
  }

  Future<void> onDataPoint(DataPoint dataPoint) => uploadData(dataPoint);

  Future<void> onDone() => close();

  /// Handle upload of data depending on the specified [CarpUploadMethod].
  Future<void> uploadData(DataPoint dataPoint) async {
    // Check if CARP authentication is ready before writing...
    if (!_initialized) {
      warning("Waiting for CARP to be initialized -- delaying for 10 sec...");
      return Future.delayed(
          const Duration(seconds: 10), () => uploadData(dataPoint));
    }

    CarpUser? _user = await user;
    if (_user == null) {
      warning('User is not authenticated - username: ${carpEndPoint.email}');
      return;
    } else {
      // first check if this is a [FileDatum] that has a separate file to be uploaded
      if (dataPoint.data is FileDatum) {
        FileDatum fileDatum = dataPoint.data as FileDatum;
        if (fileDatum.upload) _uploadFileToCarp(fileDatum);
      }

      // then upload the datum as specified in the upload method.
      switch (carpEndPoint.uploadMethod) {
        case CarpUploadMethod.DATA_POINT:
          info(
              'Uploading data point to CARP - ${dataPoint.carpHeader.dataFormat}');
          await CarpService().getDataPointReference().postDataPoint(dataPoint);
          break;
        case CarpUploadMethod.BATCH_DATA_POINT:
        case CarpUploadMethod.FILE:
          // In both cases, forward to [FileDataManager], which collects data
          // in a file before upload.
          await fileDataManager.write(dataPoint);
          break;
        case CarpUploadMethod.DOCUMENT:
          info(
              'Uploading data point document to CARP - ${dataPoint.carpHeader.dataFormat}');
          await CarpService()
              .collection('/${carpEndPoint.collection}')
              .document()
              .setData(
                  json.decode(json.encode(dataPoint)) as Map<String, dynamic>);
          return;
      }
    }
  }

  // This method upload a file of [Datum] data to CARP.
  // TODO - implement support for offline store-and-wait for later upload when online.
  Future _uploadDatumFileToCarp(String path) async {
    info("Datum json file upload to CARP started - path : '$path'");
    final File file = File(path);

    final String deviceID = DeviceInfo().deviceID.toString();
    final String? userID = (await user)!.email;

    switch (carpEndPoint.uploadMethod) {
      case CarpUploadMethod.BATCH_DATA_POINT:
        await CarpService().getDataPointReference().batchPostDataPoint(file);

        addEvent(CarpDataManagerEvent(
            CarpDataManagerEventTypes.file_uploaded,
            file.path,
            null,
            CarpService().getDataPointReference().dataEndpointUri));
        info("Batch upload to CARP finished");
        break;
      case CarpUploadMethod.FILE:
        final FileUploadTask uploadTask = CarpService()
            .getFileStorageReference()
            .upload(file, {'device_id': '$deviceID', 'user_id': '$userID'});

        // await the upload is successful
        CarpFileResponse response = await uploadTask.onComplete;
        int id = response.id;

        addEvent(CarpDataManagerEvent(CarpDataManagerEventTypes.file_uploaded,
            file.path, id, uploadTask.reference.fileEndpointUri));
        info("Datum json file upload to CARP finished - remote id: '$id' ");
        break;
      case CarpUploadMethod.DATA_POINT:
      case CarpUploadMethod.DOCUMENT:
        // do nothing -- no file to upload since data point has already been
        // uploaded (see uploadData method)
        break;
    }

    if (carpEndPoint.deleteWhenUploaded) {
      // delete the local file once uploaded
      file.delete();
      info("Locale Datum json file deleted - path: '${file.path}'.");
      addEvent(FileDataManagerEvent(
          FileDataManagerEventTypes.FILE_DELETED, file.path));
    }
  }

  // This method upload a file attachment to CARP, i.e. one that is referenced in a [FileDatum].
  Future _uploadFileToCarp(FileDatum datum) async {
    if (datum.path == null) {
      warning(
          '$runtimeType - No path to local FileDatum specified when trying to upload file.');
      return;
    }

    info("File attachment upload to CARP started - path : '${datum.path}'");
    final File file = File(datum.path!);

    if (!file.existsSync()) {
      warning('The file attachment is not found - skipping upload.');
      return;
    }

    final String deviceID = DeviceInfo().deviceID.toString();
    datum.metadata!['device_id'] = deviceID;
    datum.metadata!['study_deployment_id'] = studyDeploymentId;

    // start upload
    final FileUploadTask uploadTask =
        CarpService().getFileStorageReference().upload(file, datum.metadata);

    // await the upload is successful
    CarpFileResponse response = await uploadTask.onComplete;
    int id = response.id;

    addEvent(CarpDataManagerEvent(CarpDataManagerEventTypes.file_uploaded,
        file.path, id, uploadTask.reference.fileEndpointUri));
    info("File upload to CARP finished - remote id : $id ");

    // delete the local file once uploaded?
    if (carpEndPoint.deleteWhenUploaded) {
      file.delete();
      addEvent(FileDataManagerEvent(
          FileDataManagerEventTypes.FILE_DELETED, file.path));
    }
  }
}

class CarpDataManagerFactory implements DataManagerFactory {
  @override
  String get type => DataEndPointTypes.CARP;

  @override
  DataManager create() => CarpDataManager();
}

/// A status event for this CARP data manager.
/// See [CarpDataManagerEventTypes] for a list of possible event types.
class CarpDataManagerEvent extends DataManagerEvent {
  /// The full path and filename for the file on the device.
  String path;

  /// The ID of the file on the CARP server, if provided.
  /// `null` if not available from the server.
  int? id;

  /// The URI of the file on the CARP server.
  String fileEndpointUri;

  CarpDataManagerEvent(super.type, this.path, this.id, this.fileEndpointUri);

  String toString() =>
      'CarpDataManagerEvent - type: $type, path: $path, id: $id, fileEndpointUri: $fileEndpointUri';
}

/// An enumeration of file data manager event types
class CarpDataManagerEventTypes extends FileDataManagerEventTypes {
  static const String file_uploaded = 'file_uploaded';
}
