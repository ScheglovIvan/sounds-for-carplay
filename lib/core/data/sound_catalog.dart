import '../models/sound.dart';

/// The bundled, offline sound library.
///
/// Data is seeded from the app spec's audio inventory. Names are paraphrased
/// from the source app (e.g. its "<Brand> Airlines" naming gimmick becomes
/// "<Brand> Ignition") to avoid cloning its copy; the underlying audio content
/// is preserved. Category tags and free/premium flags are curated here so every
/// screen shares one source of truth.
///
/// Asset convention: each sound's bytes live at `assets/audio/<sha>.mp3`, copied
/// from the archive's `media/<sha>.mp3`. Both are recorded on each [Sound] so a
/// picker/audio task can resolve or (re)copy the file deterministically.
class SoundCatalog {
  SoundCatalog._();

  static const String _dir = 'assets/audio/';
  static const String _srcDir = 'media/';

  static Sound _mk(
    String id,
    String name,
    String sha,
    Set<SoundCategory> categories, {
    bool premium = true,
    String? brand,
  }) {
    return Sound(
      id: id,
      name: name,
      brand: brand,
      categories: categories,
      isPremium: premium,
      mediaId: id,
      assetPath: '$_dir$sha.mp3',
      sourcePath: '$_srcDir$sha.mp3',
    );
  }

  /// Convenience alias for an engine-startup ("ignition") sound.
  ///
  /// Engine clips are labelled by the kind of car they evoke (layout, body
  /// style, character) and share the generic `Engine` brand tag — the library
  /// carries no third-party marques.
  static Sound _engine(String id, String name, String sha, {bool premium = true}) =>
      _mk(id, name, sha, const {SoundCategory.engine},
          premium: premium, brand: 'Engine');

