import 'package:material_ui/material_ui.dart';

class SearchField extends StatefulWidget {
  const SearchField({super.key, required this.hint, required this.onChanged, this.onSubmitted});

  final String hint;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          fillColor: Colors.white,
          hintText: widget.hint,
          suffixIcon: IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () => widget.onSubmitted?.call(_controller.text),
          ),
        ),
      );
}