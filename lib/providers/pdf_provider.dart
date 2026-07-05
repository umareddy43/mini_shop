import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pdf/pdf_service.dart';

final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());
