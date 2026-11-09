"""Validate a live PokeAPI response; report network unavailability separately.

The APK contains the official Korean dictionary, so API availability is optional
for installation and browsing. A reachable but incompatible response is an error.
"""
import json
import time
import urllib.error
import urllib.request

url = 'https://pokeapi.co/api/v2/pokemon-species/1/'
request = urllib.request.Request(url, headers={
    'User-Agent': 'PokopiaHabitatGuide/1.1 (+https://github.com/ChoiSangJin/Pokopia-Spawn-Zone-App-)',
    'Accept': 'application/json',
})
for attempt in range(3):
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            data = json.load(response)
    except (urllib.error.URLError, TimeoutError) as error:
        if attempt < 2:
            time.sleep(1)
            continue
        reason = str(error).replace('\n', ' ')
        print(f'::warning::Live PokeAPI check SKIPPED: {reason}. Bundled/offline Korean names remain available; live API operation is unverified.')
        break
    else:
        assert data['id'] == 1, 'Unexpected species ID'
        assert next(item['name'] for item in data['names'] if item['language']['name'] == 'ko') == '이상해씨'
        print('Live PokeAPI Korean species contract verified: 이상해씨')
        break
