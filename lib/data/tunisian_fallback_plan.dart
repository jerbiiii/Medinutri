import 'package:medinutri/models/health_models.dart';

/// Plan nutritionnel tunisien authentique — utilisé comme plan de secours
/// si l'API Groq est indisponible ou renvoie une réponse invalide.
class TunisianFallbackPlan {
  static NutritionPlan create(int userId, String userName) {
    return NutritionPlan(
      userId: userId,
      title: 'Programme Tunisien 7 Jours — $userName',
      description:
          'Plan hebdomadaire authentique basé sur la cuisine tunisienne traditionnelle. '
          'Riche en légumes, légumineuses, épices et saveurs de la Méditerranée.',
      weeklyMeals: _buildWeeklyMeals(),
      tips: [
        'Boire au moins 2 litres d\'eau par jour, surtout par temps chaud.',
        'Favoriser l\'huile d\'olive extra-vierge, pilier de la cuisine tunisienne.',
        'Manger lentement et mastiquer correctement pour une meilleure digestion.',
        'Les épices tunisiennes (cumin, coriandre, tabel) ont des propriétés anti-inflammatoires.',
        'Combiner légumineuses et céréales pour un apport en protéines complet (ex: lablabi + pain).',
        'Préférer la cuisson vapeur ou à l\'étouffée pour préserver les nutriments.',
        'Prendre un thé à la menthe sans sucre après les repas pour faciliter la digestion.',
      ],
    );
  }

