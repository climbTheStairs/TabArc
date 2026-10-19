#!/bin/env python3
import json, os, re, shutil, subprocess, sys, time
from urllib.error import HTTPError, URLError
from urllib.request import urlopen

# note: "x" must come before any item containing "x/*"
ENDPOINTS = [
    "../../institutions",
    "adjudicators",
    "adjudicators/standings",
    "break-categories",
    "break-categories/*/break",
    "break-categories/*/eligibility",
    "feedback-questions",
    "motions",
    "preferences",
    "questions",
    "rounds",
    "rounds/*/pairings",
    "rounds/*/pairings/*/ballots", # note: only confirmed=true rel
    "speaker-categories",
    "speaker-categories/*/eligibility",
    "speakers/standings", # probably derivable
    "speakers/standings/rounds", # almost certainly derivable; perhaps needed if ballots disabled?
    "teams",
    "teams/standings", # probably derivable
    "teams/standings/rounds", # almost certainly derivable
    "venue-categories",
    "venues",
]

def eprint(*args):
    print(*args, file=sys.stderr)

PAT_TOURN = re.compile(r"^https://([0-9a-z.-]+)/([0-9A-Za-z_]+)/$")
def main():
    assert len(sys.argv) == 2, "usage: {sys.argv[0]} tab_url"
    domain, tourn = PAT_TOURN.search(sys.argv[1]).groups()
    tourn_url = f"https://{domain}/api/v1/tournaments/{tourn}/"
    for path in ENDPOINTS:
        try:
            dl_endpt(tourn_url, path)
        except Exception as e:
            eprint(f"ERR: failed to dl {tourn_url+path}", e)
            continue

def dl_endpt(tourn_url, path):
    i = path.find("*")
    if i < 0:
        return dl(tourn_url, path)
    # if here then endpt certainly contains wildcard
    fname_par = path[:i-1].replace("/", "_") + ".json"
    if not os.path.exists(fname_par):
        return eprint(f"WARN: file {fname_par} not exist, skipping endpoint {tourn_url+path}")
    with open(fname_par) as f:
        for x in json.load(f):
            xid = x["url"].split("/")[-1]
            path_new = path.replace("*", xid, 1)
            try:
                dl_endpt(tourn_url, path_new)
            except Exception as e:
                eprint(f"ERR: failed to dl {tourn_url+path_new}", e)
                continue

E_NO_INET = -3
PAT_DOTDOT = re.compile(r"[^/]+/[.][.]/")
def dl(tourn_url, path):
    fname = path.replace("../", "").replace("/", "_") + ".json"
    if os.path.exists(fname):
        return #eprint(f"WARN: file {fname} already exists, skipping")
    url = tourn_url + path
    while PAT_DOTDOT.search(url):
        url = PAT_DOTDOT.sub("", url)
    eprint("INFO: dl", url)
    while True:
        try:
            with urlopen(url) as resp, open(fname, "wb") as f:
                shutil.copyfileobj(resp, f)
        except HTTPError as e:
            if e.code == 401:
                return
            raise
        except URLError as e:
            if e.reason.errno == E_NO_INET:
                continue
            raise
        finally:
            time.sleep(1)
        break

if __name__ == "__main__":
    main()
