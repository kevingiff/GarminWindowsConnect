import json
import os
import subprocess
import sys
import threading
import time
import requests
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

TOPIC_URL = os.getenv("NTFY_TOPIC_URL")

if not TOPIC_URL:
    print("[ERROR] Missing required environment variable (NTFY_TOPIC_URL). Check your .env file.", flush=True)
    sys.exit(1)

# Load actions configuration from config.json
CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")
try:
    with open(CONFIG_PATH, "r") as f:
        config_data = json.load(f)
        ACTIONS = config_data.get("ACTIONS", {})
except Exception as e:
    print(f"[ERROR] Failed to load config.json: {e}", flush=True)
    sys.exit(1)

# Concurrency lock & state flag
IS_LAUNCHING = False
lock = threading.Lock()


def run_action_sequence(action_details):
    action_name = action_details.get("name", "Unknown Action")
    batch_path = action_details.get("batch_path")
    target_process = action_details.get("target_process")
    poll_timeout = action_details.get("poll_timeout", 12)
    post_launch_delay = action_details.get("post_launch_delay", 0)
    send_keys = action_details.get("send_keys")

    try:
        print(f"Launching startup for {action_name}...", flush=True)
        subprocess.run([batch_path], check=True)
        print(f"Batch file for {action_name} executed successfully.", flush=True)

        if not target_process:
            print(f"[SUCCESS] {action_name} initialization completed (no process polling required).", flush=True)
            return

        # System Process Polling
        print(f"[STATUS] Polling system for process '{target_process}'...", flush=True)
        ps_check_command = f"Get-Process -Name '{target_process}' -ErrorAction SilentlyContinue"

        success = False
        for _ in range(poll_timeout):
            time.sleep(1)
            result = subprocess.run(["powershell", "-Command", ps_check_command], capture_output=True, text=True)
            if target_process.lower() in result.stdout.lower():
                success = True
                print(f"[STATUS] Confirmed process '{target_process}' is running.", flush=True)
                break

        if success:
            if post_launch_delay > 0:
                print(f"[STATUS] Waiting {post_launch_delay} seconds before secondary action...", flush=True)
                time.sleep(post_launch_delay)

            if send_keys:
                print(f"[STATUS] Sending automated keystrokes to '{target_process}'...", flush=True)
                ps_click_command = (
                    f"$wshell = New-Object -ComObject wscript.shell; "
                    f"if ($wshell.AppActivate('{target_process}')) {{ Start-Sleep -Milliseconds 200; $wshell.SendKeys('{send_keys}') }}"
                )
                subprocess.run(["powershell", "-Command", ps_click_command])
                print(f"[SUCCESS] Secondary action sequence for {action_name} completed.", flush=True)
            else:
                print(f"[SUCCESS] {action_name} successfully initialized.", flush=True)
        else:
            print(f"[WARNING] Batch executed, but process '{target_process}' was not detected within timeout.", flush=True)

    except Exception as e:
        print(f"Error running action sequence for {action_name}: {e}", flush=True)
    finally:
        print("[DONE] Action sequence finished. Closing listener terminal...", flush=True)
        time.sleep(2)
        os._exit(0)


def listen_loop():
    global IS_LAUNCHING
    print("Connecting to configured secure ntfy.sh topic...", flush=True)
    first_connection = True

    while True:
        try:
            # 2-second timeout allows instant Ctrl+C check without spamming logs
            response = requests.get(TOPIC_URL, stream=True, timeout=2)

            if response.status_code == 200:
                if first_connection:
                    print("Connection established. Listening for Garmin triggers...", flush=True)
                    first_connection = False

            for line in response.iter_lines():
                if line:
                    event = json.loads(line.decode("utf-8"))
                    if event.get("event") == "message":
                        msg = event.get("message", "").strip()
                        print(f"[DEBUG] Received message payload: '{msg}'", flush=True)

                        matched_action = None
                        for token, details in ACTIONS.items():
                            if msg == token or msg == f"message={token}" or token in msg:
                                matched_action = details
                                break

                        if matched_action:
                            print(f"[RECEIVED] Message received: success ({matched_action['name']})", flush=True)

                            with lock:
                                if IS_LAUNCHING:
                                    print("[IGNORED] Launch sequence already in progress. Duplicate pub ignored.", flush=True)
                                    continue
                                IS_LAUNCHING = True

                            print(f"[ACK] Triggering action sequence for: {matched_action['name']}", flush=True)
                            
                            threading.Thread(target=run_action_sequence, args=(matched_action,)).start()
                            return

                        else:
                            print(f"Ignored unauthorized message.", flush=True)

        except (requests.exceptions.Timeout, requests.exceptions.ChunkedEncodingError, requests.exceptions.ConnectionError):
            # Silent background loop check for Ctrl+C and stream keepalive (no annoying prints)
            continue
        except Exception as e:
            print(f"Connection dropped ({e}). Retrying...", flush=True)
            time.sleep(2)


if __name__ == "__main__":
    try:
        listen_loop()
    except KeyboardInterrupt:
        print("\n[INFO] Listener stopped by user (Ctrl+C). Exiting...", flush=True)
        sys.exit(0)