  /// All bundled sounds, in catalog order.
  static final List<Sound> all = <Sound>[
    // ── Generic / sport startups ────────────────────────────────────────────
    _mk('m8566e8780ccaa79', 'Sports Car Ignition 1',
        '8566e8780ccaa79fa8d27cac4f4a77ea5bd0c55060a93c3196d31a79a039130b',
        const {SoundCategory.engine}, premium: false, brand: 'Sports Car'),
    _mk('m2c9a7d6d61de05b', 'Sports Car Ignition 2',
        '2c9a7d6d61de05b3df2c9088a6614d0d43cbea0206d5435cb6ac3ad76cb9db27',
        const {SoundCategory.engine}, brand: 'Sports Car'),
    _mk('m4ae7359b8660eb4', 'Sports Car Ignition 3',
        '4ae7359b8660eb4512581177db2c7dc6d558c7d1d2e8c36381b563002d68308e',
        const {SoundCategory.engine}, brand: 'Sports Car'),
    _mk('mdf92210a7715bb5', 'Coupe Ignition',
        'df92210a7715bb5a8383ff6ba43493371aa74c66ce6ea5e7fcf20c9cc91f1df7',
        const {SoundCategory.engine}, premium: false, brand: 'Engine'),

    // ── Engine startups ─────────────────────────────────────────────────────
    _engine('m1163ccb0ed3a2b2', 'Italian V6',
        '1163ccb0ed3a2b27662b4896cad05d28b22d33a1c572680e4d8d2d9ae59be4e6'),
    _engine('m130fa325e3e822e', 'American V8',
        '130fa325e3e822edd6c1763ae1611f2e1599c736669a9229eee5e55e6a0f7baa'),
    _engine('m18c0508ab74056a', 'City Hatch',
        '18c0508ab74056a9fa9c8739f2b22cb7174cac3db72232bae26d1812ab8a4ac0'),
    _engine('m18e696d99047fce', 'Grand Tourer',
        '18e696d99047fce677ee29194953e51c9c617e12658efdc50e5c53f5e8f48c3d'),
    _engine('m190067e544d7955', 'Luxury Sedan',
        '190067e544d79553179dfa98036d8f06eb216f95e9f68b8dc70b8e63e3f7daa5'),
    _engine('m1cd6788b37e0221', 'Off-Roader',
        '1cd6788b37e0221410056aeb39f55c1a3e5bbcd80dcfdf98c51ce08fcbaf69cd'),
    _engine('m1e0117010ea22c4', 'Hybrid Luxe',
        '1e0117010ea22c4ec280ed31ac47b6e0ed3a08eb1685773860cf5c33f7f6249a'),
    _engine('m3f9550cb135d988', 'Compact Start',
        '3f9550cb135d98857d9f8a30fcabf7db3e9baae49da26c088f8224261db2f0d7'),
    _engine('m41c445575ec731e', 'Inline-Four',
        '41c445575ec731e655b8fa74aafd071bdddfa32b199c51e486143d4a447aac50'),
    _engine('m44f0eaf8a1191b0', 'Estate Start',
        '44f0eaf8a1191b003417259a7141a24e0bea197da3956546a4a3bea0b1469d7c'),
    _engine('m4ef819a59604a70', 'Nordic Wagon',
        '4ef819a59604a707ee8aff863dd02891ff40e57819b96d388ca50454cbecddd6'),
    _engine('m5722bb90433ec9d', 'Rotary Rev',
        '5722bb90433ec9d12aafea7974ed4eae471f6de62f1ad448769690dbf2bc3abb'),
    _engine('m57cfa69c8418425', 'Sport Sedan',
        '57cfa69c841842544ac73c80ea7b53c9422f8404e621c590b15f8c513df276d5'),
    _engine('m6cc08c1e2f43965', 'Electric Whir',
        '6cc08c1e2f439657424e8f700357d6794aada9d8ec40d1662e4b04f61c78a307'),
    _engine('m67bd8461bbee182', 'Executive Start',
        '67bd8461bbee182551707aaf056828d6fbb4ed652b22a893c9e6951098692802'),
    _engine('m86cd1c68792d27b', 'Hatchback Idle',
        '86cd1c68792d27b377298b26794859570e5589b5b91749d3f450b107583f0720'),
    _engine('m8a2c335609ebb91', 'Muscle Roar',
        '8a2c335609ebb91c257c5e5fe2953f14bb0f13fe385cb446df140a997552307e'),
    _engine('m8b6890eb9efa02f', 'Cruiser Start',
        '8b6890eb9efa02f5108bdc547eeca03e8f432a3c97a7500be6b33104da837702'),
    _engine('m8d387128a8522be', 'Tuner Rev',
        '8d387128a8522be34aaa17d21c4a7b4bfca30975a743a2112766faa2743c835f'),
    _engine('mb18c3521b96a202', 'Family Estate',
        'b18c3521b96a20272a2f9ea38977f9a1fb26590601984e13ecd492d6a366b5b8'),
    _engine('mbe8aecd8f985d2d', 'Inline-Six',
        'be8aecd8f985d2d7a6ac0e41a153613520bbc32b8ae72978e0ad1341f7591536'),
    _engine('mc0a8c9b1342b609', 'Mini Runabout',
        'c0a8c9b1342b60940ef9ab811ea8c96e8b245d0adf984792549c595a25d234f6'),
    _engine('mc7f736877159382', 'Reliable Start',
        'c7f7368771593827f76c96b88c0fb9e343c7f0c7cc348cd21ba0311338077ca9'),
    _engine('mcb28d47520e23e9', 'Compact Diesel',
        'cb28d47520e23e9a59d6b0b1fa1313457796dad994dccebc5e31a23a206f31f6'),
    _engine('me86692961a3bae8', 'Boulevard V8',
        'e86692961a3bae8673be1874d720f300b68bd957531718ca422ef62885fbcbc5'),
    _engine('mef799393af33878', 'Pickup Rumble',
        'ef799393af3387860e742340ee626fb221a720c118c7902929bee27e856554d2'),
    _engine('mda783afcf213048', "People's Coupe",
        'da783afcf213048fd3aaa04357f37121e6860b371722938d3fb677856e937922'),
    _engine('maa91e2bbc3ab276', 'Sporty Hatch',
        'aa91e2bbc3ab276d81b204b07dcf30b9cea597778e22ea138e69028b40a3e61a'),
    _engine('mfe8374dad73a126', 'Crossover Start',
        'fe8374dad73a1260f12044157d02af6d82c541f6ffb5fa933291034d07cb5c6d'),
    _engine('mff22272494e6247', 'Flat-Six Roar',
        'ff22272494e6247e983dbd37c08f97d9a172f2b9901336ce7326a12064b0f7b9'),
    _engine('mf6a2a5adeb34519', 'SUV Diesel',
        'f6a2a5adeb34519cb196533fafa903020da89ff9f9d0cc752795220fe35743ee'),

    // ── Cinematic / system / trends ─────────────────────────────────────────
    _mk('m0a9d4631073a412', 'Race Start',
        '0a9d4631073a412995f0ffc50fa48c0b275e17bb80eee75cc2da1168350101e1',
        const {SoundCategory.engine, SoundCategory.trends}, premium: false),
    _mk('madbf4405810967a', 'Eagle',
        'adbf4405810967a84ffacb901d757be155c1d9cd47f9bcabc64a423b753d9b13',
        const {SoundCategory.cinematic, SoundCategory.trends}, premium: false),
    _mk('m4a7e3957fbbc761', 'Bad to the Bone',
        '4a7e3957fbbc761fab2d486ffa5d6d375208e48778703b46850d478584ec30dd',
        const {SoundCategory.cinematic, SoundCategory.trends}),
    _mk('m58dffbf1d3c98c7', 'Retro Console Boot',
        '58dffbf1d3c98c79e508035b23468c07395cce719a5ee902ed0937ad6bfcd0da',
        const {SoundCategory.gaming, SoundCategory.cinematic}),
    _mk('mfe96e35a1d64555', 'USB Connect Chime',
        'fe96e35a1d645550eb15d5a78d48df5700e16e6ad85d1e554d0b22452629f914',
        const {SoundCategory.gaming}, premium: false),
    _mk('m92ffac5ed596d28', 'AI Assistant',
        '92ffac5ed596d2838cffb5a2e3a8ac45ac9bc46edb72bc90f48d27d2e1743c5e',
        const {SoundCategory.cinematic}),
    _mk('m9b6378ac9d45ab4', 'Flight Announcement',
        '9b6378ac9d45ab4c0bb202d429373d10eb886e633a4a66a31bda5a8626d17576',
        const {SoundCategory.cinematic, SoundCategory.memesFun}),

    // ── Greetings (Trending) ────────────────────────────────────────────────
    _mk('ma598b26d2d84adb', 'Good to See You, Sir',
        'a598b26d2d84adb4ab5596f69dc59cbac1d9949cabaa3049ea3e02970be93ab5',
        const {SoundCategory.trends}, premium: false),
    _mk('mc4f45ea461e5763', 'Hello Again, Queen',
        'c4f45ea461e57636d4c94034fffe9b8f8dd978304b5dad11f9cfbdd7cd4d881b',
        const {SoundCategory.trends}),
    _mk('mfbb0d36c55bbe62', "Hey Gorgeous, You're Back",
        'fbb0d36c55bbe6268d17dfbfba41406a589ddb7834da69614289c61db0569d34',
        const {SoundCategory.trends}),
    _mk('m76590863ea8922f', 'Rise and Grind',
        '76590863ea8922f74a61309c657e4708809fe4d362235f379f23d856d87678b7',
        const {SoundCategory.trends}, premium: false),
    _mk('me9b5bf7991eb8d8', 'Morning, Gossip Squad',
        'e9b5bf7991eb8d8b1aa9d9b89472cfb1abae080df2aee42964b338250a33156b',
        const {SoundCategory.trends}),

    // ── Fun & memes ─────────────────────────────────────────────────────────
    _mk('m0e778a2fbcac666', 'Cash Mode',
        '0e778a2fbcac6664f061c35866d4a8ef93654a4725bfc74e1fcb7313991fa08c',
        const {SoundCategory.memesFun}),
    _mk('m133114cdc23acf1', 'No, Please No',
        '133114cdc23acf1fb911d48d6252951dfdcef4b039c03d14c5c3bc01ff375ca0',
        const {SoundCategory.memesFun}),
    _mk('m426bfd03b25c8bc', 'Why You Running',
        '426bfd03b25c8bcbb07b28c76042f5d07dddfd1a10a76c5edd2177bc5eda51a7',
        const {SoundCategory.memesFun}, premium: false),
    _mk('m501ca446cd42fdb', 'Emotional Damage',
        '501ca446cd42fdba2c9cf02c725331b946f6c30756e51314f81f71839a2dacc0',
        const {SoundCategory.memesFun, SoundCategory.trends}),
    _mk('m876a5f8d81785a8', 'Oh No, Baby',
        '876a5f8d81785a8aff3a2c47a4e754016a506609fc8a0d36c27e59feb4bca077',
        const {SoundCategory.memesFun}),
    _mk('mcd6a77d4e59a138', 'Oh My Gosh',
        'cd6a77d4e59a138ba5221e5967111065c8f5f02c5d81d3643d97aaa2db016a4d',
        const {SoundCategory.memesFun}, premium: false),
    _mk('maa006f755cdc1a1', 'Get Out',
        'aa006f755cdc1a1c9ae0409a408b137c6a79e284d9f094ad470b1264499fac5b',
        const {SoundCategory.memesFun}),
    _mk('mcf7b463927be8dc', 'Rizz',
        'cf7b463927be8dcee8ac52213dea4b05b4101fb54a490d7394e3ebc723713525',
        const {SoundCategory.memesFun, SoundCategory.trends}),
    _mk('md0102397da0dca2', 'Wow',
        'd0102397da0dca2affa70911f870fe876f049bcaef0e7c39a532f76b3851ef05',
        const {SoundCategory.memesFun}, premium: false),
    _mk('ma050e9b6bf27c03', 'Let Him Cook',
        'a050e9b6bf27c033a4d48e3d80b3145af9e28e027b21993c2c18a79cfd2cd048',
        const {SoundCategory.memesFun}),
    _mk('m4fd527d163cbb49', 'Hello There',
        '4fd527d163cbb492af6287bc6ee0eb54478dc40085460b68b91ad652b3305cf5',
        const {SoundCategory.memesFun}, premium: false),
    _mk('m265e93add5a23c6', 'Yeah Boy',
        '265e93add5a23c6ef6ebbb0a6c467976d4ee4818317b653a90194f635213cc9b',
        const {SoundCategory.memesFun}),
    _mk('mf688f2049dd460f', "Alright, Let's Roll",
        'f688f2049dd460f8e96225d5dac91db24ddecd24b2ea82904eb891ca3cbc0915',
        const {SoundCategory.memesFun}),
    _mk('m897f9ba2c8732d9', 'Faaah',
        '897f9ba2c8732d9fd5319acbbabfcdabbfe6cfb7912f937e6650a7d441013679',
        const {SoundCategory.memesFun}),
    _mk('mdce3cb0bbfec199', 'Big Hello',
        'dce3cb0bbfec19954160bf0791e58e231bd1ab6196afe6cbc107117f5275e841',
        const {SoundCategory.memesFun}),
  ];

  /// Fast id lookup.
  static final Map<String, Sound> _byId = {
    for (final s in all) s.id: s,
  };

  /// Returns the sound with [id], or null if it is not in the catalog.
  static Sound? byId(String? id) => id == null ? null : _byId[id];

  /// Sounds tagged with [category] (or every sound for [SoundCategory.all]).
  static List<Sound> byCategory(SoundCategory category) =>
      all.where((s) => s.inCategory(category)).toList(growable: false);

  /// Filter by category and free-text query, matching the picker behaviour.
  static List<Sound> filter({
    SoundCategory category = SoundCategory.all,
    String query = '',
  }) =>
      all
          .where((s) => s.inCategory(category) && s.matchesQuery(query))
          .toList(growable: false);

  /// Sounds available without a PRO entitlement.
  static List<Sound> get freeSounds =>
      all.where((s) => !s.isPremium).toList(growable: false);
}
