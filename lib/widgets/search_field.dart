import 'dart:async';
import 'package:flutter/material.dart';

/// Debounced search field shared by Customer/Item/Order search bars, so
/// the DB isn't hit on every single keystroke.
class SearchField extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onChanged;
  final Duration debounce;

  const SearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.debounce = const Duration(milliseconds: 300),
  });

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(value));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                widget.onChanged('');
              },
            );
          },
        ),
      ),
    );
  }
}
