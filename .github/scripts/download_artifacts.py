import json
import requests
import sys

urls = {}
with open(sys.argv[1]) as f:
    artifacts = json.load(f)
    for artifact in artifacts['artifacts']:
        urls[artifact['name']] = artifact['archive_download_url']

headers = {
    'Accept': 'application/vnd.github+json',
    'Authorization': 'Bearer ' + sys.argv[2],
    'X-GitHub-Api-Version': '2022-11-28',
}

for url in urls:
    print("Downloading artifact for architecture " + url)
    response = requests.get(urls[url], headers=headers)
    with open(url + '.zip', 'wb') as r:
        r.write(response.content)
        print("Wrote zip for " + url)
