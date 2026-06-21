import os
import json
import urllib.request
import urllib.parse

def get_wikimedia_direct_url(file_name):
    api_url = "https://commons.wikimedia.org/w/api.php?" + urllib.parse.urlencode({
        "action": "query",
        "titles": f"File:{file_name}",
        "prop": "imageinfo",
        "iiprop": "url",
        "format": "json"
    })
    
    print(f"Querying Wikimedia API for {file_name}...")
    try:
        req = urllib.request.Request(
            api_url, 
            headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
        )
        with urllib.request.urlopen(req) as response:
            res_data = json.loads(response.read().decode())
            pages = res_data.get("query", {}).get("pages", {})
            for page_id, page_info in pages.items():
                imageinfo = page_info.get("imageinfo", [])
                if imageinfo:
                    return imageinfo[0].get("url")
    except Exception as e:
        print(f"API Error for {file_name}: {e}")
    return None

def download_file(url, destination):
    print(f"Downloading {url} to {destination}...")
    try:
        os.makedirs(os.path.dirname(destination), exist_ok=True)
        req = urllib.request.Request(
            url, 
            headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
        )
        with urllib.request.urlopen(req) as response, open(destination, 'wb') as out_file:
            out_file.write(response.read())
        print("Success!")
    except Exception as e:
        print(f"Error downloading {url}: {e}")

def download_tts(text, destination):
    print(f"Generating TTS for: '{text}'...")
    try:
        os.makedirs(os.path.dirname(destination), exist_ok=True)
        params = urllib.parse.urlencode({
            'ie': 'UTF-8',
            'client': 'tw-ob',
            'q': text,
            'tl': 'en'
        })
        url = f"https://translate.google.com/translate_tts?{params}"
        req = urllib.request.Request(
            url,
            headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}
        )
        with urllib.request.urlopen(req) as response, open(destination, 'wb') as out_file:
            out_file.write(response.read())
        print("TTS Success!")
    except Exception as e:
        print(f"Error generating TTS: {e}")

if __name__ == "__main__":
    # 1. Download SFX from Wikimedia
    sfx_to_download = {
        "Heartbeat.ogg": "assets/audio/sfx/heartbeat.ogg",
        "Wilhelm_Scream.ogg": "assets/audio/sfx/death_scream.ogg"
    }
    
    for wiki_name, dest in sfx_to_download.items():
        url = get_wikimedia_direct_url(wiki_name)
        if url:
            download_file(url, dest)
        else:
            print(f"Could not retrieve URL for {wiki_name}")
            
    # 2. Download TTS Dialogue Voice Lines
    dialogue_lines = {
        "Where... where am I? This place is freezing. I need to get out.": "assets/audio/dialog/start_dialog.mp3",
        "The porcelain doll. It's so cold... I feel a presence watching me.": "assets/audio/dialog/doll_dialog.mp3",
        "The Altar demands a vessel...": "assets/audio/dialog/altar_need_doll.mp3",
        "The sacrifice is complete. The presence is fading. I am free.": "assets/audio/dialog/victory_dialog.mp3"
    }
    
    for text, dest in dialogue_lines.items():
        download_tts(text, dest)
