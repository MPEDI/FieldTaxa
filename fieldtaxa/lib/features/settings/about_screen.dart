import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appChrome,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 8),
              Icon(Icons.arrow_back_ios_rounded,
                  size: 16, color: context.appPrimary),
              Text('Settings',
                  style: jakartaStyle(14, context.appPrimary,
                      weight: FontWeight.w700)),
            ],
          ),
        ),
        leadingWidth: 90,
        title: Text('About FieldTaxa',
            style: newsreaderStyle(17, context.appFg,
                weight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
        children: [
          // Center branding
          Center(
            child: Column(
              children: [
                Image.asset(
                  'assets/MPeditechLogo.png',
                  height: 52,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                Text('FieldTaxa',
                    style: newsreaderStyle(30, context.appFg,
                        weight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text(
                  'FieldTaxa lets you capture, classify, and track field observations of fauna, flora, and other taxa.',
                  textAlign: TextAlign.center,
                  style: jakartaStyle(13, context.appMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Info card
          Container(
            decoration: BoxDecoration(
              color: context.appSurface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: context.appLine),
            ),
            child: Column(
              children: [
                _InfoRow(label: 'Version', value: '1.0.0'),
                Divider(height: 1, color: context.appLine),
                _InfoRow(label: 'Build', value: '1'),
                Divider(height: 1, color: context.appLine),
                _InfoRow(label: 'Release date', value: 'June 2026'),
                Divider(height: 1, color: context.appLine),
                _InfoRow(label: 'Developer', value: 'MPediTech'),
                Divider(height: 1, color: context.appLine),
                _WebsiteRow(url: 'https://www.mpeditech.com', label: 'www.mpeditech.com'),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Footer
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco_rounded,
                    color: context.appPrimary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'FieldTaxa · © 2026 MPediTech',
                  style: jakartaStyle(12, context.appMuted,
                      weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(label,
              style: jakartaStyle(13, context.appMuted,
                  weight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: jakartaStyle(13, context.appFg,
                  weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _WebsiteRow extends StatelessWidget {
  final String url;
  final String label;
  const _WebsiteRow({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Text('Website',
                style: jakartaStyle(13, context.appMuted,
                    weight: FontWeight.w500)),
            const Spacer(),
            Text(label,
                style: jakartaStyle(13, context.appPrimary,
                    weight: FontWeight.w600)),
            const SizedBox(width: 4),
            Icon(Icons.open_in_new_rounded,
                size: 13, color: context.appPrimary),
          ],
        ),
      ),
    );
  }
}
