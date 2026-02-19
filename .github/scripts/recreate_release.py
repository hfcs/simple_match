#!/usr/bin/env python3
import os, sys, json, urllib.request, urllib.error

def main():
    REPO = "hfcs/simple_match"
    TAG = "v2026-02-19"
    GITHUB_TOKEN = os.environ.get("GITHUB_TOKEN")
    if not GITHUB_TOKEN:
        print("GITHUB_TOKEN not set", file=sys.stderr)
        return 2
    base = f"https://api.github.com/repos/{REPO}"
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json",
        "Content-Type": "application/json",
    }

    def http(url, method='GET', data=None):
        data_bytes = json.dumps(data).encode('utf-8') if data is not None else None
        req = urllib.request.Request(url, data=data_bytes, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req) as resp:
                return resp.getcode(), resp.read().decode('utf-8')
        except urllib.error.HTTPError as e:
            try:
                body = e.read().decode('utf-8')
            except:
                body = ''
            return e.code, body

    # 1) check existing release
    code, body = http(f"{base}/releases/tags/{TAG}")
    if code == 200:
        j = json.loads(body)
        rid = j.get('id')
        print('Found release id', rid, '— deleting')
        http(f"{base}/releases/{rid}", method='DELETE')
    else:
        print('No existing release object (HTTP', code, ')')

    # 2) delete tag ref (may 404)
    code, body = http(f"{base}/git/refs/tags/{TAG}", method='DELETE')
    print('delete tag ref response code', code)

    # 3) create release
    payload = {
        'tag_name': TAG,
        'target_commitish': 'main',
        'name': TAG,
        'body': 'Release v2026-02-19 (recreated to point at current main)\\n\\nIncludes CI refactor: parallel test controller and documentation updates.',
        'draft': False,
        'prerelease': False
    }

    code, body = http(f"{base}/releases", method='POST', data=payload)
    print('create response code', code)
    if code not in (200, 201):
        print('create failed:', body, file=sys.stderr)
        return 3
    try:
        j = json.loads(body)
        print(j.get('html_url'))
    except Exception:
        print('created but could not parse response')
        print(body)
    return 0

if __name__ == '__main__':
    sys.exit(main())
