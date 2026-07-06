import 'package:flutter_test/flutter_test.dart';
import 'package:goodwill_circle/features/requests/request_repository.dart';

void main() {
  group('request repository join and contact logic', () {
    test('counts helper and helpie joins from actual join rows', () {
      final joins = [
        {'join_role': 'helper'},
        {'join_role': 'helper'},
        {'join_role': 'helpee'},
      ];

      expect(RequestRepository.countJoinRole(joins, 'helper'), 2);
      expect(RequestRepository.countJoinRole(joins, 'helpee'), 1);
    });

    test('deduplicates contact rows for the same participant', () {
      final contacts = [
        {
          'participant_id': 'user-1',
          'name': 'A',
          'role': 'helpee',
          'status': 'accepted',
        },
        {
          'participant_id': 'user-1',
          'name': 'A',
          'role': 'helper',
          'status': 'accepted',
        },
        {
          'participant_id': 'user-2',
          'name': 'B',
          'role': 'helper',
          'status': 'completed',
        },
      ];

      final deduped = RequestRepository.deduplicateContacts(contacts);

      expect(deduped, hasLength(2));
      expect(
        deduped.where((c) => c['participant_id'] == 'user-1'),
        hasLength(1),
      );
      expect(
        deduped.firstWhere((c) => c['participant_id'] == 'user-1')['role'],
        'helper',
      );
    });
  });
}
