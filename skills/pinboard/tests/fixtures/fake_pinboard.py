"""A fake Pinboard v1 API, served from the importing test's process."""

from __future__ import annotations

import hashlib
import json
import threading
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

TOKEN = "testuser:0123456789ABCDEF0123"


class Fake:
    """A Pinboard v1 API with knobs for failure cases."""

    def __init__(self) -> None:
        self.lock = threading.Lock()
        self.posts: dict[str, dict[str, str]] = {}
        self.tick = 0
        self.update_time = ""
        self.calls: list[tuple[str, dict[str, str]]] = []
        self.reset_knobs()

    def reset_knobs(self) -> None:
        self.all_mode = ""  # empty, malformed, truncated, error
        self.all_delay = 0.0  # seconds posts/all takes, outside the lock
        self.hidden: set[str] = set()  # omitted from posts/all only
        self.get_error = False
        self.rate_limit = 0
        self.rate_limit_only = ""  # an endpoint, to rate limit only that one
        self.add_mode = ""  # vanish-after (apply, no response), vanish-before

    def put(
        self, url, title, time_, notes="", tags="", shared="no", toread="no"
    ) -> None:
        post = {
            "href": url,
            "description": title,
            "extended": notes,
            "hash": hashlib.md5(url.encode()).hexdigest(),
            "time": time_,
            "shared": shared,
            "toread": toread,
            "tags": tags,
        }
        post["meta"] = hashlib.md5(
            json.dumps(post, sort_keys=True).encode()
        ).hexdigest()
        self.posts[url] = post
        self.touch()

    def delete(self, url) -> None:
        del self.posts[url]
        self.touch()

    def touch(self) -> None:
        # Pinboard's update_time has one-second resolution; count instead.
        self.tick += 1
        self.update_time = time.strftime(
            "%Y-%m-%dT%H:%M:%SZ", time.gmtime(1767225600 + self.tick)
        )

    def count(self, endpoint: str) -> int:
        return sum(1 for e, _ in self.calls if e == endpoint)


FAKE = Fake()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args) -> None:
        pass

    def send(self, status: int, body) -> None:
        data = body if isinstance(body, bytes) else json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "text/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self) -> None:
        parts = urllib.parse.urlsplit(self.path)
        endpoint = parts.path.removeprefix("/v1/")
        q = {
            k: v[0]
            for k, v in urllib.parse.parse_qs(
                parts.query, keep_blank_values=True
            ).items()
        }
        if q.pop("auth_token", None) != TOKEN:
            return self.send(401, b"")
        if endpoint == "posts/all" and FAKE.all_delay:
            time.sleep(FAKE.all_delay)
        with FAKE.lock:
            FAKE.calls.append((endpoint, q))
            if FAKE.rate_limit and FAKE.rate_limit_only in ("", endpoint):
                FAKE.rate_limit -= 1
                return self.send(429, b"")
            if endpoint == "posts/update":
                return self.send(200, {"update_time": FAKE.update_time})
            if endpoint == "posts/all":
                if FAKE.all_mode == "error":
                    return self.send(500, b"")
                if FAKE.all_mode == "empty":
                    return self.send(200, [])
                posts = [p for u, p in FAKE.posts.items() if u not in FAKE.hidden]
                posts.sort(key=lambda p: p["time"], reverse=True)
                if FAKE.all_mode == "malformed":
                    posts = [dict(posts[0]), *posts[1:]]
                    del posts[0]["href"]
                body = json.dumps(posts).encode()
                if FAKE.all_mode == "truncated":
                    body = body[: len(body) // 2]
                return self.send(200, body)
            if endpoint == "posts/get":
                if FAKE.get_error:
                    return self.send(500, b"")
                post = FAKE.posts.get(q.get("url", ""))
                return self.send(
                    200,
                    {
                        "date": FAKE.update_time,
                        "user": "testuser",
                        "posts": [post] if post else [],
                    },
                )
            if endpoint == "posts/add":
                if FAKE.add_mode == "vanish-before":
                    FAKE.add_mode = ""
                    return
                url = q["url"]
                if url in FAKE.posts and q.get("replace") == "no":
                    return self.send(200, {"result_code": "item already exists"})
                stamp = q.get("dt") or time.strftime(
                    "%Y-%m-%dT%H:%M:%SZ", time.gmtime()
                )
                FAKE.put(
                    url,
                    q["description"],
                    stamp,
                    q.get("extended", ""),
                    q.get("tags", ""),
                    q.get("shared", "yes"),
                    q.get("toread", "no"),
                )
                if FAKE.add_mode == "vanish-after":
                    FAKE.add_mode = ""
                    return
                return self.send(200, {"result_code": "done"})
            if endpoint == "posts/suggest":
                return self.send(
                    200, [{"popular": ["web"]}, {"recommended": ["reading", "web"]}]
                )
        self.send(404, b"")


SERVER = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
threading.Thread(target=SERVER.serve_forever, daemon=True).start()
API = f"http://127.0.0.1:{SERVER.server_address[1]}/v1/"
