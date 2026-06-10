class TimeHelper {

  static const Map<String, String> _locationToTz = {
    // Indonesia untuk deteksi, bukan slot dinamis
    'jakarta':        'Asia/Jakarta',
    'bandung':        'Asia/Jakarta',
    'surabaya':       'Asia/Jakarta',
    'medan':          'Asia/Jakarta',
    'semarang':       'Asia/Jakarta',
    'yogyakarta':     'Asia/Jakarta',
    'makassar':       'Asia/Makassar',
    'bali':           'Asia/Makassar',
    'denpasar':       'Asia/Makassar',
    'lombok':         'Asia/Makassar',
    'papua':          'Asia/Jayapura',
    'jayapura':       'Asia/Jayapura',
    'ambon':          'Asia/Jayapura',

    // Singapore
    'singapore':      'Asia/Singapore',
    'singapura':      'Asia/Singapore',
    'central region': 'Asia/Singapore',
    'east region':    'Asia/Singapore',
    'west region':    'Asia/Singapore',
    'north region':   'Asia/Singapore',

    // Malaysia
    'malaysia':       'Asia/Kuala_Lumpur',
    'kuala lumpur':   'Asia/Kuala_Lumpur',

    // India
    'india':          'Asia/Kolkata',
    'bangalore':      'Asia/Kolkata',
    'bengaluru':      'Asia/Kolkata',
    'mumbai':         'Asia/Kolkata',
    'delhi':          'Asia/Kolkata',
    'hyderabad':      'Asia/Kolkata',
    'chennai':        'Asia/Kolkata',
    'pune':           'Asia/Kolkata',
    'kolkata':        'Asia/Kolkata',
    'ahmedabad':      'Asia/Kolkata',
    'noida':          'Asia/Kolkata',
    'gurgaon':        'Asia/Kolkata',

    // Australia
    'australia':      'Australia/Sydney',
    'sydney':         'Australia/Sydney',
    'melbourne':      'Australia/Melbourne',
    'brisbane':       'Australia/Brisbane',
    'gold coast':     'Australia/Brisbane',
    'perth':          'Australia/Perth',
    'adelaide':       'Australia/Adelaide',
    'canberra':       'Australia/Sydney',
    'hobart':         'Australia/Hobart',
    'darwin':         'Australia/Darwin',

    // UK
    'uk':             'Europe/London',
    'london':         'Europe/London',
    'england':        'Europe/London',
    'manchester':     'Europe/London',
    'birmingham':     'Europe/London',
    'leeds':          'Europe/London',
    'glasgow':        'Europe/London',
    'bristol':        'Europe/London',
    'edinburgh':      'Europe/London',
    'sheffield':      'Europe/London',
    'liverpool':      'Europe/London',
    'nottingham':     'Europe/London',

    // Germany
    'germany':        'Europe/Berlin',
    'berlin':         'Europe/Berlin',
    'munich':         'Europe/Berlin',
    'hamburg':        'Europe/Berlin',
    'frankfurt':      'Europe/Berlin',
    'cologne':        'Europe/Berlin',
    'stuttgart':      'Europe/Berlin',
    'dusseldorf':     'Europe/Berlin',
    'düsseldorf':     'Europe/Berlin',
    'leipzig':        'Europe/Berlin',

    // USA
    'usa':            'America/New_York',
    'new york':       'America/New_York',
    'boston':         'America/New_York',
    'miami':          'America/New_York',
    'atlanta':        'America/New_York',
    'washington':     'America/New_York',
    'philadelphia':   'America/New_York',
    'chicago':        'America/Chicago',
    'houston':        'America/Chicago',
    'dallas':         'America/Chicago',
    'austin':         'America/Chicago',
    'denver':         'America/Denver',
    'los angeles':    'America/Los_Angeles',
    'san francisco':  'America/Los_Angeles',
    'seattle':        'America/Los_Angeles',
    'silicon valley': 'America/Los_Angeles',

    // Canada
    'canada':         'America/Toronto',
    'toronto':        'America/Toronto',
    'montreal':       'America/Toronto',
    'ottawa':         'America/Toronto',
    'quebec':         'America/Toronto',
    'quebec city':    'America/Toronto',
    'edmonton':       'America/Edmonton',
    'calgary':        'America/Edmonton',
    'winnipeg':       'America/Winnipeg',
    'vancouver':      'America/Vancouver',

    // Lainnya
    'japan':          'Asia/Tokyo',
    'tokyo':          'Asia/Tokyo',
    'osaka':          'Asia/Tokyo',
    'korea':          'Asia/Seoul',
    'seoul':          'Asia/Seoul',
    'china':          'Asia/Shanghai',
    'beijing':        'Asia/Shanghai',
    'shanghai':       'Asia/Shanghai',
    'shenzhen':       'Asia/Shanghai',
    'hong kong':      'Asia/Hong_Kong',
    'taiwan':         'Asia/Taipei',
    'taipei':         'Asia/Taipei',
    'thailand':       'Asia/Bangkok',
    'bangkok':        'Asia/Bangkok',
    'vietnam':        'Asia/Ho_Chi_Minh',
    'ho chi minh':    'Asia/Ho_Chi_Minh',
    'philippines':    'Asia/Manila',
    'manila':         'Asia/Manila',
    'dubai':          'Asia/Dubai',
    'uae':            'Asia/Dubai',
    'saudi':          'Asia/Riyadh',
    'riyadh':         'Asia/Riyadh',
    'france':         'Europe/Paris',
    'paris':          'Europe/Paris',
    'netherlands':    'Europe/Amsterdam',
    'amsterdam':      'Europe/Amsterdam',
    'russia':         'Europe/Moscow',
    'moscow':         'Europe/Moscow',
    'brazil':         'America/Sao_Paulo',
    'sao paulo':      'America/Sao_Paulo',
    'south africa':   'Africa/Johannesburg',
    'johannesburg':   'Africa/Johannesburg',
    'new zealand':    'Pacific/Auckland',
    'auckland':       'Pacific/Auckland',
  };

  static const Map<String, String> _tzLabels = {
    'Asia/Jakarta':                   'WIB',
    'Asia/Makassar':                  'WITA',
    'Asia/Jayapura':                  'WIT',
    'Asia/Singapore':                 'SGT - Singapura',
    'Asia/Kuala_Lumpur':              'MYT - Kuala Lumpur',
    'Asia/Tokyo':                     'JST - Tokyo',
    'Asia/Seoul':                     'KST - Seoul',
    'Asia/Shanghai':                  'CST - Shanghai',
    'Asia/Kolkata':                   'IST - India',
    'Asia/Dubai':                     'GST - Dubai',
    'Asia/Riyadh':                    'AST - Riyadh',
    'Asia/Bangkok':                   'ICT - Bangkok',
    'Asia/Ho_Chi_Minh':               'ICT - Ho Chi Minh',
    'Asia/Manila':                    'PHT - Manila',
    'Asia/Hong_Kong':                 'HKT - Hong Kong',
    'Asia/Taipei':                    'CST - Taipei',
    'Australia/Sydney':               'AEST - Sydney',
    'Australia/Melbourne':            'AEST - Melbourne',
    'Australia/Brisbane':             'AEST - Brisbane',
    'Australia/Perth':                'AWST - Perth',
    'Australia/Adelaide':             'ACST - Adelaide',
    'Australia/Hobart':               'AEST - Hobart',
    'Australia/Darwin':               'ACST - Darwin',
    'Pacific/Auckland':               'NZST - Auckland',
    'Europe/London':                  'GMT - London',
    'Europe/Paris':                   'CET - Paris',
    'Europe/Berlin':                  'CET - Berlin',
    'Europe/Amsterdam':               'CET - Amsterdam',
    'Europe/Moscow':                  'MSK - Moscow',
    'America/New_York':               'EST - New York',
    'America/Chicago':                'CST - Chicago',
    'America/Los_Angeles':            'PST - Los Angeles',
    'America/Denver':                 'MST - Denver',
    'America/Toronto':                'EST - Toronto',
    'America/Edmonton':               'MST - Edmonton',
    'America/Winnipeg':               'CST - Winnipeg',
    'America/Vancouver':              'PST - Vancouver',
    'America/Sao_Paulo':              'BRT - Sao Paulo',
    'Africa/Johannesburg':            'SAST - Johannesburg',
  };

  /// Deteksi timezone luar negeri dari teks lokasi loker.
  /// Return null kalau lokasi Indonesia (tidak perlu slot dinamis).
  static String? detectForeignTimezone(String location) {
    final loc = location.toLowerCase().trim();

    const indonesiaKeywords = [
      'indonesia', 'jakarta', 'bandung', 'surabaya', 'medan',
      'semarang', 'yogyakarta', 'makassar', 'bali', 'denpasar',
      'lombok', 'papua', 'jayapura', 'ambon', 'wib', 'wita', 'wit',
    ];
    for (final kw in indonesiaKeywords) {
      if (loc.contains(kw)) return null;
    }

    final sortedKeys = _locationToTz.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    for (final keyword in sortedKeys) {
      if (loc.contains(keyword)) {
        return _locationToTz[keyword];
      }
    }
    return null;
  }

  static String labelFromTz(String tz) {
    return _tzLabels[tz] ?? tz.split('/').last.replaceAll('_', ' ');
  }

  // 3 slot tetap Indonesia — label bersih tanpa nama kota
  static const List<Map<String, String>> indonesiaTimezones = [
    {'label': 'WIB',  'tz': 'Asia/Jakarta'},
    {'label': 'WITA', 'tz': 'Asia/Makassar'},
    {'label': 'WIT',  'tz': 'Asia/Jayapura'},
  ];

  static const List<Map<String, String>> foreignTimezones = [
    {'label': 'SGT - Singapura',     'tz': 'Asia/Singapore'},
    {'label': 'MYT - Kuala Lumpur',  'tz': 'Asia/Kuala_Lumpur'},
    {'label': 'JST - Tokyo',         'tz': 'Asia/Tokyo'},
    {'label': 'KST - Seoul',         'tz': 'Asia/Seoul'},
    {'label': 'CST - Shanghai',      'tz': 'Asia/Shanghai'},
    {'label': 'IST - India',         'tz': 'Asia/Kolkata'},
    {'label': 'ICT - Bangkok',       'tz': 'Asia/Bangkok'},
    {'label': 'PHT - Manila',        'tz': 'Asia/Manila'},
    {'label': 'HKT - Hong Kong',     'tz': 'Asia/Hong_Kong'},
    {'label': 'GST - Dubai',         'tz': 'Asia/Dubai'},
    {'label': 'AST - Riyadh',        'tz': 'Asia/Riyadh'},
    {'label': 'AEST - Sydney',       'tz': 'Australia/Sydney'},
    {'label': 'AEST - Melbourne',    'tz': 'Australia/Melbourne'},
    {'label': 'AEST - Brisbane',     'tz': 'Australia/Brisbane'},
    {'label': 'AWST - Perth',        'tz': 'Australia/Perth'},
    {'label': 'ACST - Adelaide',     'tz': 'Australia/Adelaide'},
    {'label': 'ACST - Darwin',       'tz': 'Australia/Darwin'},
    {'label': 'AEST - Hobart',       'tz': 'Australia/Hobart'},
    {'label': 'NZST - Auckland',     'tz': 'Pacific/Auckland'},
    {'label': 'GMT - London',        'tz': 'Europe/London'},
    {'label': 'CET - Berlin',        'tz': 'Europe/Berlin'},
    {'label': 'CET - Paris',         'tz': 'Europe/Paris'},
    {'label': 'CET - Amsterdam',     'tz': 'Europe/Amsterdam'},
    {'label': 'MSK - Moscow',        'tz': 'Europe/Moscow'},
    {'label': 'EST - New York',      'tz': 'America/New_York'},
    {'label': 'CST - Chicago',       'tz': 'America/Chicago'},
    {'label': 'PST - Los Angeles',   'tz': 'America/Los_Angeles'},
    {'label': 'MST - Denver',        'tz': 'America/Denver'},
    {'label': 'EST - Toronto',       'tz': 'America/Toronto'},
    {'label': 'MST - Edmonton',      'tz': 'America/Edmonton'},
    {'label': 'CST - Winnipeg',      'tz': 'America/Winnipeg'},
    {'label': 'PST - Vancouver',     'tz': 'America/Vancouver'},
    {'label': 'BRT - Sao Paulo',     'tz': 'America/Sao_Paulo'},
    {'label': 'SAST - Johannesburg', 'tz': 'Africa/Johannesburg'},
  ];
}