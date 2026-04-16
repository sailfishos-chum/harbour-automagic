# -*- coding: utf-8 -*-
import os
import json
import socket
import threading
import shutil
import secrets
from datetime import date
from typing import Any, Dict
import pyotherside

class Automagic:
  def __init__(self):
    print('Automagic init')
    self.config_path = os.environ['HOME'] + "/.config/app.qml/automagic/"
    self.socket_path = "/run/automagicd/automagicd.sock"
    self.secret = ""
    self._listening = False

  def loadVersioned(self, filename: str, default = []) -> Dict[str, Any]:
    path = os.path.join(self.config_path, filename)
    try:
      with open(path, 'r') as f:
        content = json.load(f)
        return content.get("data", [])
    except Exception as e:
      print(f"Error loading {filename}: {e}")
      return default

  def _sort_items(self, items: Any) -> Any:
    if not isinstance(items, list):
      return items
        
    return sorted(
      items, 
      key=lambda x: str(x.get("name") or "").lower()
    )

  def load_data(self) -> Dict[str, Any]:
    print('Automagic loading data')
    
    secret = self.loadVersioned("secret.json", {})
    if isinstance(secret, dict):
      self.secret = secret.get("shared_secret", "automagicd")

    return {
      "settings": self.loadVersioned("settings.json", {}),
      "data_sources": self._sort_items(self.loadVersioned("data_sources.json")),
      "flows": self._sort_items(self.loadVersioned("flows.json")),
      "actions": self._sort_items(self.loadVersioned("actions.json")),
      "value_maps": self.loadVersioned("value_maps.json", {})
    }

  def ensure_configs_exist(self):
    print('Automagic checking config directory and bootstrap files')
    os.makedirs(self.config_path, exist_ok=True)
    
    secret_path = os.path.join(self.config_path, "secret.json")
    new_secret = secrets.token_hex(16)
    secret_str = ""
    if os.path.exists(secret_path):
      secret = self.loadVersioned("secret.json", {})
      if isinstance(secret, dict):
        secret_str = secret.get("shared_secret", "automagicd")

    if not os.path.exists(secret_path) or secret_str == "":
      try:
        with open(secret_path, "w") as f:
          json.dump({"version": 1, "data": {"shared_secret": new_secret}}, f, indent=2)
        print("Created default secret.json")
      except Exception as e:
        print(f"Error creating secret.json: {e}")

    script_dir = os.path.dirname(os.path.abspath(__file__))
    examples_dir = os.path.join(script_dir, "..", "examples")
    target_files = ["flows.json", "actions.json", "data_sources.json", "value_maps.json"]
    
    if os.path.exists(examples_dir):
      for file_name in target_files:
        target_path = os.path.join(self.config_path, file_name)
        example_path = os.path.join(examples_dir, file_name)
        
        if not os.path.exists(target_path) and os.path.exists(example_path):
          try:
            shutil.copy2(example_path, target_path)
            print(f"Bootstrapped {file_name} from examples.")
          except Exception as e:
            print(f"Failed to copy {file_name}: {e}")
    else:
      print(f"Examples directory not found at {examples_dir}. Skipping examples.")

  def start(self):
    print('Automagic start')
    self.ensure_configs_exist()
    if not self.secret:
      self.load_data()
      
    if not self._listening:
      self._listening = True
      threading.Thread(target=self._broadcast_listener, daemon=True).start()
    pyotherside.send("progress", "automagic", "start", "ready")

  def stop(self):
    print('Automagic stop')
    self._listening = False
    pyotherside.send("progress", "automagic", "stop", "ended")

  def _broadcast_listener(self):
    import sys
    import time
    print("Starting broadcast listener thread...")
    sys.stdout.flush()
    
    while self._listening:
      try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
          s.connect(self.socket_path)
          s.sendall((json.dumps({"secret": self.secret}) + "\n").encode("utf-8"))

          pyotherside.send("progress", "automagic", "listener", "connected")
          
          f = s.makefile('r', encoding='utf-8')
          auth_data = f.readline()
          
          if not auth_data:
            print("Daemon closed connection during handshake. Retrying in 2s...")
            pyotherside.send("progress", "automagic", "listener", "disconnected")
            sys.stdout.flush()
            time.sleep(2)
            continue

          auth_resp = json.loads(auth_data)
          if not auth_resp.get("ok"):
            print(f"Listener auth failed: {auth_resp.get('error')}")
            sys.stdout.flush()
            self._listening = False
            pyotherside.send("error", "automagic", "listener", auth_resp.get("error"))
            return

          s.sendall((json.dumps({"cmd": "listen"}) + "\n").encode("utf-8"))
          listen_data = f.readline()
          
          if not listen_data:
            print("Daemon closed connection during listen request. Retrying in 2s...")
            pyotherside.send("progress", "automagic", "listener", "disconnected")
            sys.stdout.flush()
            time.sleep(2)
            continue
            
          listen_resp = json.loads(listen_data)
          if not listen_resp.get("ok"):
            print(f"Listen request failed: {listen_resp.get('error')}")
            sys.stdout.flush()
            time.sleep(2)
            continue

          print("Listener successfully authenticated and waiting for events...")
          sys.stdout.flush()

          for line in f:
            if not self._listening:
              break
            if line.strip():
              payload = json.loads(line.strip())
              p_type = payload.get("type")
              
              if p_type == "state_update":
                pyotherside.send("state_changed", payload.get("key"), payload.get("value"))
              elif p_type == "log":
                pyotherside.send("log_received", payload.get("flow_id"), payload.get("step_id"), payload.get("run_id"), payload.get("message"))

      except Exception as e:
        if self._listening:
          print(f"Listener disconnected ({e}). Reconnecting in 2s...")
          pyotherside.send("progress", "automagic", "listener", "disconnected")
          sys.stdout.flush()
          time.sleep(2)
          
    print("Broadcast listener thread cleanly exited.")
    pyotherside.send("progress", "automagic", "listener", "disconnected")
    sys.stdout.flush()

  def _send(self, payload: Dict[str, Any]) -> Dict[str, Any]:
    try:
      with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(2.0)
        s.connect(self.socket_path)
        
        s.sendall((json.dumps({"secret": self.secret}) + "\n").encode("utf-8"))
        f = s.makefile('r', encoding='utf-8')
        
        auth_data = f.readline()
        if not auth_data:
          return {"ok": False, "error": "connection closed during auth"}

        s.sendall((json.dumps(payload) + "\n").encode("utf-8"))
        
        resp_data = f.readline()
        if not resp_data:
          return {"ok": False, "error": "connection closed during response"}
          
        return json.loads(resp_data)
    except Exception as e:
      print("_send error:", e)
      return {"ok": False, "error": str(e)}

  def get_states(self) -> Dict[str, Any]:
    result = self._send({"cmd": "get_states"})
    return result.get("states", {})

  def exec_trigger(self, trigger_id):
    payload = {"cmd": "trigger", "trigger": trigger_id, "vars": {}}
    result = self._send(payload)
    print("exec_trigger:", result)
    return True

  def exec_flow(self, flow_id):
    payload = {"cmd": "execute_flow", "flow": flow_id, "vars": {}}
    result = self._send(payload)
    print("exec_flow:", result)
    return True

  def daemon_reload(self):
    payload = {"cmd": "reload" }
    result = self._send(payload)
    print("daemon_reload:", result)
    return True

  def get_templates(self):
    current_year = date.today().year

    return {
      "version": 1,
      "ui_schema": {
        "step_types": {
          "throttle": {
            "name": "Throttle",
            "fields": [
              { "key": "duration", "label": "Duration", "ui_type": "string", "default": "30s" },
              { "key": "scope", "label": "Scope", "ui_type": "array", "default": [""] }
            ]
          },
          "wait": {
            "name": "Wait",
            "fields": [
              { "key": "duration", "label": "Duration", "ui_type": "string", "default": "1s" }
            ]
          },
          "round": {
            "name": "Round",
            "fields": [
              { "key": "in", "label": "Input Variable", "ui_type": "string", "default": "" },
              { "key": "out", "label": "Output Variable", "ui_type": "string", "default": "" },
              { "key": "decimals", "label": "Decimal Places", "ui_type": "number", "default": 0, "placeholder": "0" }
            ]
          },
          "math": {
            "name": "Math",
            "fields": [
              { "key": "in", "label": "Expression", "ui_type": "string", "default": "", "placeholder": "{{a}} + {{b}}" },
              { "key": "out", "label": "Output Variable", "ui_type": "string", "default": "", "placeholder": "c" },
            ]
          },
          "action_log": {
            "name": "Log Message",
            "fields": [
              { "key": "message", "label": "Message", "ui_type": "string", "placeholder": "Hello World" }
            ]
          },
          "action_set_state": {
            "name": "Set Internal State",
            "fields": [
              { "key": "name", "label": "State Name", "ui_type": "string", "placeholder": "e.g., lamp_status" },
              [
                { "key": "static", "label": "Static Value", "ui_type": "string", "placeholder": "static value" },
                { "key": "variable", "label": "Variable Name", "ui_type": "string", "placeholder": "variable name" },
                { "key": "template", "label": "Template", "ui_type": "string", "placeholder": "{{temp}} °C" }
              ]
            ]
          },
          "action_set_variable": {
            "name": "Set Flow Variable",
            "fields": [
              { "key": "name", "label": "Variable Name", "ui_type": "string", "placeholder": "e.g., initial_value" },
              [
                { "key": "static", "label": "Static Value", "ui_type": "string", "placeholder": "static value" },
                { "key": "variable", "label": "Variable Name", "ui_type": "string", "placeholder": "variable name" },
                { "key": "template", "label": "Template", "ui_type": "string", "placeholder": "{{temp}} °C" }
              ]
            ]
          },
          
          
          "get_time": {
            "name": "System Time",
            "fields": []
          },
          "get_device": {
            "name": "Device Info",
            "fields": []
          },
          "get_random": {
            "name": "Random Number",
            "fields": []
          },
          "get_darkness": {
            "name": "Sunrise/Sunset Calculations",
            "fields": [
              { "key": "latitude", "label": "Latitude", "ui_type": "number", "placeholder": "53.48114" },
              { "key": "longitude", "label": "Longitude", "ui_type": "number", "placeholder": "-2.23707" }
            ]
          },
          "get_state": {
            "name": "Get Internal State",
            "fields": [
              { "key": "name", "label": "State Name", "ui_type": "string", "placeholder": "e.g., temp_status" }
            ]
          },
          "string_uppercase": {
            "name": "Convert to Uppercase",
            "fields": [
              { "key": "in", "label": "Input Template", "ui_type": "string", "default": "" },
              { "key": "out", "label": "Output Variable", "ui_type": "string", "default": "" }
            ]
          },          
          "string_lowercase": {
            "name": "Convert to Lowercase",
            "fields": [
              { "key": "in", "label": "Input Template", "ui_type": "string", "default": "" },
              { "key": "out", "label": "Output Variable", "ui_type": "string", "default": "" }
            ]
          },
          "string_trim": {
            "name": "Trim Whitespace",
            "fields": [
              { "key": "in", "label": "Input Template", "ui_type": "string", "default": "" },
              { "key": "out", "label": "Output Variable", "ui_type": "string", "default": "" }
            ]
          },
          "string_replace": {
            "name": "Text Replace",
            "fields": [
              { "key": "in", "label": "Input Template", "ui_type": "string", "default": "" },
              { "key": "search", "label": "Text to Find", "ui_type": "string", "default": "" },
              { "key": "replace", "label": "Replace With", "ui_type": "string", "default": "" },
              { "key": "out", "label": "Output Variable", "ui_type": "string", "default": "" }
            ]
          },
          "string_regex_replace": {
            "name": "Regex Replace",
            "fields": [
              { "key": "in", "label": "Input Template", "ui_type": "string", "default": "" },
              { "key": "pattern", "label": "Regex Pattern", "ui_type": "string", "default": "" },
              { "key": "replace", "label": "Replace With", "ui_type": "string", "default": "" },
              { "key": "out", "label": "Output Variable", "ui_type": "string", "default": "" }
            ]
          }
        },
        
        "action_types": {
          "sqlite_query": {
            "name": "SQLite Query",
            "fields": [
              { "key": "path", "label": "Database Path", "ui_type": "string", "placeholder": "/home/defaultuser/auto.db" },
              { "key": "query", "label": "SQL Query", "ui_type": "string", "placeholder": "INSERT INTO..."  }
            ]
          },
          "mysql_query": {
            "name": "MySQL Query",
            "fields": [
              { "key": "address", "label": "Database Address", "ui_type": "string", "placeholder": "192.168.0.1" },
              { "key": "database", "label": "Database", "ui_type": "string", "placeholder": "sensordata" },
              { "key": "username", "label": "Username", "ui_type": "string", "placeholder": "username" },
              { "key": "password", "label": "Password", "ui_type": "string", "placeholder": "password" },
              { "key": "query", "label": "SQL Query", "ui_type": "string", "placeholder": "INSERT INTO..."  }
            ]
          },
          "http": {
            "name": "HTTP Request",
            "fields": [
              { "key": "address", "label": "URL", "ui_type": "string", "placeholder": "https://qml.app" },
              { "key": "method", "label": "Method", "ui_type": "string", "default": "POST", "options": [
                  { "value": "GET", "label": "GET" },
                  { "value": "POST", "label": "POST" },
                  { "value": "PUT", "label": "PUT" },
                  { "value": "DELETE", "label": "DELETE" },
                  { "value": "PATCH", "label": "PATCH" }
                ]
              },
              { "key": "insecure", "label": "Ignore Certificate", "ui_type": "boolean", "default": False, "options": [
                  { "value": False, "label": "No" },
                  { "value": True, "label": "Yes" }
                ] 
              },
              { "key": "username", "label": "Username", "ui_type": "string" },
              { "key": "password", "label": "Password", "ui_type": "password" },
              { "key": "content_type", "label": "Content-Type", "ui_type": "string", "default": "application/json" },
              { "key": "payload", "label": "Payload", "ui_type": "string" },
              { "key": "timeout", "label": "Timeout", "ui_type": "string", "placeholder": "10s" }
            ]
          },
          "mqtt_publish": {
            "name": "MQTT Publisher",
            "fields": [
              { "key": "address", "label": "Broker Address", "ui_type": "string", "placeholder": "127.0.0.1:1883" },
              { "key": "username", "label": "Username", "ui_type": "string", "placeholder": "username" },
              { "key": "password", "label": "Password", "ui_type": "string", "placeholder": "password" },
              { "key": "topic", "label": "Topic", "ui_type": "string", "placeholder": "sensors/#" },
              { "key": "payload", "label": "Payload", "ui_type": "string", "default": "{{payload}}",  "placeholder": "payload"},
              { "key": "qos", "label": "Quality of Service", "ui_type": "number", "default": 0,  "options": [
                  { "value": 0, "label": "At most once" },
                  { "value": 1, "label": "At least once" },
                  { "value": 2, "label": "Exactly once" }
                ]
              },
              { "key": "retained", "label": "Retained", "ui_type": "boolean", "default": False,  "options": [
                  { "value": False, "label": "No" },
                  { "value": True, "label": "Yes" }
                ]
              }
            ]
          },
          "dbus_method": {
            "name": "DBus Method",
            "fields": [
              { "key": "address", "label": "Bus Address", "ui_type": "string", "placeholder": "system" },
              { "key": "destination", "label": "Destination", "ui_type": "string", "placeholder": "org.freedesktop.hostname1" },
              { "key": "path", "label": "Object Path", "ui_type": "string", "placeholder": "/org/freedesktop/hostname1" },
              { "key": "interface", "label": "Interface", "ui_type": "string", "placeholder": "org.freedesktop.DBus.Properties" },
              { "key": "method", "label": "Method", "ui_type": "string", "placeholder": "Set" },
              { "key": "timeout", "label": "Timeout", "ui_type": "string", "placeholder": "2s" }
            ]
          },
          "write_data": { "name": "Write Data Record", 
            "fields": [
              { "key": "key", "label": "Message", "ui_type": "string", "default": "message", "placeholder": "message" },
              { "key": "value", "label": "Variable", "ui_type": "string", "default": "message", "placeholder": "message" },
            ] 
          },
          "log": {
            "name": "Log Message",
            "fields": [
              { "key": "message", "label": "Message", "ui_type": "string" },
            ]
          },
          "smtp": {
            "name": "Send Email (SMTP)",
            "fields": [
              { "key": "address", "label": "SMTP Host:Port", "ui_type": "string" },
              { "key": "username", "label": "Username", "ui_type": "string" },
              { "key": "password", "label": "Password", "ui_type": "password" },
              { "key": "from", "label": "From Address", "ui_type": "string" },
              { "key": "to", "label": "To Address(es)", "ui_type": "string" },
              { "key": "bcc", "label": "BCC Address(es)", "ui_type": "string" },
              { "key": "subject", "label": "Subject", "ui_type": "string" },
              { "key": "body", "label": "Message Body", "ui_type": "text" }
            ]
          },
          "imap_mark_seen": {
            "name": "Mark Email as Read",
            "fields": [
              { "key": "address", "label": "IMAP Host:Port", "ui_type": "string" },
              { "key": "username", "label": "Username", "ui_type": "string" },
              { "key": "password", "label": "Password", "ui_type": "password" },
              { "key": "path", "label": "Mailbox", "ui_type": "string", "default": "INBOX" },
              { "key": "payload", "label": "Message UID (Optional)", "ui_type": "string", "default": "" },
              { "key": "insecure", "label": "Ignore Certificate", "ui_type": "boolean", "default": False, "options": [
                  { "value": False, "label": "No" },
                  { "value": True, "label": "Yes" }
                ] 
              }
            ]
          },
          "shell": {
            "name": "Shell",
            "fields": [
              { "key": "command", "label": "Command", "ui_type": "string" },
            ]
          }
        },

        "source_types": {
          "timer": {
            "name": "Timer",
            "fields": [
              { "key": "interval", "label": "Interval", "ui_type": "string", "placeholder": "30s" },
              { "key": "initial_delay", "label": "Initial Delay", "ui_type": "string", "placeholder": "1s" },
              { "key": "schedule_seconds", "label": "Seconds", "ui_type": "array_integer", "default": [] },
              { "key": "schedule_minutes", "label": "Minutes", "ui_type": "array_integer", "default": [] },
              { "key": "schedule_hours", "label": "Hours", "ui_type": "array_integer", "default": [] },
              { "key": "schedule_weekdays", "label": "Weekdays (0=Sun, 6=Sat)", "ui_type": "array_integer", "default": [] },
              { "key": "schedule_days", "label": "Days", "ui_type": "array_integer", "default": [] },
              { "key": "schedule_months", "label": "Months", "ui_type": "array_integer", "default": [] },
              { "key": "schedule_years", "label": "Years", "ui_type": "array_integer", "default": [], "placeholder": "%s,%s,%s" % (current_year-1, current_year, current_year+1) }
            ],
            "output_label": "Output Variables",
            "output_hint": "trigger_time, trigger_source, epoch, hour, minute, second, date, time, weekday, weekday_name, day, month, month_name, year",
            "trigger_mode": "always"
          },
          "mqtt": {
            "name": "MQTT Sensor",
            "fields": [
              { "key": "address", "label": "Broker Address", "ui_type": "string", "placeholder": "127.0.0.1:1883" },
              { "key": "topic", "label": "Topic", "ui_type": "string", "placeholder": "sensors/#" },
              { "key": "username", "label": "Username", "ui_type": "string", "placeholder": "username" },
              { "key": "password", "label": "Password", "ui_type": "string", "placeholder": "password" },
              { "key": "format", "label": "Payload Format", "ui_type": "string", "default": "json", "options": [
                  { "value": "raw", "label": "Raw String" },
                  { "value": "json", "label": "JSON Object" },
                  { "value": "split", "label": "Split by Delimiter" },
                  { "value": "regex", "label": "Regex Match" },
                  { "value": "conf", "label": "Config File" },
                  { "value": "none", "label": "No Parsing" }
                ]
              },
              { "key": "pattern", "label": "Regex Pattern", "ui_type": "string", "placeholder": "(?P<name>\\\\d+)" },
              { "key": "delimiter", "label": "Delimiter", "ui_type": "string", "placeholder": "\n" }
            ],
            "output_label": "Output",
            "output_hint": "_topic | arg0-n | json keys | config file keys",
            "trigger_mode": "always"
          },
          "http": {
            "name": "HTTP Request",
            "fields": [
              { "key": "address", "label": "URL", "ui_type": "string", "placeholder": "https://qml.app" },
              { "key": "method", "label": "Method", "ui_type": "string", "default": "GET", "options": [
                  { "value": "GET", "label": "GET" },
                  { "value": "POST", "label": "POST" },
                  { "value": "PUT", "label": "PUT" },
                  { "value": "DELETE", "label": "DELETE" },
                  { "value": "PATCH", "label": "PATCH" }
                ] 
              },
              { "key": "insecure", "label": "Ignore Certificate", "ui_type": "boolean", "default": False, "options": [
                  { "value": False, "label": "No" },
                  { "value": True, "label": "Yes" }
                ] 
              },
              { "key": "username", "label": "Username", "ui_type": "string" },
              { "key": "password", "label": "Password", "ui_type": "password" },
              { "key": "content_type", "label": "Content-Type", "ui_type": "string", "default": "application/json" },
              { "key": "payload", "label": "Request Payload", "ui_type": "string" },
              { "key": "timeout", "label": "Timeout", "ui_type": "string", "placeholder": "10s" },
              { "key": "format", "label": "Result Payload Format", "ui_type": "string", "default": "json", "options": [
                  { "value": "raw", "label": "Raw String" },
                  { "value": "json", "label": "JSON Object" },
                  { "value": "split", "label": "Split by Delimiter" },
                  { "value": "regex", "label": "Regex Match" },
                  { "value": "conf", "label": "Config File" },
                  { "value": "none", "label": "No Parsing" }
                ]
              },
              { "key": "pattern", "label": "Regex Pattern", "ui_type": "string", "placeholder": "(?P<name>\\\\d+)" },
              { "key": "delimiter", "label": "Delimiter", "ui_type": "string", "placeholder": "\n" }
            ],
            "output_label": "Output",
            "output_hint": "arg0-n | json keys | config file keys",
            "trigger_mode": "never"
          },
          "dbus": {
            "name": "DBus Connection",
            "fields": [
              { "key": "address", "label": "Bus Address", "ui_type": "string", "placeholder": "unix:path=/run/user/100000/dbus/user_bus_socket" },
              { "key": "destination", "label": "Destination", "ui_type": "string", "placeholder": "org.freedesktop.hostname1" },
              { "key": "path", "label": "Object Path", "ui_type": "string", "placeholder": "/org/freedesktop/hostname1" },
              { "key": "interface", "label": "Interface", "ui_type": "string", "placeholder": "org.freedesktop.DBus.Properties" },
              { "key": "method", "label": "Method", "ui_type": "string", "placeholder": "Get" },
              { "key": "signal", "label": "Signal", "ui_type": "string", "placeholder": "PropertiesChanged" }
            ],
            "output_label": "Output",
            "output_hint": "arg0-n",
            "trigger_mode": "optional"
          },
          "file": {
            "name": "File",
            "fields": [
              { "key": "path", "label": "File Path", "ui_type": "string", "placeholder": "/proc/sys/kernel/hostname" },
              { "key": "format", "label": "Payload Format", "ui_type": "string", "default": "json", "options": [
                  { "value": "raw", "label": "Raw String" },
                  { "value": "json", "label": "JSON Object" },
                  { "value": "split", "label": "Split by Delimiter" },
                  { "value": "regex", "label": "Regex Match" },
                  { "value": "conf", "label": "Config File" },
                  { "value": "none", "label": "No Parsing" }
                ]
              },
              { "key": "pattern", "label": "Regex Pattern", "ui_type": "string", "placeholder": "(?P<name>\\\\d+)" },
              { "key": "delimiter", "label": "Delimiter", "ui_type": "string", "placeholder": "\n" }
            ],
            "output_label": "Output",
            "output_hint": "exists, size, base_name, is_directory, modify_time, mode, permissions | arg0-n | json keys | config file keys",
            "trigger_mode": "optional"
          },
          "sqlite": {
            "name": "SQLite",
            "fields": [
              { "key": "path", "label": "Database Path", "ui_type": "string", "placeholder": "/home/defaultuser/auto.db" },
              { "key": "query", "label": "SELECT Query", "ui_type": "string", "placeholder": "SELECT sold, total FROM phone_stats LIMIT 1"}
            ],
            "output_label": "Output",
            "output_hint": "column names",
            "trigger_mode": "never"
          },
          "mysql": {
            "name": "MySQL",
            "fields": [
              { "key": "address", "label": "Database Address", "ui_type": "string", "placeholder": "192.168.0.1" },
              { "key": "database", "label": "Database", "ui_type": "string", "placeholder": "sensordata" },
              { "key": "username", "label": "Username", "ui_type": "string", "placeholder": "username" },
              { "key": "password", "label": "Password", "ui_type": "string", "placeholder": "password" },
              { "key": "query", "label": "SQL Query", "ui_type": "string", "placeholder": "INSERT INTO..."  }
            ],
            "output_label": "Output",
            "output_hint": "column names",
            "trigger_mode": "never"
          },
          "state": {
            "name": "State",
            "fields": [

            ],
            "output_label": "Output Variables",
            "output_hint": "state_key, state_value",
            "trigger_mode": "optional"
          },
          "imap": {
            "name": "IMAP Inbox",
            "fields": [
              { "key": "address", "label": "IMAP Host:Port", "ui_type": "string" },
              { "key": "username", "label": "Username", "ui_type": "string" },
              { "key": "password", "label": "Password", "ui_type": "password" },
              { "key": "path", "label": "Mailbox", "ui_type": "string", "default": "INBOX" },
              { "key": "insecure", "label": "Ignore Certificate", "ui_type": "boolean", "default": False, "options": [
                  { "value": False, "label": "No" },
                  { "value": True, "label": "Yes" }
                ] 
              },
              { "key": "format", "label": "Payload Format", "ui_type": "string", "default": "split", "options": [
                  { "value": "raw", "label": "Raw String" },
                  { "value": "json", "label": "JSON Object" },
                  { "value": "split", "label": "Split by Delimiter" },
                  { "value": "regex", "label": "Regex Match" },
                  { "value": "conf", "label": "Config File" },
                  { "value": "none", "label": "No Parsing" }
                ]
              },
              { "key": "pattern", "label": "Regex Pattern", "ui_type": "string", "placeholder": "(?P<name>\\\\d+)" },
              { "key": "delimiter", "label": "Delimiter", "ui_type": "string", "placeholder": "\n", "default": "\n" }
            ],
            "output_label": "Output",
            "output_hint": "has_message, uid, subject, date, message_id, remaining, from_email, from_name, to_email, to_name | text/plain/arg0-n | text/html/arg0-n | ...",
            "trigger_mode": "never"
          },
          "location": {
            "name": "Location",
            "fields": [
              { "key": "interval", "label": "Interval", "ui_type": "string", "placeholder": "30s" },
              { "key": "cache_ttl", "label": "Cache Time To Live", "ui_type": "string", "placeholder": "60s" }
            ],
            "output_label": "Output Variables",
            "output_hint": "latitude, longitude, altitude, accuracy, vertical_accuracy, timestamp, provider",
            "trigger_mode": "optional"
          }
        }
      }
    }

  def save_text_file(self, file_name_or_path, data):
    try:
      if os.path.isabs(file_name_or_path):
        target_path = file_name_or_path
      else:
        target_path = os.path.join(self.config_path, file_name_or_path)

      os.makedirs(os.path.dirname(target_path), exist_ok=True)

      with open(target_path, 'w') as f:
        f.write(data)
      
      print(f"File saved successfully: {target_path}")
      pyotherside.send("success", "automagic", "save_text_file", f"File Saved")

    except Exception as err:
      error_msg = str(err)
      print(f"Settings save_text_file error: {error_msg}")
      pyotherside.send("error", "automagic", "save_text_file", error_msg)

automagic_object = Automagic()


