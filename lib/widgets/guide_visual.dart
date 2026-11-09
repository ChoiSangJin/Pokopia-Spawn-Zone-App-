import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/visual_fact.dart';
import '../services/translations.dart';

class GuideImage extends StatelessWidget {
  const GuideImage({
    super.key,
    required this.url,
    required this.label,
    this.size = 44,
    this.fallback = Icons.image_outlined,
  });
  final String? url;
  final String label;
  final double size;
  final IconData fallback;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    image: true,
    child: SizedBox.square(
      dimension: size,
      child: url == null || Uri.tryParse(url!)?.scheme != 'https'
          ? Icon(
              fallback,
              size: size * .65,
              color: Theme.of(context).colorScheme.primary,
            )
          : CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.contain,
              placeholder: (_, value) => Center(
                child: SizedBox.square(
                  dimension: size.clamp(12, 24),
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, value, error) => Icon(
                fallback,
                size: size * .65,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
    ),
  );
}

class VisualCapsules extends StatelessWidget {
  const VisualCapsules({
    super.key,
    required this.facts,
    required this.section,
    required this.translations,
    this.fallback = Icons.auto_awesome,
  });
  final List<VisualFact> facts;
  final String section;
  final Translations translations;
  final IconData fallback;
  @override
  Widget build(BuildContext context) => facts.isEmpty
      ? const Text('미제공')
      : Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final fact in facts)
              Chip(
                avatar: GuideImage(
                  url: fact.iconUrl,
                  label: fact.name,
                  size: 30,
                  fallback: fallback,
                ),
                label: Text(translations.translate(section, fact.name)),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
          ],
        );
}
