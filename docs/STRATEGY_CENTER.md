# Strategy Center - Integrated AI Chat Interface

The Strategy Center is a built-in web interface that provides a split-screen experience with live telemetry and an AI chat sidebar.

## Features

- **Split-Screen Layout**: Telemetry dashboard on the left, AI chat on the right
- **Collapsible Sidebar**: Toggle AI panel for full-screen telemetry
- **Quick Actions**: One-click common questions
- **Live Telemetry Context**: AI has access to current race data
- **Direct API Integration**: Uses existing Pits n' Giggles endpoints

## Access

Once Pits n' Giggles is running, visit:
```
http://localhost:4768/strategy-center
```

## Setup

### 1. Set OpenAI API Key

The Strategy Center uses OpenAI's GPT-4 for AI responses. Set your API key in the browser console:

```javascript
localStorage.setItem('openai_api_key', 'sk-your-key-here')
```

Get your API key from: https://platform.openai.com/api-keys

### 2. Refresh the Page

After setting the key, refresh the Strategy Center page. You should see "Live" status in the top-right.

## Usage

### Quick Actions

Use the pre-configured buttons for common queries:
- **Race Status** - Current conditions, lap count, safety car
- **Last Laps** - Analyze recent performance
- **Tyre Strategy** - Compare compounds across drivers
- **Pit Call** - Get pit window recommendation
- **Standings** - Current race positions

### Custom Questions

Type your own questions in the chat input:

**Strategy Questions:**
> "What's the optimal pit window based on my tyre wear?"

> "Should I switch to a different compound?"

> "How does my fuel usage compare to planned strategy?"

**Performance Analysis:**
> "Where am I losing time compared to P1?"

> "Analyze my sector times for the last 3 laps"

> "What setup changes would help with understeer?"

**Race Monitoring:**
> "Who's in my DRS train?"

> "What's the gap to the car ahead?"

> "Summarize the current race situation"

## How It Works

### Data Flow

1. User asks a question in the chat
2. Strategy Center fetches current telemetry via `/telemetry-info` and `/race-info`
3. Telemetry data is sent to OpenAI GPT-4 as context
4. AI analyzes data and provides strategic advice
5. Response displayed in chat

### Context Provided to AI

The AI receives:
- Current race information (lap, session type, weather)
- All drivers' telemetry (positions, times, tyres, fuel)
- Session status (safety car, flags, etc.)
- Your specific question

### AI Prompt

The AI is configured as an "expert F1 race engineer" with instructions to:
- Analyze telemetry data
- Provide strategic advice on tyres, fuel, and setup
- Be concise and actionable
- Focus on race-winning decisions

## Customization

### Change AI Model

Edit `strategy-center.html` and modify the model in the fetch request:

```javascript
body: JSON.stringify({
    model: 'gpt-4-turbo',  // or 'gpt-3.5-turbo' for faster/cheaper
    messages: [...]
})
```

### Modify System Prompt

Change the AI's personality by editing the system message:

```javascript
{
    role: 'system',
    content: 'You are a data-focused F1 race engineer. Provide numerical analysis...'
}
```

### Add More Quick Actions

Add buttons in the HTML:

```html
<button class="quick-btn" data-msg="Your question here">Button Label</button>
```

## Comparison to External AI Tools

### Strategy Center (Built-in)
- ✅ Integrated UI with telemetry
- ✅ No external app needed
- ✅ Custom AI prompts
- ✅ Quick actions
- ❌ Requires OpenAI API key
- ❌ Browser-based only
- ❌ No conversation history

### ChatGPT Desktop (via MCP)
- ✅ Full conversation context
- ✅ No API key needed
- ✅ Better AI reasoning
- ✅ Multi-turn conversations
- ❌ Separate application
- ❌ Less integrated UI

### Recommendation

- **During Racing**: Use Strategy Center for quick, in-race decisions
- **Post-Race Analysis**: Use ChatGPT Desktop for detailed session review
- **Live Streaming**: Strategy Center can be OBS-captured easily
- **Development**: Use both! Strategy Center while racing, ChatGPT for detailed analysis

## Privacy & Security

### API Key Storage
- API key stored in browser localStorage
- Only sent to OpenAI (never to Pits n' Giggles server)
- Cleared when localStorage is cleared

### Data Sent to OpenAI
- Current race telemetry (anonymized driver names)
- Your questions
- No personally identifiable information

### Costs
- OpenAI API charges per token
- Typical query: ~$0.01-0.03 for GPT-4
- Consider GPT-3.5-turbo for lower costs (~$0.001-0.003)

## Troubleshooting

### "Please set your OpenAI API key"
- Set the key in browser console: `localStorage.setItem('openai_api_key', 'sk-...')`
- Refresh the page

### "Could not connect to telemetry server"
- Ensure Pits n' Giggles backend is running
- Check console for errors
- Verify URL: `http://localhost:4768/strategy-center`

### "Error communicating with AI"
- Check API key is valid
- Check browser console for details
- Verify OpenAI account has credits
- Try GPT-3.5-turbo if GPT-4 quota exceeded

### Sidebar Not Showing
- Click the arrow button on the left edge
- Refresh the page
- Check browser console for JavaScript errors

### Iframe Not Loading
- Check telemetry server is running
- Verify `/eng-view` endpoint works
- Check for CORS errors in console

## Advanced: Self-Hosted AI

Instead of OpenAI, you can modify the code to use:

### Local LLMs (Ollama, LM Studio)
```javascript
const AI_ENDPOINT = 'http://localhost:11434/api/chat';
// Modify request format for Ollama API
```

### Azure OpenAI
```javascript
const AI_ENDPOINT = 'https://YOUR-RESOURCE.openai.azure.com/openai/deployments/YOUR-DEPLOYMENT/chat/completions?api-version=2024-02-15-preview';
headers: {
    'api-key': YOUR_AZURE_KEY
}
```

### Anthropic Claude
```javascript
const AI_ENDPOINT = 'https://api.anthropic.com/v1/messages';
headers: {
    'x-api-key': YOUR_ANTHROPIC_KEY,
    'anthropic-version': '2023-06-01'
}
```

## Future Enhancements

Potential improvements (contributions welcome!):
- Voice input/output for hands-free use
- Conversation history persistence
- Multi-session comparison
- Automated strategy recommendations
- Integration with OpenF1 API for real F1 data
- Custom AI agent training on your driving style

---

**See Also:**
- [MCP Integration Guide](MCP_INTEGRATION.md)
- [MCP Quick Start](MCP_QUICKSTART.md)
