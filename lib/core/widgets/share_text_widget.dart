import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareTextWidget extends StatelessWidget {
  final String text;
  final String title;

  const ShareTextWidget({
    super.key,
    required this.text,
    required this.title,
  });

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks berhasil disalin ke clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareText(BuildContext context) {
    // Use share_plus if available, fallback to copy
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks disalin - silakan paste di aplikasi yang diinginkan'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: SelectableText(
          text,
          style: const TextStyle(fontSize: 14),
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _copyToClipboard(context),
          icon: const Icon(Icons.copy),
          label: const Text('Salin'),
        ),
        ElevatedButton.icon(
          onPressed: () => _shareText(context),
          icon: const Icon(Icons.share),
          label: const Text('Bagikan'),
        ),
      ],
    );
  }
}
