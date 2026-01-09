// This file acts as a curated database of high-quality "Internet-sourced" content
// for Sri Lankan destinations. It simulates dynamic fetching by providing a rich
// fallback dataset for any city the app might encounter.

final List<Map<String, dynamic>> allDestinationsData = [
  {
    'city': 'Colombo',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/22/Colombo_Skyline_2019.jpg/800px-Colombo_Skyline_2019.jpg',
    'desc':
        'The vibrant commercial capital. Discover luxury shopping at One Galle Face, vibrant street food at Galle Face Green, and colonial charm in the Fort district.',
    'buses': 150
  },
  {
    'city': 'Kandy',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Kandy_Lake_and_Temple_of_the_Tooth.jpg/800px-Kandy_Lake_and_Temple_of_the_Tooth.jpg',
    'desc':
        'The hill capital and home to the sacred Temple of the Tooth Relic. Experience rich culture, the Esala Perahera in August, and misty mountain views.',
    'buses': 85,
  },
  {
    'city': 'Galle',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Galle_Fort_Lighthouse_2019.jpg/800px-Galle_Fort_Lighthouse_2019.jpg',
    'desc':
        'A UNESCO World Heritage site. Wander through the cobblestone streets of the 17th-century Dutch Fort, featuring boutique cafes, lighthouses, and ocean bastions.',
    'buses': 60,
  },
  {
    'city': 'Ella',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/Nine_Arch_Bridge_Ella.jpg/800px-Nine_Arch_Bridge_Ella.jpg',
    'desc':
        'A backpacker\'s paradise. Hike up Little Adam\'s Peak, marvel at the Nine Arch Bridge, and enjoy the cool climate and unending tea plantations.',
    'buses': 40,
  },
  {
    'city': 'Nuwara Eliya',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/d/df/Gregory_Lake_Nuwara_Eliya.jpg/800px-Gregory_Lake_Nuwara_Eliya.jpg',
    'desc':
        'Known as "Little England". Famous for its colonial bungalows, chilly weather, Gregory Lake, and the world\'s finest teas.',
    'buses': 35,
  },
  {
    'city': 'Sigiriya',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Sigiriya_Rock_Fortress.jpg/800px-Sigiriya_Rock_Fortress.jpg',
    'desc':
        'The 8th Wonder of the World. Climb the ancient Lion Rock fortress and witness the cloud maidens frescoes and the mirror wall.',
    'buses': 25,
  },
  {
    'city': 'Jaffna',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5e/Nallur_Kandaswamy_Kovil_2015.jpg/800px-Nallur_Kandaswamy_Kovil_2015.jpg',
    'desc':
        'The heart of Northern culture. Visit the golden Nallur Kandaswamy Kovil, taste authentic crab curry, and explore the historic Jaffna Library.',
    'buses': 45,
  },
  {
    'city': 'Trincomalee',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/8d/Koneswaram_Temple_Trincomalee.jpg/800px-Koneswaram_Temple_Trincomalee.jpg',
    'desc':
        'Home to one of the world\'s finest natural harbors. Snorkel at Pigeon Island, visit Koneswaram Temple, and relax on Nilaveli Beach.',
    'buses': 30,
  },
  {
    'city': 'Anuradhapura',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/1/15/Ruwanwelisaya_Stupa.jpg/800px-Ruwanwelisaya_Stupa.jpg',
    'desc':
        'The ancient capital. A sacred city of massive stupas like Ruwanwelisaya and the ancient Sri Maha Bodhi tree.',
    'buses': 40,
  },
  {
    'city': 'Mirissa',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e0/Mirissa_Beach_Sri_Lanka.jpg/800px-Mirissa_Beach_Sri_Lanka.jpg',
    'desc':
        'The best place for whale watching. Enjoy surfing, coconut tree hills, and vibrant beach nightlife.',
    'buses': 50,
  },
  {
    'city': 'Matara',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b5/Matara_Parey_Duwa.jpg/800px-Matara_Parey_Duwa.jpg',
    'desc':
        'A bustling southern commercial hub. Visit the Paravi Duwa temple and the historic Star Fort.',
    'buses': 55,
  },
  {
    'city': 'Negombo',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/91/Negombo_Beach_Sunset.jpg/800px-Negombo_Beach_Sunset.jpg',
    'desc':
        'Little Rome. Famous for its fishing industry, wide sandy beaches, and proximity to the airport.',
    'buses': 70,
  },
  {
    'city': 'Hambantota',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2c/Hambantota_Port.jpg/800px-Hambantota_Port.jpg',
    'desc':
        'The emerging southern hub. Gateway to Yala National Park and home to the dry zone botanic gardens.',
    'buses': 20,
  },
  {
    'city': 'Badulla',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a2/Badulla_Railway_Station.jpg/800px-Badulla_Railway_Station.jpg',
    'desc':
        'Surrounded by tea plantations and the Dunhinda Falls. The terminus of the famous Main Line railway.',
    'buses': 28,
  },
  {
    'city': 'Ratnapura',
    'image':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/5/52/Adam%27s_Peak_View_from_Ratnapura.jpg/800px-Adam%27s_Peak_View_from_Ratnapura.jpg',
    'desc':
        'The City of Gems. Famous for gem mining and as a starting point for Adam\'s Peak pilgrimages.',
    'buses': 32,
  }
];
