import 'package:mockito/annotations.dart';
import 'package:cafe_bda/services/google_sheets_service.dart';
import 'package:cafe_bda/repositories/cafe_repository.dart';
import 'package:cafe_bda/providers/cafe_data_provider.dart';

@GenerateMocks([GoogleSheetsService, CafeRepository, CafeDataProvider])
void main() {}
