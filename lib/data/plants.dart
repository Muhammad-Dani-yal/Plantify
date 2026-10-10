import 'package:flutter/material.dart';
part 'catalogue.g.dart';

class Plant {
  const Plant(
      {required this.id,
      required this.name,
      required this.botanical,
      required this.image,
      required this.description,
      required this.environment,
      required this.light,
      required this.water,
      required this.waterDays,
      required this.temperature,
      required this.difficulty,
      required this.soil,
      required this.tip,
      required this.category,
      required this.color,
      this.imageCredit = '',
      this.imageSource = ''});

  final String id,
      name,
      botanical,
      image,
      description,
      environment,
      light,
      water;
  final String temperature, difficulty, soil, tip, category;
  final int waterDays;
  final Color color;
  final String imageCredit, imageSource;

  String get imagePath => image.startsWith('assets/') || image.isEmpty
      ? image
      : 'assets/botanical/$image.png';
}

const featuredPlants = <Plant>[
  Plant(
      id: 'monstera',
      name: 'Monstera',
      botanical: 'Monstera deliciosa',
      image: 'monstera',
      category: 'Tropical',
      environment: 'Indoor',
      description:
          'A little piece of the jungle, at home. Its sculptural, split leaves bring a lush, architectural feel to any bright corner. Give it room to grow and a support to climb.',
      light: 'Indirect',
      water: 'Moderate',
      waterDays: 7,
      temperature: '18–24°C',
      difficulty: 'Easy',
      soil: 'Loose, well-draining potting mix with bark and perlite.',
      tip:
          'Check the top layer of soil before watering. Wipe leaves with a damp cloth and keep away from harsh midday sun.',
      color: Color(0xFFE9EEDC)),
  Plant(
      id: 'snake',
      name: 'Snake plant',
      botanical: 'Dracaena trifasciata',
      image: 'snake-plant',
      category: 'Easy care',
      environment: 'Indoor',
      description:
          'Clean lines, beautiful patterns, very little fuss. This resilient plant is a lovely first companion for a busy home, with upright leaves that make a quiet statement.',
      light: 'Low light',
      water: 'Low',
      waterDays: 21,
      temperature: '18–27°C',
      difficulty: 'Easy',
      soil: 'Free-draining cactus or succulent potting mix.',
      tip:
          'Let the compost dry thoroughly between waterings. Less water is usually better, particularly in winter.',
      color: Color(0xFFF0EDDE)),
  Plant(
      id: 'pothos',
      name: 'Golden pothos',
      botanical: 'Epipremnum aureum',
      image: 'pothos',
      category: 'Trailing',
      environment: 'Indoor',
      description:
          'Let it trail from a shelf or climb toward the light. Heart-shaped leaves, brushed with gold, make this adaptable vine a warm addition to your indoor jungle.',
      light: 'Indirect',
      water: 'Moderate',
      waterDays: 10,
      temperature: '18–24°C',
      difficulty: 'Easy',
      soil: 'Well-draining houseplant compost with added perlite.',
      tip:
          'Rotate the pot for even growth. Check the top few centimetres of compost before watering and trim long vines for a fuller plant.',
      color: Color(0xFFE7ECDC)),
  Plant(
      id: 'peperomia',
      name: 'Baby rubber plant',
      botanical: 'Peperomia obtusifolia',
      image: 'peperomia',
      category: 'Compact',
      environment: 'Indoor',
      description:
          'Small space, big personality. Its rounded, glossy leaves store moisture, making this compact plant a forgiving companion for a desk or bright windowsill.',
      light: 'Indirect',
      water: 'Low',
      waterDays: 14,
      temperature: '18–30°C',
      difficulty: 'Easy',
      soil: 'Light houseplant compost with good drainage.',
      tip:
          'Allow the top few centimetres of compost to dry. Never leave the pot sitting in water; peperomia roots dislike staying wet.',
      color: Color(0xFFEDE9DF)),
  Plant(
      id: 'watermelon',
      name: 'Watermelon peperomia',
      botanical: 'Peperomia argyreia',
      image: 'watermelon',
      category: 'Compact',
      environment: 'Indoor',
      description:
          'A living collection of silver and green stripes. Its distinctive leaves and delicate red stems add a playful detail to a bright, softly lit shelf.',
      light: 'Indirect',
      water: 'Moderate',
      waterDays: 10,
      temperature: '18–30°C',
      difficulty: 'Moderate',
      soil: 'Airy, free-draining houseplant potting mix.',
      tip:
          'Avoid direct sun on the patterned leaves. Let the surface of the soil dry and water the compost rather than the foliage.',
      color: Color(0xFFE4EDE6)),
  Plant(
      id: 'lavender',
      name: 'English lavender',
      botanical: 'Lavandula angustifolia',
      image: 'lavender',
      category: 'Outdoor',
      environment: 'Outdoor',
      description:
          'Bring a little calm to a sunny balcony. Silvery foliage and fragrant violet blooms make lavender a beautiful outdoor plant that welcomes pollinators.',
      light: 'Full sun',
      water: 'Low',
      waterDays: 14,
      temperature: 'Sunny outdoors',
      difficulty: 'Moderate',
      soil: 'Gritty, well-drained compost. Avoid heavy, waterlogged soil.',
      tip:
          'Choose a sunny, airy spot. Water container plants when needed, allow excess water to drain, and trim after flowering without cutting into old wood.',
      color: Color(0xFFEDE7F0)),
];

final plants = <Plant>[...featuredPlants, ...extraPlants];
Plant plantById(String id) => plants.firstWhere((plant) => plant.id == id);

class PlantFilter {
  const PlantFilter(
      {this.environment = 'All',
      this.light = 'All',
      this.water = 'All',
      this.difficulty = 'All',
      this.category = 'All'});
  final String environment, light, water, difficulty;
  final String category;
  int get activeCount => [environment, light, water, difficulty, category]
      .where((v) => v != 'All')
      .length;
  bool matches(Plant plant, String query) {
    final text =
        '${plant.name} ${plant.botanical} ${plant.category} ${plant.environment} ${plant.light} ${plant.water} ${plant.difficulty}'
            .toLowerCase();
    return query
            .trim()
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .every(text.contains) &&
        (category == 'All' || plant.category == category) &&
        (environment == 'All' || plant.environment == environment) &&
        (light == 'All' || plant.light == light) &&
        (water == 'All' || plant.water == water) &&
        (difficulty == 'All' || plant.difficulty == difficulty);
  }
}
