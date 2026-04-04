import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          color: const Color(0xFFF5F5F5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 14, color: Color(0xFF888888)),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    style:
                        const TextStyle(fontSize: 11, color: Color(0xFF888888)),
                    children: [
                      const TextSpan(
                          text:
                              'For reference only. Not medical advice. Questions? '),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: GestureDetector(
                          onTap: _launchEmail,
                          child: const Text(
                            'support@supplecut.com',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
      ],
    );
  }

  static Future<void> _launchEmail() async {
    final uri = Uri.parse('mailto:support@supplecut.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
