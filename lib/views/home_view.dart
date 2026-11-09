import 'package:flutter/material.dart';
import 'catalog_view.dart';
import 'items_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int index = 0;
  bool itemsOpened = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: index,
      children: [
        const CatalogView(),
        itemsOpened ? const ItemsView() : const SizedBox.shrink(),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: index,
      onDestinationSelected: (value) => setState(() {
        index = value;
        if (value == 1) itemsOpened = true;
      }),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.catching_pokemon), label: '포켓몬'),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          label: '아이템',
        ),
      ],
    ),
  );
}
