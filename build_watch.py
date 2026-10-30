import os
import json
from dotenv import load_dotenv

load_dotenv()

TOPIC_URL = os.getenv("NTFY_TOPIC_URL", "https://ntfy.sh/DEFAULT_TOPIC/json")
# Default fallback coordinates (Denver area) if not specified
TARGET_LAT = float(os.getenv("TARGET_LAT", "39.794058"))
TARGET_LON = float(os.getenv("TARGET_LON", "-105.008369"))

CONFIG_PATH = os.path.join(os.path.dirname(__file__), "config.json")

def generate_monkey_c():
    actions = {}
    radius_meters = 2414.0 # Default 1.5 miles

    if os.path.exists(CONFIG_PATH):
        try:
            with open(CONFIG_PATH, "r") as f:
                config_data = json.load(f)
                actions = config_data.get("ACTIONS", {})
                geo_config = config_data.get("GEO_FENCING", {})
                radius_meters = float(geo_config.get("radius_meters", 2414.0))
        except Exception as e:
            print(f"[WARNING] Could not read config.json: {e}")

    # Generate Monkey C code dynamically
    mc_lines = [
        "// AUTO-GENERATED FILE BY build_watch.py. DO NOT EDIT DIRECTLY.",
        "import Toybox.Lang;",
        "import Toybox.WatchUi;",
        "",
        "module GeneratedConfig {",
        f'    public const WEBHOOK_URL as String = "{TOPIC_URL}";',
        f'    public const TARGET_LAT as Double = {TARGET_LAT}d;',
        f'    public const TARGET_LON as Double = {TARGET_LON}d;',
        f'    public const RADIUS_METERS as Float = {radius_meters}f;',
        "",
        "    public function populateMenu(menu as WatchUi.Menu2) as Void {",
    ]

    # Map dynamic actions into the menu
    idx = 0
    for secret_token, details in actions.items():
        name = details.get("name", f"Action {idx+1}")
        mc_lines.append(f'        menu.addItem(new WatchUi.MenuItem("{name}", "Trigger", :action_{idx}, {{}}));')
        idx += 1

    mc_lines.extend([
        "    }",
        "",
        "    public function getPayload(id as Symbol) as String {",
    ])

    idx = 0
    for secret_token in actions.keys():
        mc_lines.append(f'        if (id == :action_{idx}) {{ return "{secret_token}"; }}')
        idx += 1

    mc_lines.extend([
        '        return "";',
        "    }",
        "}"
    ])

    output_path = os.path.join(os.path.dirname(__file__), "app", "source", "GeneratedConfig.mc")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(output_path, "w") as f:
        f.write("\n".join(mc_lines))
    
    print(f"[SUCCESS] Generated {output_path} with {idx} configured action(s) and {radius_meters}m geofence radius.")

if __name__ == "__main__":
    generate_monkey_c()