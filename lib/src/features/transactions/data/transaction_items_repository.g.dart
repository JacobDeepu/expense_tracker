// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_items_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(transactionItemsRepository)
final transactionItemsRepositoryProvider =
    TransactionItemsRepositoryProvider._();

final class TransactionItemsRepositoryProvider
    extends
        $FunctionalProvider<
          TransactionItemsRepository,
          TransactionItemsRepository,
          TransactionItemsRepository
        >
    with $Provider<TransactionItemsRepository> {
  TransactionItemsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionItemsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionItemsRepositoryHash();

  @$internal
  @override
  $ProviderElement<TransactionItemsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransactionItemsRepository create(Ref ref) {
    return transactionItemsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionItemsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionItemsRepository>(value),
    );
  }
}

String _$transactionItemsRepositoryHash() =>
    r'236d4d49ab80814aa7ab25c76c75f7a6b89ecfa9';
