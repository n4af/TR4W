#!/usr/bin/env python3
"""
hamscore_mock.py -- Local stand-in for the HamScore RTC server.

Listens on http://localhost:8765/ (any path). Logs every POST: client
address, decoded Basic-auth credentials, headers, raw XML body, and a
pretty-printed parsed form so you can visually verify SentExchange /
RxExchange values without making a round-trip to hamscore.com.

Configure TR4W:
   HAMSCORE URL = http://localhost:8765/postxml/index.php
   HAMSCORE USER = anything
   HAMSCORE PASSWORD = anything

Returns 200 OK with a JSON body matching the protocol TR4W's HamScore
client expects (see ResponseStatusKind in src/uHamScore.pas):
   {"Status":"CFM"}       contacts confirmed -- queue cleared
   {"Status":"OK"}        accepted (server uses this for score-only posts;
                          TR4W only honours OK when its payload had no QSOs)
   {"Status":"ResyncLog"} server requests a full resync
   {"Status":"Error"}     server error
Anything else makes TR4W log "Unexpected response" and retain the QSOs
for retry. Default = CFM (success-with-QSOs path the RTC fix is testing).
Override with --response.

No external dependencies -- pure stdlib (http.server + xml.dom.minidom).
Tested on Python 3.8+.
"""

import argparse
import base64
import datetime as dt
import re
import sys
import urllib.parse
import xml.dom.minidom
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


SEP = "=" * 72


VALID_RESPONSES = ("CFM", "OK", "ResyncLog", "Error")

# Module-level so the CLI can set it once and every request handler reads it.
RESPONSE_STATUS = "CFM"


class HamScoreMockHandler(BaseHTTPRequestHandler):
   server_version = "HamScoreMock/0.2"

   def log_message(self, fmt, *args):
      # Silence the per-request access log; we print our own block.
      return

   def do_POST(self):
      length = int(self.headers.get("Content-Length", "0") or "0")
      body = self.rfile.read(length) if length > 0 else b""

      print(SEP)
      print(f"[{dt.datetime.now():%Y-%m-%d %H:%M:%S}] POST {self.path}")
      print(f"From: {self.client_address[0]}:{self.client_address[1]}")
      print("-" * 72)

      auth = self.headers.get("Authorization", "")
      if auth.startswith("Basic "):
         try:
            decoded = base64.b64decode(auth[6:]).decode("utf-8", errors="replace")
            print(f"Authorization: Basic  <{decoded}>")
         except Exception as e:
            print(f"Authorization: Basic  <decode-failed: {e}>")
      elif auth:
         print(f"Authorization: {auth}")
      else:
         print("Authorization: <none>")

      print(f"Content-Type:   {self.headers.get('Content-Type', '<none>')}")
      print(f"User-Agent:     {self.headers.get('User-Agent', '<none>')}")
      print(f"Content-Length: {length}")
      print("-" * 72)

      try:
         raw_text = body.decode("utf-8")
      except UnicodeDecodeError:
         raw_text = body.decode("utf-8", errors="replace")

      # N1MM percent-encodes the entire XML body and sends no Content-Type
      # header. TR4W sends raw XML with Content-Type: application/xml.
      # Detect form-encoding heuristically (Content-Type, or body starts
      # with %3C = encoded '<') and URL-decode for readable display.
      ctype = self.headers.get("Content-Type", "") or ""
      is_form_encoded = (
         "x-www-form-urlencoded" in ctype.lower()
         or raw_text[:10].count("%") >= 2
      )
      if is_form_encoded:
         body_text = urllib.parse.unquote(raw_text)
         print("Raw body (URL-encoded, as received):")
         print(raw_text if raw_text else "<empty>")
         print("-" * 72)
         print("URL-decoded body:")
         print(body_text if body_text else "<empty>")
      else:
         body_text = raw_text
         print("Raw body:")
         print(body_text if body_text else "<empty>")
      print("-" * 72)
      print("Pretty-printed:")
      # TR4W's HamScore payload is XML *fragments*, not a single-root
      # document -- e.g. <dynamicresults>...</dynamicresults> followed
      # by <deletelog></deletelog>. The real server tolerates this;
      # Python's xml.dom.minidom strict-parses and rejects it as
      # "junk after document element". Strip the XML declaration and
      # wrap in a synthetic root so pretty-printing works.
      try:
         stripped = re.sub(r"<\?xml[^>]*\?>\s*", "", body_text, count=1).strip()
         wrapped = f"<hamscoreMockRoot>{stripped}</hamscoreMockRoot>"
         dom = xml.dom.minidom.parseString(wrapped)
         pretty = dom.toprettyxml(indent="   ")
         # Strip the synthetic root we added + the XML declaration
         # minidom emits, and collapse minidom's extra blank lines.
         lines = [
            ln for ln in pretty.splitlines()
            if ln.strip()
               and "<hamscoreMockRoot" not in ln
               and "</hamscoreMockRoot>" not in ln
               and not ln.lstrip().startswith("<?xml")
         ]
         # Un-indent one level since we removed the wrapper.
         print("\n".join(ln[3:] if ln.startswith("   ") else ln for ln in lines))
      except Exception as e:
         print(f"(could not parse as XML: {e})")

      # Inline highlight of the two fields that matter for the RTC fix.
      print("-" * 72)
      print("Highlights (inline tag extracts):")
      found_any = False
      for tag in ("Call", "Mode", "Band", "SentExchange", "RxExchange", "Operator"):
         for m in re.finditer(rf"<{tag}>(.*?)</{tag}>", body_text, re.DOTALL):
            print(f"   {tag:<14} {m.group(1).strip()!r}")
            found_any = True
      if not found_any:
         print("   (no tags of interest found)")

      # JSON response per the protocol TR4W parses
      # (uHamScore.pas ResponseStatusKind). Case-sensitive "Status" key.
      response = f'{{"Status":"{RESPONSE_STATUS}"}}\n'.encode("utf-8")
      print(f"Responding: 200 OK  body={response.rstrip().decode()}")
      print(SEP)
      sys.stdout.flush()

      self.send_response(200)
      self.send_header("Content-Type", "application/json")
      self.send_header("Content-Length", str(len(response)))
      self.end_headers()
      self.wfile.write(response)

   def do_GET(self):
      # Health check + helpful message if the operator visits the URL.
      msg = (
         b"HamScore mock server is running.\n"
         b"POST your XML payload to this URL to see it logged.\n"
      )
      self.send_response(200)
      self.send_header("Content-Type", "text/plain; charset=utf-8")
      self.send_header("Content-Length", str(len(msg)))
      self.end_headers()
      self.wfile.write(msg)


