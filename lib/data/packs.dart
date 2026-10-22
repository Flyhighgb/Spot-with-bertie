import 'dart:ui';

import 'items.dart';
import 'models.dart';

const airportPack = SpotPack(
  id: 'airport',
  name: 'Airport',
  place: 'airport',
  icon: 'assets/images/tower.webp',
  items: airportItems,
  mapPosition: Offset(0.30, 0.80),
  free: true,
);

const parkPack = SpotPack(
  id: 'park',
  name: 'Park',
  place: 'park',
  icon: 'assets/images/p_tree.webp',
  items: parkItems,
  mapPosition: Offset(0.68, 0.58),
  blurb: '24 things to spot at the park: squirrels, conkers, kites, ducks and more.',
);

const trainPack = SpotPack(
  id: 'train',
  name: 'Train station',
  place: 'station',
  icon: 'assets/images/t_steam.webp',
  items: trainItems,
  mapPosition: Offset(0.32, 0.36),
  blurb: '24 things to spot at the station: signals, steam trains, high-speed trains and more.',
);

const seasidePack = SpotPack(
  id: 'seaside',
  name: 'Seaside',
  place: 'seaside',
  icon: '',
  items: [],
  mapPosition: Offset(0.68, 0.14),
  comingSoon: true,
);

/// Every pack in map order, from the first island to the last.
const allPacks = [airportPack, parkPack, trainPack, seasidePack];

/// Packs that a child can buy and play.
List<SpotPack> get playablePacks => allPacks.where((p) => !p.comingSoon).toList();

SpotPack packById(String id) => allPacks.firstWhere((p) => p.id == id);

const familyPassPrice = '£5.99';
