/*
 * Copyright 2021 Copenhagen Center for Health Technology (CACHET) at the
 * Technical University of Denmark (DTU).
 * Use of this source code is governed by a MIT-style license that can be
 * found in the LICENSE file.
 */

part of mobile_sensing_app;

/// This class implements the sensing layer.
///
/// Call [initialize] to setup a deployment, either locally or using a CARP
/// deployment. Once initialized, the runtime [controller] can be used to
/// control the study execution (e.g., resume, pause, stop).
class Sensing {
  static final Sensing _instance = Sensing._();
  StudyDeploymentStatus? _status;
  SmartphoneDeploymentController? _controller;

  DeploymentService? deploymentService;
  SmartPhoneClientManager? client;
  Study? study;

  /// The deployment running on this phone.
  // SmartphoneDeployment? get deployment => _controller?.deployment;

  /// Get the latest status of the study deployment.
  StudyDeploymentStatus? get status => _status;

  /// The role name of this device in the deployed study
  String? get deviceRolename => "pixel device 1";

  /// The study runtime controller for this deployment
  SmartphoneDeploymentController? get controller => _controller;

  /// the list of running - i.e. used - probes in this study.
  List<Probe> get runningProbes =>
      (_controller != null) ? _controller!.executor!.probes : [];

  /// The list of available devices.
  List<DeviceManager>? get availableDevices =>
      (client != null) ? client!.deviceController.devices.values.toList() : [];

  /// The singleton sensing instance
  factory Sensing() => _instance;

  Sensing._() {
    CarpMobileSensing();

    // Create and register external sampling packages
    SamplingPackageRegistry().register(ConnectivitySamplingPackage());
    SamplingPackageRegistry().register(ContextSamplingPackage());
    SamplingPackageRegistry().register(MediaSamplingPackage());
    // SamplingPackageRegistry().register(CommunicationSamplingPackage());
    SamplingPackageRegistry().register(AppsSamplingPackage());
    SamplingPackageRegistry().register(PolarSamplingPackage());
    SamplingPackageRegistry().register(ESenseSamplingPackage());
  }

  /// Initialize and set up sensing.
  Future<void> initialize() async {
    info('Initializing $runtimeType - mode: ${bloc.deploymentMode}');

    switch (bloc.deploymentMode) {
      case DeploymentMode.LOCAL:
        // use the local, phone-based deployment service
        deploymentService = SmartphoneDeploymentService();

        // get the protocol from the local study protocol manager
        // note that the study id is not used
        StudyProtocol protocol =
            await LocalStudyProtocolManager().getStudyProtocol('');

        // deploy this protocol using the on-phone deployment service
        // reuse the study deployment id, if this is stored on the phone
        _status = await SmartphoneDeploymentService().createStudyDeployment(
          protocol,
          bloc._studyDeploymentId as List<ParticipantInvitation>,
        );

        // save the correct deployment id on the phone for later use
        bloc.studyDeploymentId = _status!.studyDeploymentId;

        break;
      case DeploymentMode.CARP_PRODUCTION:
      case DeploymentMode.CARP_STAGING:

        // use the CARP deployment service that knows how to download a
        // custom protocol
        // deploymentService = CustomProtocolDeploymentService();
        //
        // // get the study deployment status based on the studyDeploymentId
        // if (bloc.studyDeploymentId != null) {
        //   _status = await CustomProtocolDeploymentService()
        //       .getStudyDeploymentStatus(bloc.studyDeploymentId!);
        // } else
        {
          warning(
              '$runtimeType - no study deployment ID has been specified....?');
        }

        break;
    }

    // Register the CARP data manager for uploading data back to CARP.
    // This is needed in both LOCAL and CARP deployments, since a local study
    // protocol may still upload to CARP
    DataManagerRegistry().register(CarpDataManagerFactory());

    // Create and configure a client manager for this phone
    client = SmartPhoneClientManager();

    await client?.configure(
      deploymentService: deploymentService,
      deviceController: DeviceController(),
    );

    // Define the study and add it to the client.
    await client?.addStudy(bloc._studyDeploymentId!, deviceRolename!);

    // Get the study controller and try to deploy the study.
    //
    // Note that if the study has already been deployed on this phone
    // it has been cached locally in a file and the local cache will
    // be used pr. default.
    // If not deployed before (i.e., cached) the study deployment will be
    // fetched from the deployment service.
    study = Study(
      bloc.studyDeploymentId!,
      deviceRolename!,
    );
    _controller = client?.getStudyRuntime(study!);
    await controller?.tryDeployment(useCached: bloc.useCachedStudyDeployment);

    // Configure the controller
    await controller?.configure();

    // Start samplling
    controller?.start(bloc.resumeSensingOnStartup);
    // Listening on the data stream and print them as json to the debug console
    controller?.measurements.listen((event)  => print(toJsonString(event)));

    info('$runtimeType initialized');
  }
}
