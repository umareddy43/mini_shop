import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/item.dart';
import '../repositories/item_repository.dart';
import 'repository_providers.dart';

class ItemListState {
  final List<Item> items;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  const ItemListState({
    this.items = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  ItemListState copyWith({
    List<Item>? items,
    String? searchQuery,
    bool? isLoading,
    String? error,
  }) {
    return ItemListState(
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ItemListNotifier extends StateNotifier<ItemListState> {
  final ItemRepository _repository;

  ItemListNotifier(this._repository) : super(const ItemListState()) {
    loadItems();
  }

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Always sorted by name per spec ("Sort by Name").
      final items = await _repository.getAllItems(
        searchQuery: state.searchQuery,
      );
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadItems();
  }

  Future<void> addItem({
    required String name,
    required double price,
    required String unit,
    bool available = true,
  }) async {
    final trimmedName = name.trim();
    final exists = await _repository.nameExists(trimmedName);
    if (exists) {
      throw StateError('An item named "$trimmedName" already exists');
    }
    final item = Item(
      name: trimmedName,
      price: price,
      unit: unit,
      available: available,
    );
    await _repository.insertItem(item);
    await loadItems();
  }

  Future<void> updateItem(Item item) async {
    final exists =
        await _repository.nameExists(item.name.trim(), excludeId: item.id);
    if (exists) {
      throw StateError('An item named "${item.name}" already exists');
    }
    await _repository.updateItem(item);
    await loadItems();
  }

  Future<void> deleteItem(int id) async {
    await _repository.deleteItem(id);
    await loadItems();
  }

  Future<void> toggleAvailability(Item item) async {
    await _repository.updateItem(item.copyWith(available: !item.available));
    await loadItems();
  }
}

final itemListProvider =
    StateNotifierProvider<ItemListNotifier, ItemListState>((ref) {
  final repository = ref.watch(itemRepositoryProvider);
  return ItemListNotifier(repository);
});

/// Only-available items, used by the Create Order > Select Items step so
/// unavailable stock never accidentally gets billed.
final availableItemsProvider = FutureProvider.autoDispose<List<Item>>((ref) async {
  // Rebuild whenever the main item list changes.
  ref.watch(itemListProvider);
  final repository = ref.watch(itemRepositoryProvider);
  return repository.getAllItems(onlyAvailable: true);
});
