# Strategy Center - AI Modes

The Strategy Center now supports **two AI modes**: MCP mode and OpenAI mode.

## Quick Comparison

| Feature | MCP Mode | OpenAI Mode |
|---------|----------|-------------|
| **Cost** | Free (no API key) | Requires OpenAI API key |
| **Setup** | Zero config | Need API key |
| **Responses** | Direct telemetry data | Natural language + context |
| **Best For** | Quick data lookups | Strategic analysis |
| **Internet** | Not required | Required |

## Switching Modes

### Method 1: Browser Console
```javascript
// Switch to MCP mode (free, no API key)
switchAIMode('mcp')

// Switch to OpenAI mode (requires API key)
switchAIMode('openai')
```

### Method 2: localStorage
```javascript
// Set to MCP
localStorage.setItem('ai_mode', 'mcp')

// Set to OpenAI
localStorage.setItem('ai_mode', 'openai')

// Refresh page after changing
location.reload()
```

---

## MCP Mode (Default)

**No API key required!** Uses Pits n' Giggles MCP server directly.

### How It Works
1. Your question is analyzed for keywords
2. Appropriate MCP tool is called automatically
3. Data is formatted and displayed

### Intelligent Query Routing

The system automatically routes questions to the right MCP tool:

**Race Status Questions** → `get_race_info`
- "What are the current race conditions?"
- "Is there a safety car?"
- "What's the weather?"

**Tyre Questions** → `analyze_tyre_strategy`
- "Compare tyre strategies"
- "Who's on soft tyres?"
- "Show me tyre wear"

**Driver-Specific** → `get_driver_info`
- "Analyze driver 5"
- "Show me driver 0's lap history"

**Lap Comparison** → `get_lap_comparison`
- "Compare laps between drivers"
- "Show lap time comparison"

**Standings** → `get_telemetry_data`
- "Show me the standings"
- "What are the positions?"
- "Display all drivers"

### Example Responses

**Input:** "What are the current race conditions?"

**Output:**
```
📊 Race Status

Session: Race
Lap: 15/52
Status: In Progress
Track Temp: 42°C
Air Temp: 28°C
Weather: Clear
```

**Input:** "Compare tyre strategies"

**Output:**
```
🏎️ Tyre Analysis

Hamilton: Soft (5 laps, 12% wear)
Verstappen: Medium (8 laps, 8% wear)
Leclerc: Soft (3 laps, 5% wear)
Sainz: Medium (12 laps, 15% wear)
Russell: Soft (6 laps, 10% wear)
```

---

## OpenAI Mode

**Requires API key** but provides natural language analysis with strategic insights.

### Setup

1. Get API key from: https://platform.openai.com/api-keys
2. Set in browser console:
   ```javascript
   localStorage.setItem('openai_api_key', 'sk-your-key-here')
   ```
3. Switch to OpenAI mode (if not default):
   ```javascript
   switchAIMode('openai')
   ```

### How It Works
1. Fetches current telemetry data
2. Sends question + telemetry context to GPT-4
3. AI analyzes and provides strategic advice
4. Natural language response displayed

### Example Responses

**Input:** "What are the current race conditions?"

**Output:**
```
You're on lap 15 of 52 at Silverstone. Track temperature is quite 
warm at 42°C which is causing higher tyre degradation than expected. 

The race is green with no safety car periods yet. Based on current 
degradation rates, I'd suggest extending your stint another 3-5 laps 
before pitting to maximize the delta strategy.

Weather is clear and stable - no rain expected.
```

**Input:** "Compare tyre strategies"

**Output:**
```
Looking at the field, there's an interesting split:

Soft runners (Hamilton, Leclerc, Russell): Started with track position 
advantage but showing 12-15% wear already. They'll need to pit soon.

Medium runners (Verstappen, Sainz): Better degradation profile, only 
8-10% wear. They can extend 8-10 more laps and undercut the soft runners.

Strategic recommendation: If you're on softs, pit within next 2 laps. 
If mediums, extend to lap 23-25 for optimal delta.
```

---

## Which Mode Should I Use?

### Use MCP Mode When:
- ✅ You want quick, factual data
- ✅ You don't have an OpenAI API key
- ✅ You're offline (no internet)
- ✅ You want free operation
- ✅ You prefer raw numbers

### Use OpenAI Mode When:
- ✅ You want strategic analysis
- ✅ You have an OpenAI API key
- ✅ You need contextual advice
- ✅ You want natural language responses
- ✅ You need complex multi-factor analysis

### Pro Tip: Use Both!
1. Start in MCP mode for quick lookups during race
2. Switch to OpenAI for strategic decisions
3. Or keep two browser tabs open - one in each mode!

---

## Cost Comparison

### MCP Mode
- **Cost:** $0
- **Requirements:** None
- **Limits:** No limits

### OpenAI Mode
- **Cost:** ~$0.01-0.03 per question (GPT-4)
- **Alternative:** Use GPT-3.5-turbo for ~$0.001-0.003 per question
- **Requirements:** OpenAI account with credits
- **Limits:** Your API quota

To use cheaper GPT-3.5-turbo, edit `strategy-center.html`:
```javascript
model: 'gpt-3.5-turbo',  // Change from 'gpt-4'
```

---

## Troubleshooting

### MCP Mode Issues

**"Error: tools/call failed"**
- Check Pits n' Giggles backend is running
- Verify `/mcp/tools` endpoint works

**Unformatted JSON responses**
- This is normal for complex queries
- Data is still correct, just not formatted

**"Unknown tool" error**
- Question might not match any routing pattern
- Try rephrasing or be more specific

### OpenAI Mode Issues

**"Please set your OpenAI API key"**
- Set key: `localStorage.setItem('openai_api_key', 'sk-...')`
- Refresh page

**"Rate limit exceeded"**
- You've hit OpenAI API quota
- Wait, upgrade plan, or switch to MCP mode

**"Insufficient quota"**
- Add credits to OpenAI account
- Or use GPT-3.5-turbo (cheaper)

---

## Advanced: Custom MCP Routing

Want to add custom query patterns? Edit the `routeMCPQuery` function in `strategy-center.html`:

```javascript
async function routeMCPQuery(question) {
    const q = question.toLowerCase();
    
    // Add your custom routing
    if (q.includes('fuel')) {
        // Call specific tool for fuel analysis
        return await callMCPTool('get_race_info');
    }
    
    // ... existing routing ...
}
```

## Advanced: Custom Formatting

Customize how MCP responses are displayed by editing `formatMCPResponse`:

```javascript
function formatMCPResponse(question, data) {
    // Add custom formatting logic
    if (data.fuel_remaining) {
        return `⛽ Fuel: ${data.fuel_remaining}kg (${data.laps_remaining} laps)`;
    }
    
    // ... existing formatting ...
}
```

---

**See Also:**
- [Strategy Center Guide](STRATEGY_CENTER.md)
- [MCP Integration](MCP_INTEGRATION.md)
- [MCP Quick Start](MCP_QUICKSTART.md)
