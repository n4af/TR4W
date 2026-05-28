#!/usr/bin/env python3
"""
hamscore_mock.py -- Local stand-in for the HamScore RTC server.

Listens on http://localhost:8765/ (any path). Logs every POST: client
address, decoded Basic-auth credentials, headers, raw XML body, and a
pretty-printed parsed form so you can visually verify the CabrilloString
value and other RTC 3.0 fields without making a round-trip to
hamscore.com / scoredistributor.net.

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

RTC 3.0 (issue #920) added a "Description" field that the server uses to
attach warnings to CFM responses or details to errors. Set --description
"<text>" to exercise TR4W's Description extraction path. Examples:
   --response CFM   --description "Warning! Exchange error"
   --response Error --description "Bad credentials"

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

# Module-level so the CLI can set them once and every request handler reads.
RESPONSE_STATUS = "CFM"
RESPONSE_DESCRIPTION = ""


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
      # RTC 3.0 (issue #920) wraps everything in a single <rtc> root, so
      # the wrapper-strip dance is no longer strictly needed; we keep it
      # anyway as a graceful fallback when the payload is missing <rtc>
      # (e.g. older TR4W builds or third-party clients posting fragments).
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

      # Inline highlights -- RTC 3.0 contactinfo carries just <ID>,
      # <CabrilloString>, <timestamp>, plus the <contest> child of
      # <deletelog>.  Show those plus the dynamicresults <score>/<call>
      # for at-a-glance verification.  Also flag the <rtc> wrapper so
      # the operator can confirm the post is 3.0-shaped.
      print("-" * 72)
      print("Highlights (RTC 3.0 fields):")
      found_any = False
      has_rtc_wrapper = bool(re.search(r"<rtc\b", body_text))
      print(f"   <rtc> wrapper  {'present' if has_rtc_wrapper else 'MISSING (pre-3.0?)'}")
      for tag in ("ID", "CabrilloString", "timestamp", "contest",
                  "call", "score", "soft", "version"):
         for m in re.finditer(rf"<{tag}\b[^>]*>(.*?)</{tag}>",
                              body_text, re.DOTALL):
            print(f"   {tag:<14} {m.group(1).strip()!r}")
            found_any = True
      if not found_any:
         print("   (no tags of interest found)")

      # JSON response per the protocol TR4W parses
      # (uHamScore.pas ResponseStatusKind + ExtractDescription).
      # Case-sensitive "Status" key.  Add Description when set so the
      # CFM-with-warning and Error-with-detail paths can be exercised.
      if RESPONSE_DESCRIPTION:
         # Escape minimal JSON chars so common test strings work.
         desc = (RESPONSE_DESCRIPTION
                 .replace("\\", "\\\\")
                 .replace('"', '\\"'))
         response_body = (
            f'{{"Status":"{RESPONSE_STATUS}",'
            f'"Description":"{desc}",'
            f'"TimeStamp":"{dt.datetime.utcnow():%Y-%m-%d %H:%M:%S}"}}\n'
         )
      else:
         response_body = f'{{"Status":"{RESPONSE_STATUS}"}}\n'
      response = response_body.encode("utf-8")
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
   global RESPONSE_STATUS, RESPONSE_DESCRIPTION
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
   p.add_argument("--description", default="",
                  help="Optional Description field included in the JSON "
                       "response.  RTC 3.0 uses it to attach warnings to "
                       "CFM (e.g. 'Warning! Exchange error') or detail to "
                       "Error.  Exercises ExtractDescription in "
                       "src/uHamScore.pas and the Settings status line.")
   args = p.parse_args()

   RESPONSE_STATUS = args.response
   RESPONSE_DESCRIPTION = args.description

   print(f"HamScore mock listening on http://{args.host}:{args.port}/")
   if RESPONSE_DESCRIPTION:
      print(f'Response status: {{"Status":"{RESPONSE_STATUS}",'
            f'"Description":"{RESPONSE_DESCRIPTION}"}}')
   else:
      print(f'Response status: {{"Status":"{RESPONSE_STATUS}"}}')
   print("Configure TR4W (in tr4w.ini or via the HAMSCORE commands):")
   print(f"   HAMSCORE URL               = http://{args.host}:{args.port}/postxml/index.php")
   print("   HAMSCORE USER              = anything (logged, not validated)")
   print("   HAMSCORE PASSWORD          = anything (logged, not validated)")
   print("   HAMSCORE ENABLE            = TRUE")
   print("   HAMSCORE SEND CONTACT INFO = TRUE  (issue #931 -- needed if you want")
   print("                                       per-QSO <contactinfo> posts, not")
   print("                                       just the <dynamicresults> score)")
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
