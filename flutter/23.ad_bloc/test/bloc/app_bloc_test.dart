import 'package:ad_bloc/base.dart';
import 'package:ad_bloc/bloc.dart';
import 'package:ad_bloc/model.dart';
import 'package:ad_bloc/src/service/age_detector.dart';
import 'package:ad_bloc/src/service/face_detector.dart';
import 'package:ad_bloc/src/service/gender_detector.dart';
import 'package:ad_bloc/src/service/gps/debug_route_loader.dart';
import 'package:ad_bloc/src/service/movement_detector.dart';
import 'package:fake_async/fake_async.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import '../utils.dart';

main() {
  AppBloc appBloc;
  List<AppEvent> emittedEvents;

  MockAdRepository adRepository;

  StreamController<LatLng> latLng$Controller;
  MockGpsController gpsController;
  MovementDetector movementDetector;

  StreamController<bool> isAllowed$Controller;
  MockPermissionController permissionController;

  StreamController<bool> isStrong$Controller;
  MockPowerProvider powerProvider;

  group('AppBloc', () {
    setUp(() {
      adRepository = MockAdRepository();

      latLng$Controller = StreamController();
      gpsController = MockGpsController(latLng$Controller.stream);
      movementDetector = MovementDetectorImpl(gpsController.latLng$);

      isAllowed$Controller = StreamController.broadcast();
      permissionController =
          MockPermissionController(isAllowed$Controller.stream);

      isStrong$Controller = StreamController.broadcast();
      powerProvider = MockPowerProvider(isStrong$Controller.stream);

      appBloc = AppBloc(
        AppState.init(),
        adRepository: adRepository,
        gpsController: gpsController,
        permissionController: permissionController,
        powerProvider: powerProvider,
        movementDetector: movementDetector,
      );

      emittedEvents = [];

      appBloc.event$.listen(emittedEvents.add);
    });

    tearDown(() {
      resetMockitoState();
      latLng$Controller.close();
      isAllowed$Controller.close();
      isStrong$Controller.close();
      appBloc.close();
    });

    _permit(bool isAllowed) {
      isAllowed$Controller.add(isAllowed);
    }

    _powerSupply(bool isStrong) {
      isStrong$Controller.add(isStrong);
    }

    _locate(LatLng latLng) {
      latLng$Controller.add(latLng);
    }

    _fetchAds(Iterable<Ad> ads) {
      adRepository.ads = ads;
    }

    test('stopped when permission is denied or power is weak', () async {
      appBloc.add(const Initialized());
      await flushMicrotasks();

      expect(permissionController.startCalled, 1);
      expect(powerProvider.startCalled, 1);

      _permit(false);
      _powerSupply(true);
      await flushMicrotasks();

      expect(emittedEvents, [
        const Initialized(),
        const Permitted(false),
        const PowerSupplied(true),
      ]);
      expect(
        appBloc.state,
        AppState.init().copyWith(
          isPermissionAllowed: false,
          isPowerStrong: true,
          isStarted: false,
        ),
      );

      _powerSupply(false);
      _permit(true);
      await flushMicrotasks();

      expect(emittedEvents.skip(3), [
        const PowerSupplied(false),
        const Permitted(true),
      ]);
      expect(
        appBloc.state,
        AppState.init().copyWith(
          isPermissionAllowed: true,
          isPowerStrong: false,
          isStarted: false,
        ),
      );
    });

    test('started', () async {
      appBloc.add(const Initialized());
      await flushMicrotasks();

      expect(permissionController.startCalled, 1);
      expect(powerProvider.startCalled, 1);

      _permit(true);
      _powerSupply(true);
      await flushMicrotasks();

      expect(emittedEvents, [
        const Initialized(),
        const Permitted(true),
        const PowerSupplied(true),
      ]);
      expect(
        appBloc.state,
        AppState.init().copyWith(
          isPermissionAllowed: true,
          isPowerStrong: true,
          isStarted: true,
          isTrackingLocation: true,
        ),
      );
    });

    test('fetch new ads when location is changed', () async {
      // App started
      appBloc
        ..add(const Initialized())
        ..add(const Permitted(true))
        ..add(const PowerSupplied(true));

      await flushMicrotasks();

      expect(gpsController.startCalled, 1);

      _locate(const LatLng(53.817198, -2.417717));
      await flushMicrotasks();

      expect(adRepository.changeLocationCalledArgs, [
        const LatLng(53.817198, -2.417717),
      ]);

      _fetchAds(sampleAds);
      await flushMicrotasks();

      expect(emittedEvents.skip(3), [
        const Located(const LatLng(53.817198, -2.417717)),
        ReadyAdsChanged(sampleAds),
      ]);
      expect(
        appBloc.state,
        AppState.init().copyWith(
          isPermissionAllowed: true,
          isPowerStrong: true,
          isStarted: true,
          isTrackingLocation: true,
          isFetchingAds: true,
          latLng: const LatLng(53.817198, -2.417717),
          newAds: [],
          readyAds: sampleAds,
        ),
      );
    });
  });

  group('AppBloc', () {
    test('detect movement when location is changing', () async {
      final debugRoutes = await DebugRouteLoader.singleton().load();
      final debugRoute = debugRoutes[0];

      fakeAsync((async) {
        final gpsController = MockGpsController(debugRoute.latLng$);
        final movementDetector = MovementDetectorImpl(gpsController.latLng$);

        appBloc = AppBloc(
          AppState.init(),
          gpsController: gpsController,
          movementDetector: movementDetector,
        );

        emittedEvents = [];
        appBloc.event$.listen(emittedEvents.add);

        appBloc
          ..add(const Initialized())
          ..add(const Permitted(true))
          ..add(const PowerSupplied(true));

        async.elapse(Duration(seconds: 11));

        expect(emittedEvents.skip(3), [
          const Located(const LatLng(16.0703366, 108.231204)),
          const Located(const LatLng(16.0707824, 108.2310186)),
          const Located(const LatLng(16.0709385, 108.230972)),
          const Located(const LatLng(16.0710511, 108.2309365)),
          const Located(const LatLng(16.0710983, 108.2309286)),
          const Moved(true),
          const Located(const LatLng(16.0710929, 108.2309424)),
          const Located(const LatLng(16.0710693, 108.2309624)),
          const Located(const LatLng(16.0710323, 108.2309851)),
        ]);

        expect(
          appBloc.state,
          AppState.init().copyWith(
            isPermissionAllowed: true,
            isPowerStrong: true,
            isStarted: true,
            isTrackingLocation: true,
            isMoving: true,
            isFetchingAds: true,
            gpsOptions: const GpsOptions(accuracy: GpsAccuracy.high),
            latLng: const LatLng(16.0710323, 108.2309851),
          ),
        );
      });
    });
  });

  group('AppBloc', () {
    test('detect no faces while moving', () async {
      fakeAsync((async) {
        final cameraController = MockCameraController();
        appBloc = AppBloc(
          AppState.init(),
          cameraController: cameraController,
          faceDetector: FakeFaceDetector(),
          genderDetector: FakeGenderDetector(),
          ageDetector: FakeAgeDetector(),
        );

        emittedEvents = [];
        appBloc.event$.listen(emittedEvents.add);

        appBloc
          ..add(const Initialized())
          ..add(const Permitted(true))
          ..add(const PowerSupplied(true))
          ..add(const Located(const LatLng(16.0710693, 108.2309624)))
          ..add(const Moved(true));

        const fakePhoto = Photo('camera-sample_4.png');
        cameraController.photo = fakePhoto;

        async.elapse(Duration(seconds: 3));

        expect(cameraController.captureCalled, 1);
        expect(emittedEvents.skip(5), const [
          PhotoCaptured(fakePhoto),
          DetectedNoFace(),
        ]);

        expect(
          appBloc.state,
          AppState.init().copyWith(
            isPermissionAllowed: true,
            isPowerStrong: true,
            isStarted: true,
            isTrackingLocation: true,
            isMoving: true,
            isFetchingAds: true,
            gpsOptions: const GpsOptions(accuracy: GpsAccuracy.high),
            latLng: const LatLng(16.0710693, 108.2309624),
            capturedPhoto: fakePhoto,
          ),
        );
      });
    });

    test('detect passenger info when moving', () async {
      fakeAsync((async) {
        final cameraController = MockCameraController();
        appBloc = AppBloc(
          AppState.init(),
          cameraController: cameraController,
          faceDetector: FakeFaceDetector(),
          genderDetector: FakeGenderDetector(),
          ageDetector: FakeAgeDetector(),
        );

        emittedEvents = [];
        appBloc.event$.listen(emittedEvents.add);

        appBloc
          ..add(const Initialized())
          ..add(const Permitted(true))
          ..add(const PowerSupplied(true))
          ..add(const Located(const LatLng(16.0710693, 108.2309624)))
          ..add(const Moved(true));

        const fakePhoto = Photo('camera-sample_1.png');
        cameraController.photo = fakePhoto;

        async.elapse(Duration(seconds: 3));

        expect(cameraController.captureCalled, 1);
        expect(emittedEvents.skip(5), const [
          PhotoCaptured(fakePhoto),
          FacesDetected([
            Face('fd32f', Photo('face-sample-female-26_30.png')),
            Face('5eeb5', Photo('face-sample-male-18_25.png')),
          ]),
          GendersDetected([PassengerGender.female]),
          AgeRangesDetected([PassengerAgeRange(26, 30)]),
          GendersDetected([PassengerGender.male]),
          AgeRangesDetected([PassengerAgeRange(18, 25)]),
        ]);

        expect(
          appBloc.state,
          AppState.init().copyWith(
            isPermissionAllowed: true,
            isPowerStrong: true,
            isStarted: true,
            isTrackingLocation: true,
            isMoving: true,
            isFetchingAds: true,
            gpsOptions: const GpsOptions(accuracy: GpsAccuracy.high),
            latLng: const LatLng(16.0710693, 108.2309624),
            capturedPhoto: fakePhoto,
            genders: const [
              PassengerGender.female,
              PassengerGender.male,
            ],
            ageRanges: const [
              PassengerAgeRange(26, 30),
              PassengerAgeRange(18, 25),
            ],
            faces: const [
              Face('fd32f', Photo('face-sample-female-26_30.png')),
              Face('5eeb5', Photo('face-sample-male-18_25.png')),
            ],
            trip: Trip.onTrip(const [
              Face('fd32f', Photo('face-sample-female-26_30.png')),
              Face('5eeb5', Photo('face-sample-male-18_25.png')),
            ]),
          ),
        );
      });
    });
  });
}
