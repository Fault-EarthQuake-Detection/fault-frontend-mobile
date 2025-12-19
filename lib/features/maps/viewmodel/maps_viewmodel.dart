// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_riverpod/legacy.dart';
// import '../../detection/data/detection_model.dart';
// import '../data/maps_repository.dart';
//
// final mapsControllerProvider = StateNotifierProvider<MapsController, AsyncValue<List<DetectionModel>>>((ref) {
//   return MapsController(MapsRepository());
// });
//
// class MapsController extends StateNotifier<AsyncValue<List<DetectionModel>>> {
//   final MapsRepository _repo;
//
//   MapsController(this._repo) : super(const AsyncValue.loading()) {
//     fetchDetections();
//   }
//
//   Future<void> fetchDetections() async {
//     try {
//       state = const AsyncValue.loading();
//       final data = await _repo.getAllDetections();
//       state = AsyncValue.data(data);
//     } catch (e, stack) {
//       state = AsyncValue.error(e, stack);
//     }
//   }
// }