def main() -> int:
   global RESPONSE_STATUS
   p = argparse.ArgumentParser(description="Local HamScore RTC mock server.")
   p.add_argument("--host", default="127.0.0.1",
                  help="Bind host (default 127.0.0.1). Use 0.0.0.0 to accept "
                       "from other machines on the LAN.")
   p.add_argument("--port", type=int, default=8765,
                  help="Bind port (default 8765).")
   p.add_argument("--response", default="CFM", choices=VALID_RESPONSES,
                  help="Status to return in the JSON body. CFM (default) = "
                       "QSOs confirmed -- TR4W clears its queue. OK = "
                       "accepted (only valid for score-only posts). "
                       "ResyncLog = ask client to resync. Error = server "
                       "error. Use these to exercise the four code paths "
                       "in src/uHamScore.pas:DoCycle.")
   args = p.parse_args()

   RESPONSE_STATUS = args.response

   print(f"HamScore mock listening on http://{args.host}:{args.port}/")
   print(f'Response status: {{"Status":"{RESPONSE_STATUS}"}}')
   print("Configure TR4W (in tr4w.ini or via the HAMSCORE commands):")
   print(f"   HAMSCORE URL      = http://{args.host}:{args.port}/postxml/index.php")
   print("   HAMSCORE USER     = anything (logged, not validated)")
   print("   HAMSCORE PASSWORD = anything (logged, not validated)")
   print("   HAMSCORE ENABLE   = TRUE")
   print("Press Ctrl+C to stop.")
   print()

   server = ThreadingHTTPServer((args.host, args.port), HamScoreMockHandler)
   try:
      server.serve_forever()
   except KeyboardInterrupt:
      print("\nShutting down.")
   finally:
      server.server_close()
   return 0


if __name__ == "__main__":
   sys.exit(main())
