import '../services/persistence_service.dart';
import 'package:flutter/foundation.dart';

class StageResultViewModel extends ChangeNotifier {
	final PersistenceService persistenceService;
	StageResultViewModel({required this.persistenceService});
}
