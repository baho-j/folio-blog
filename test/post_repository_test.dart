import 'package:flutter_test/flutter_test.dart';

import 'support/in_memory_post_repository.dart';
import 'support/repository_contract.dart';

void main() {
  group('InMemoryPostRepository', () {
    repositoryContract(() async {
      final repository = InMemoryPostRepository();
      return ContractSubject(
        repository: repository,
        newPhoto: () async => 'picked.jpg',
        hasImage: (name) async => repository.imageNames.contains(name),
      );
    });
  });
}
