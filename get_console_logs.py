import asyncio
import websockets
import json
import sys
import signal

# Chrome DevTools URL
WS_URL = "ws://127.0.0.1:39509/devtools/page/8550D3644FC1D459157CFCB6F771E1F7"

async def get_console_logs():
    async with websockets.connect(WS_URL) as ws:
        # Enable console domain
        await ws.send(json.dumps({
            "id": 1,
            "method": "Runtime.enable"
        }))
        
        await ws.send(json.dumps({
            "id": 2,
            "method": "Console.enable"
        }))
        
        # Get all console messages
        await ws.send(json.dumps({
            "id": 3,
            "method": "Runtime.runIfWaitingForDebugger"
        }))
        
        print("=" * 80)
        print("📱 CONSOLE LOGS FROM LAUNDRY28 WEB APP")
        print("=" * 80)
        print()
        
        log_count = 0
        try:
            while True:
                response = await asyncio.wait_for(ws.recv(), timeout=0.5)
                data = json.loads(response)
                
                # Filter for console messages
                if "method" in data:
                    if data["method"] == "Console.messageAdded":
                        msg = data["params"]["message"]
                        level = msg.get("level", "unknown")
                        text = msg.get("text", "")
                        timestamp = msg.get("timestamp", 0)
                        
                        # Format the log
                        prefix = {
                            "log": "📝",
                            "warning": "⚠️",
                            "error": "❌",
                            "debug": "🐛",
                            "info": "ℹ️"
                        }.get(level, "📌")
                        
                        print(f"{prefix} {text}")
                        log_count += 1
                        
                        # Also print any exception text
                        if msg.get("exceptionDetails"):
                            exc = msg["exceptionDetails"]
                            print(f"   ❌ Exception: {exc.get('exception', {}).get('description', 'Unknown')}")
                
                elif "result" in data:
                    # Response to our commands
                    if data.get("id") == 3:
                        result = data.get("result", {})
                        if result.get("result", {}).get("subtype") == "array":
                            arr = result.get("result", {}).get("value", [])
                            if arr:
                                print(f"\n📊 Found {len(arr['value'])} console messages already in buffer:\n")
                                for item in arr["value"]:
                                    if isinstance(item, dict) and item.get("type") == "object":
                                        obj = item.get("value", [{}])[0]
                                        if isinstance(obj, dict):
                                            text = obj.get("value", {}).get("value", "")
                                            level = obj.get("properties", [{}])[0].get("value", {}).get("value", "log")
                                            prefix = {"log": "📝", "warning": "⚠️", "error": "❌", "debug": "🐛"}.get(level, "📌")
                                            print(f"{prefix} {text}")
                                            log_count += 1
                        
                        print(f"\n📡 Listening for new console messages... (Ctrl+C to stop)")
                        print("=" * 80)
                
        except asyncio.TimeoutError:
            pass
        except websockets.exceptions.ConnectionClosed:
            pass
        except KeyboardInterrupt:
            pass
        
        print()
        print(f"\n📊 Total logs captured: {log_count}")

if __name__ == "__main__":
    try:
        asyncio.run(get_console_logs())
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
