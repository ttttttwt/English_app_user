import 'package:do_an_test/common/constant/const_class.dart';

MediaType getMediaType(String type) {
  switch (type) {
    case 'video':
      return MediaType.video;
    case 'image':
      return MediaType.image;
    default:
      return MediaType.image;
  }
}