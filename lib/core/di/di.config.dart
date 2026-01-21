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

import '../../features/editor/application/usecases/pick_image_uc.dart' as _i726;
import '../../features/editor/data/file_picker_adapter.dart' as _i842;
import '../../features/editor/domain/image_picker_port.dart' as _i829;
import '../../features/editor/presentation/editor_controller.dart' as _i819;
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
    gh.factory<_i819.BackgroundBlurController>(
      () => _i819.BackgroundBlurController(
        gh<_i183.ImagePicker>(),
        gh<_i254.SelfieSegmenter>(),
      ),
    );
    gh.lazySingleton<_i829.ImagePickerPort>(() => _i842.FilePickerAdapter());
    gh.factory<_i726.PickImageUc>(
      () => _i726.PickImageUc(gh<_i829.ImagePickerPort>()),
    );
    return this;
  }
}

class _$RegisterModule extends _i460.RegisterModule {}
