"""Publish and verify the v4.50 mission with the GitHub Actions job token."""
from hashlib import sha256
import json
import os
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent
REPO = "Iron87ita/WarZone-Caucasus-Dynamic-Sector-Campaign"
API = "https://api.github.com/repos/" + REPO
TAG = "v4.50"
TITLE = "WarZone Caucasus v4.50 – Central Air Corridor & Airlift Update"
NAME = "WarZone_IRON87_CAUCASO_DYNAMIC_SECTOR_MODERN_V4_50.miz"
DIGEST = "f60f376137e1ed0982963f3d1d8bc00a4ffb3d47ba66fd7fdf0be430190e2cee"
USER_AGENT = "WarZone-v4.50-Release-Publisher"


def request(url, method="GET", payload=None, content_type="application/json"):
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": "Bearer " + os.environ["GITHUB_TOKEN"],
        "User-Agent": USER_AGENT,
        "X-GitHub-Api-Version": "2022-11-28",
    }
    if payload is not None:
        headers["Content-Type"] = content_type
    data = json.dumps(payload).encode() if isinstance(payload, dict) else payload
    with urlopen(Request(url, data=data, headers=headers, method=method), timeout=120) as response:
        return json.load(response)


def publish():
    assert os.environ["GITHUB_REPOSITORY"] == REPO
    assert os.environ["GITHUB_REF"] == "refs/heads/main"
    mission = (ROOT / NAME).read_bytes()
    assert sha256(mission).hexdigest() == DIGEST, "Mission checksum mismatch"
    notes = (ROOT.parents[1] / "docs/releases/v4.50.md").read_text(encoding="utf-8")
    release = next((item for item in request(API + "/releases?per_page=100")
                    if item["tag_name"] == TAG), None)
    if release is None:
        release = request(API + "/releases", "POST", {
            "tag_name": TAG, "name": TITLE, "body": notes,
            "target_commitish": os.environ["GITHUB_SHA"],
            "draft": True, "prerelease": False,
        })
    assert release["name"] == TITLE and release["body"] == notes, "Unexpected existing release"
    release_url = API + "/releases/" + str(release["id"])
    assets = request(release_url + "/assets?per_page=100")
    if not assets:
        assert release["draft"], "Release was published without its mission asset"
        upload = release["upload_url"].split("{", 1)[0] + "?" + urlencode({"name": NAME})
        assets = [request(upload, "POST", mission, "application/octet-stream")]
    assert len(assets) == 1 and assets[0]["name"] == NAME, "Unexpected release assets"
    asset = assets[0]
    assert asset["state"] == "uploaded" and asset["digest"] == "sha256:" + DIGEST
    if release["draft"]:
        release = request(release_url, "PATCH", {"draft": False, "prerelease": False, "make_latest": "true"})
    latest = request(API + "/releases/latest")
    assert latest["id"] == release["id"] and not latest["draft"]
    download = Request(asset["browser_download_url"], headers={"User-Agent": USER_AGENT})
    with urlopen(download, timeout=120) as response:
        assert sha256(response.read()).hexdigest() == DIGEST, "Public asset checksum mismatch"
    print("Verified public mission download:", asset["browser_download_url"])


if __name__ == "__main__":
    publish()
