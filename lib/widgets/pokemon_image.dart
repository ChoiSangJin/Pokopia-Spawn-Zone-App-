import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/pokemon.dart';

class PokemonImage extends StatelessWidget {
  const PokemonImage({super.key, required this.pokemon});
  final Pokemon pokemon;
  @override
  Widget build(BuildContext context) {
    final fallback = Icon(
      Icons.catching_pokemon,
      size: 64,
      color: Theme.of(context).colorScheme.primary,
    );
    return Hero(
      tag: pokemon.id,
      child: Semantics(
        label: '${pokemon.name} 이미지',
        child: pokemon.imageUrl == null
            ? fallback
            : CachedNetworkImage(
                imageUrl: pokemon.imageUrl!,
                fit: BoxFit.contain,
                placeholder: (_, url) => const Center(
                  child: SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, url, error) => fallback,
              ),
      ),
    );
  }
}
