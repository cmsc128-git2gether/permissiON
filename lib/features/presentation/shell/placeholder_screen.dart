import 'package:material_ui/material_ui.dart';

/// Temporary stand-in until the real screen exists.
/// key is used in tests to identify the screen.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, this.showAppBar = true});

  final String title;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    //both the body and the app bar use the title, so we can just define it once
    final body = Center(
      child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
    );
    if (showAppBar){
      return body;
     } //if no app bar, just return the body
    return Scaffold(appBar: AppBar(title: Text(title)), body: body);
  }
}