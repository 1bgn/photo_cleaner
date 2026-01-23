// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:google_mlkit_selfie_segmentation/google_mlkit_selfie_segmentation.dart'
    as _i254;
import 'package:image_picker/image_picker.dart' as _i183;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/editor/application/inpaint_service.dart' as _i193;
import '../../features/editor/application/media_save_service.dart' as _i646;
import '../../features/editor/data/inpaint_service_impl.dart' as _i879;
import '../../features/editor/data/media_save_service_impl.dart' as _i798;
import '../../features/editor/data/repository/media_repository_impl.dart'
    as _i816;
import '../../features/editor/domain/repository/media_repository.dart' as _i60;
import '../../features/editor/presentation/editor_controller.dart' as _i819;
import '../../features/gallery/data/local_gallery_service_impl.dart' as _i374;
import '../../features/gallery/domain/local_gallery_service.dart' as _i324;
import '../../features/gallery/presentation/gallery_controller.dart' as _i759;
import '../network/dio_factory.dart' as _i798;
import '../network/retrofit_clients.dart' as _i401;
import 'app_module.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    gh.factory<_i254.SelfieSegmenter>(
      () => registerModule.provideSelfieSegmenter(),
    );
    gh.lazySingleton<_i183.ImagePicker>(() => registerModule.imagePicker);
    gh.lazySingleton<_i798.DioFactory>(() => registerModule.dioFactory);
    gh.lazySingleton<_i646.MediaSaveService>(
      () => _i798.MediaSaveServiceImpl(),
    );
    gh.lazySingleton<_i401.CleanerInpaintClient>(
      () => registerModule.cleanerInpaintClient(gh<_i798.DioFactory>()),
    );
    gh.lazySingleton<_i324.LocalGalleryService>(
      () => _i374.LocalGalleryServiceImpl(),
    );
    gh.lazySingleton<_i60.MediaRepository>(
      () => _i816.MediaRepositoryImpl(gh<_i401.CleanerInpaintClient>()),
    );
    gh.lazySingleton<_i193.InpaintService>(
      () => _i879.InpaintServiceImpl(gh<_i60.MediaRepository>()),
    );
    gh.factory<_i759.GalleryController>(
      () => _i759.GalleryController(gh<_i324.LocalGalleryService>()),
    );
    gh.factory<_i819.EditorController>(
      () => _i819.EditorController(
        gh<_i183.ImagePicker>(),
        gh<_i193.InpaintService>(),
        gh<_i254.SelfieSegmenter>(),
        gh<_i646.MediaSaveService>(),
        gh<_i324.LocalGalleryService>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i460.RegisterModule {}
