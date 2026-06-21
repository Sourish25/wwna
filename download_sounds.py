import os
import json
import urllib.request
import urllib.parse

def get_wikimedia_direct_url(file_name):
    # API request to get direct file URL from title
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

if __name__ == "__main__":
    files_to_download = {
        "Horror_laugh.ogg": "assets/audio/sfx/ghost_laugh.ogg",
        "Kevin_MacLeod_-_Horroriffic.ogg": "assets/audio/music/horror_ambient.ogg"
    }
    
    for wiki_name, dest in files_to_download.items():
        url = get_wikimedia_direct_url(wiki_name)
        if url:
            download_file(url, dest)
        else:
            print(f"Could not retrieve URL for {wiki_name}")