  static Map<String, List<Meal>> _buildWeeklyMeals() {
    return {
      'Lundi': [
        Meal(
          name: 'Bssissa au lait',
          type: 'Petit-déjeuner',
          ingredients: ['bssissa (farine d\'orge grillée)', 'lait chaud', 'huile d\'olive', 'sel', 'miel optionnel'],
          preparation:
              'Mélanger 4 cuillères de bssissa avec du lait chaud jusqu\'à obtenir une pâte lisse. Ajouter une cuillère d\'huile d\'olive et de sel. Servir chaud.',
          calories: 340,
          protein: 12.0,
          carbs: 48.0,
          fat: 10.0,
          prepTime: '5 min',
        ),
        Meal(
          name: 'Lablabi aux œufs',
          type: 'Déjeuner',
          ingredients: ['pois chiches cuits', 'pain rassis', 'cumin', 'harissa', 'citron', 'huile d\'olive', 'œuf poché', 'ail'],
          preparation:
              'Faire chauffer les pois chiches avec l\'ail et le cumin. Poser sur du pain émietté. Ajouter l\'œuf poché, la harissa, le jus de citron et l\'huile d\'olive.',
          calories: 520,
          protein: 24.0,
          carbs: 65.0,
          fat: 14.0,
          prepTime: '20 min',
        ),
        Meal(
          name: 'Salade Mechouia avec Thon',
          type: 'Dîner',
          ingredients: ['poivrons grillés', 'tomates grillées', 'ail grillé', 'harissa', 'huile d\'olive', 'citron', 'thon en boîte', 'câpres'],
          preparation:
              'Griller les légumes au four ou directement sur la flamme. Les peler, les écraser grossièrement. Assaisonner avec harissa, huile d\'olive, citron. Garnir de thon et câpres.',
          calories: 310,
          protein: 22.0,
          carbs: 18.0,
          fat: 16.0,
          prepTime: '30 min',
        ),
      ],
      'Mardi': [
        Meal(
          name: 'Fricassée Tunisienne',
          type: 'Petit-déjeuner',
          ingredients: ['petits pains frits maison', 'thon', 'harissa', 'œuf dur', 'olive noire', 'câpres', 'pomme de terre bouillie'],
          preparation:
              'Frire les petits pains ronds dans l\'huile. Les couper et garnir de thon, œuf, olive, pomme de terre et harissa.',
          calories: 420,
          protein: 18.0,
          carbs: 45.0,
          fat: 18.0,
          prepTime: '25 min',
        ),
        Meal(
          name: 'Chorba Frik au Poulet',
          type: 'Déjeuner',
          ingredients: ['blé vert (frik)', 'poulet en morceaux', 'tomates', 'oignon', 'céleri', 'tabel', 'coriandre fraîche', 'sel', 'poivre'],
          preparation:
              'Faire revenir le poulet avec l\'oignon. Ajouter les tomates, le tabel, le frik et couvrir d\'eau. Laisser mijoter 45 min. Garnir de coriandre fraîche.',
          calories: 480,
          protein: 32.0,
          carbs: 52.0,
          fat: 12.0,
          prepTime: '50 min',
        ),
        Meal(
          name: 'Chakchouka aux Merguez',
          type: 'Dîner',
          ingredients: ['tomates concassées', 'poivrons', 'oignon', 'merguez', 'œufs', 'harissa', 'cumin', 'huile d\'olive'],
          preparation:
              'Faire revenir les merguez. Ajouter poivrons, oignons puis tomates. Assaisonner. Casser les œufs dans la sauce et couvrir jusqu\'à cuisson.',
          calories: 390,
          protein: 26.0,
          carbs: 22.0,
          fat: 22.0,
          prepTime: '25 min',
        ),
      ],
      'Mercredi': [
        Meal(
          name: 'Lben avec pain tabouna',
          type: 'Petit-déjeuner',
          ingredients: ['lben (lait fermenté)', 'pain tabouna maison', 'huile d\'olive', 'zaatar (thym)', 'olives'],
          preparation:
              'Réchauffer le pain tabouna. Tremper dans le lben frais. Accompagner d\'huile d\'olive avec zaatar et quelques olives noires.',
          calories: 310,
          protein: 14.0,
          carbs: 42.0,
          fat: 9.0,
          prepTime: '5 min',
        ),
        Meal(
          name: 'Couscous au Poisson',
          type: 'Déjeuner',
          ingredients: ['couscous fin', 'mérou ou daurade', 'carottes', 'navets', 'pois chiches', 'harissa', 'tomates', 'huile d\'olive', 'tabel'],
          preparation:
              'Cuire le couscous à la vapeur. Préparer la sauce avec poisson, légumes et épices. Servir le couscous nappé de sauce et accompagné de harissa.',
          calories: 620,
          protein: 38.0,
          carbs: 72.0,
          fat: 14.0,
          prepTime: '60 min',
        ),
        Meal(
          name: 'Ojja Merguez',
          type: 'Dîner',
          ingredients: ['merguez', 'poivrons', 'tomates', 'oignons', 'œufs', 'harissa', 'cumin', 'persil'],
          preparation:
              'Faire sauter les merguez en rondelles. Ajouter oignon, poivrons, tomates et harissa. Casser 3 œufs dans la sauce et remuer délicatement.',
          calories: 410,
          protein: 24.0,
          carbs: 14.0,
          fat: 28.0,
          prepTime: '20 min',
        ),
      ],
      'Jeudi': [
        Meal(
          name: 'Assida Zgougou',
          type: 'Petit-déjeuner',
          ingredients: ['pâte de pignons de pin (zgougou)', 'lait', 'fécule de maïs', 'eau de fleur d\'oranger', 'sucre', 'crème fraîche'],
          preparation:
              'Dissoudre la fécule dans le lait froid. Ajouter la pâte de zgougou et faire chauffer en remuant. Parfumer à l\'eau de fleur d\'oranger. Servir tiède.',
          calories: 360,
          protein: 8.0,
          carbs: 55.0,
          fat: 12.0,
          prepTime: '15 min',
        ),
        Meal(
          name: 'Brick à l\'Œuf et Thon',
          type: 'Déjeuner',
          ingredients: ['feuilles de brick', 'thon', 'œufs', 'persil', 'harissa', 'câpres', 'fromage râpé', 'huile de friture'],
          preparation:
              'Disposer thon, câpres et harissa sur la feuille de brick. Casser l\'œuf au centre. Plier en demi-lune et frire jusqu\'à dorure.',
          calories: 440,
          protein: 22.0,
          carbs: 35.0,
          fat: 24.0,
          prepTime: '15 min',
        ),
        Meal(
          name: 'Mloukhia (Corète en sauce)',
          type: 'Dîner',
          ingredients: ['feuilles de corète séchées (mloukhia)', 'viande d\'agneau', 'ail', 'coriandre sèche', 'harissa', 'huile d\'olive'],
          preparation:
              'Cuire la viande. Faire revenir l\'ail et la coriandre dans l\'huile. Ajouter la mloukhia en poudre et de l\'eau. Laisser mijoter 1h. Servir avec pain.',
          calories: 500,
          protein: 30.0,
          carbs: 20.0,
          fat: 32.0,
          prepTime: '75 min',
        ),
      ],
      'Vendredi': [
        Meal(
          name: 'Kalb El Louz (gâteau tunisien)',
          type: 'Petit-déjeuner',
          ingredients: ['semoule fine', 'amandes moulues', 'beurre', 'sucre', 'eau de fleur d\'oranger', 'miel', 'amandes entières'],
          preparation:
              'Mélanger semoule, amandes, beurre et sucre. Mouler dans un plat. Faire dorer au four 30 min. Napper de miel et décorer d\'amandes.',
          calories: 420,
          protein: 9.0,
          carbs: 58.0,
          fat: 18.0,
          prepTime: '40 min',
        ),
        Meal(
          name: 'Couscous à l\'Agneau et Légumes',
          type: 'Déjeuner',
          ingredients: ['couscous', 'épaule d\'agneau', 'courgettes', 'potiron', 'navets', 'pois chiches', 'tomates', 'harissa', 'ras-el-hanout'],
          preparation:
              'Cuire le couscous à la vapeur 3 fois. Préparer la marqa avec viande et légumes épicés. Servir monté et arroser de bouillon.',
          calories: 680,
          protein: 40.0,
          carbs: 78.0,
          fat: 18.0,
          prepTime: '90 min',
        ),
        Meal(
          name: 'Kafteji Tunisien',
          type: 'Dîner',
          ingredients: ['courgettes frites', 'poivrons frits', 'tomates frites', 'pomme de terre frite', 'œufs', 'harissa', 'sel', 'poivre'],
          preparation:
              'Frire tous les légumes séparément jusqu\'à dorure. Broyer grossièrement. Mélanger avec des œufs brouillés. Assaisonner de harissa.',
          calories: 380,
          protein: 14.0,
          carbs: 38.0,
          fat: 20.0,
          prepTime: '30 min',
        ),
      ],
      'Samedi': [
        Meal(
          name: 'Makroudh aux Dattes',
          type: 'Petit-déjeuner',
          ingredients: ['semoule', 'huile', 'eau de fleur d\'oranger', 'pâte de dattes', 'sirop de miel', 'cannelle'],
          preparation:
              'Pétrir la semoule avec huile et eau de fleur d\'oranger. Farcir de pâte de dattes. Frire jusqu\'à dorure. Tremper dans le miel.',
          calories: 450,
          protein: 6.0,
          carbs: 72.0,
          fat: 16.0,
          prepTime: '45 min',
        ),
        Meal(
          name: 'Tajine Malsouka (Tajine aux Feuilles de Brick)',
          type: 'Déjeuner',
          ingredients: ['feuilles de brick', 'poulet', 'fromage', 'persil', 'œufs', 'oignons', 'épices tunisiennes'],
          preparation:
              'Faire revenir le poulet émietté avec oignons et épices. Préparer un appareil avec œufs et fromage. Alterner feuilles de brick et farce. Cuire au four.',
          calories: 540,
          protein: 34.0,
          carbs: 40.0,
          fat: 24.0,
          prepTime: '50 min',
        ),
        Meal(
          name: 'Merguez Grillées et Salade Tunisienne',
          type: 'Dîner',
          ingredients: ['merguez fraîches', 'tomates', 'concombre', 'oignons', 'menthe fraîche', 'persil', 'citron', 'huile d\'olive', 'harissa'],
          preparation:
              'Griller les merguez à la plancha ou au barbecue. Préparer la salade en dés. Assaisonner citron et huile. Servir avec du pain.',
          calories: 370,
          protein: 20.0,
          carbs: 16.0,
          fat: 26.0,
          prepTime: '20 min',
        ),
      ],
      'Dimanche': [
        Meal(
          name: 'Ftayer (Feuilletés farcis)',
          type: 'Petit-déjeuner',
          ingredients: ['pâte feuilletée', 'thon', 'tomates', 'harissa', 'fromage', 'olive', 'œuf pour badigeonner'],
          preparation:
              'Étaler la pâte. Farci de thon, tomates et fromage. Plier en triangle. Badigeonner d\'œuf. Cuire au four 20 min à 180°C.',
          calories: 380,
          protein: 16.0,
          carbs: 38.0,
          fat: 18.0,
          prepTime: '30 min',
        ),
        Meal(
          name: 'Marqa Poulet aux Olives',
          type: 'Déjeuner',
          ingredients: ['poulet', 'olives vertes', 'citron confit', 'oignons', 'tomates', 'safran', 'curcuma', 'coriandre', 'persil'],
          preparation:
              'Faire revenir le poulet doré. Ajouter oignons, tomates, épices et couvrir. Ajouter olives et citron confit. Mijoter 40 min. Garnir d\'herbes fraîches.',
          calories: 490,
          protein: 38.0,
          carbs: 22.0,
          fat: 26.0,
          prepTime: '55 min',
        ),
        Meal(
          name: 'Borghol aux Légumes',
          type: 'Dîner',
          ingredients: ['borghol (blé concassé)', 'courgettes', 'tomates', 'oignons', 'pois chiches', 'persil', 'menthe', 'citron', 'huile d\'olive'],
          preparation:
              'Cuire le borghol à l\'eau bouillante salée. Faire revenir les légumes. Mélanger tout avec herbes fraîches, citron et huile d\'olive. Servir tiède.',
          calories: 380,
          protein: 14.0,
          carbs: 62.0,
          fat: 8.0,
          prepTime: '25 min',
        ),
      ],
    };
  }
}
