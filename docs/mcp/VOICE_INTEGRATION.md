# Voice Integration - Speech-to-Text and Text-to-Speech

Add voice functionality to your F1 Race Engineer for hands-free operation during racing.

## Overview

The Strategy Center supports browser-based voice input and output:
- **Speech-to-Text**: Ask questions hands-free using your microphone
- **Text-to-Speech**: Hear AI responses while racing

This uses the Web Speech API (built into modern browsers - no additional services needed for basic functionality).

## Browser Support

| Feature | Chrome/Edge | Firefox | Safari |
|---------|-------------|---------|--------|
| Speech Recognition | ✅ Yes | ⚠️ Limited | ✅ Yes |
| Speech Synthesis | ✅ Yes | ✅ Yes | ✅ Yes |

## Quick Setup

### 1. Create Voice-Enabled Strategy Center

Copy the strategy center and add voice controls:

```bash
cp apps/frontend/html/strategy-center.html apps/frontend/html/voice-strategy-center.html
```

### 2. Add Voice Controls (Already Done in voice-strategy-center.html)

The voice integration is already implemented in `voice-strategy-center.html`. Features include:

- 🎤 **Push-to-Talk** - Hold button to speak
- 🔊 **Auto-Response** - AI responses are spoken aloud
- ⚙️ **Voice Settings** - Adjust speed, pitch, volume
- 🗣️ **Voice Selection** - Choose from available voices

### 3. Enable Voice in Strategy Center

Add these buttons to the chat input area:

```html
<div class="voice-controls">
    <button id="voice-btn" class="voice-btn" title="Push to talk">
        🎤
    </button>
    <button id="tts-toggle" class="tts-btn" title="Toggle voice responses">
        🔊
    </button>
</div>
```

### 4. Add Voice JavaScript

```javascript
// Voice Recognition
const recognition = new (window.SpeechRecognition || window.webkitSpeechRecognition)();
recognition.continuous = false;
recognition.interimResults = false;
recognition.lang = 'en-US';

const voiceBtn = document.getElementById('voice-btn');
let isListening = false;

voiceBtn.addEventListener('mousedown', () => {
    if (!isListening) {
        recognition.start();
        isListening = true;
        voiceBtn.classList.add('listening');
    }
});

voiceBtn.addEventListener('mouseup', () => {
    if (isListening) {
        recognition.stop();
        isListening = false;
        voiceBtn.classList.remove('listening');
    }
});

recognition.onresult = (event) => {
    const transcript = event.results[0][0].transcript;
    chatInput.value = transcript;
    sendMessage();
};

// Text-to-Speech
let ttsEnabled = localStorage.getItem('tts_enabled') === 'true';
const ttsToggle = document.getElementById('tts-toggle');

ttsToggle.addEventListener('click', () => {
    ttsEnabled = !ttsEnabled;
    localStorage.setItem('tts_enabled', ttsEnabled);
    ttsToggle.textContent = ttsEnabled ? '🔊' : '🔇';
});

function speak(text) {
    if (!ttsEnabled) return;
    
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.rate = 1.1; // Slightly faster
    utterance.pitch = 1.0;
    utterance.volume = 0.8;
    
    // Use a natural voice if available
    const voices = speechSynthesis.getVoices();
    const preferredVoice = voices.find(v => v.name.includes('Google') || v.name.includes('Samantha'));
    if (preferredVoice) {
        utterance.voice = preferredVoice;
    }
    
    speechSynthesis.speak(utterance);
}

// Modify addMessage to speak AI responses
const originalAddMessage = addMessage;
addMessage = function(text, type) {
    originalAddMessage(text, type);
    if (type === 'ai') {
        speak(text);
    }
};
```

### 5. Add CSS Styling

```css
.voice-controls {
    display: flex;
    gap: 8px;
}

.voice-btn, .tts-btn {
    width: 48px;
    height: 48px;
    background: rgba(0, 242, 255, 0.1);
    border: 1px solid var(--accent-primary);
    border-radius: 8px;
    cursor: pointer;
    font-size: 20px;
    transition: all 0.2s ease;
}

.voice-btn:hover, .tts-btn:hover {
    background: rgba(0, 242, 255, 0.2);
    transform: scale(1.05);
}

.voice-btn.listening {
    background: rgba(255, 50, 50, 0.3);
    border-color: #ff3232;
    animation: pulse 1s infinite;
}

@keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.6; }
}
```

## Usage

### Push-to-Talk

1. Click and hold the 🎤 microphone button
2. Speak your question
3. Release the button
4. Your question will be sent automatically

### Voice Responses

1. Click the 🔊 speaker button to enable voice responses
2. AI responses will be spoken automatically
3. Click again to disable (🔇 muted)

### Example Workflow While Racing

1. Enter a corner with understeer
2. **Hold 🎤** "I have understeer in turn three what should I change"
3. **Release 🎤**
4. **Hear response**: "Try reducing front wing by one click and increasing brake bias to fifty-seven percent"
5. Make changes during next pit stop

## Advanced Configuration

### Custom Voices

```javascript
// List available voices
speechSynthesis.getVoices().forEach(voice => {
    console.log(`${voice.name} (${voice.lang})`);
});

// Use specific voice
const utterance = new SpeechSynthesisUtterance(text);
utterance.voice = speechSynthesis.getVoices().find(v => v.name === 'Google UK English Male');
```

### Adjust Speech Parameters

```javascript
utterance.rate = 1.2;   // Faster speech (0.1 - 10)
utterance.pitch = 0.9;  // Lower pitch (0 - 2)
utterance.volume = 0.7; // Quieter (0 - 1)
```

### Wake Word Detection (Experimental)

For true hands-free operation, you can add wake word detection using libraries like:
- [PocketSphinx.js](https://github.com/syl22-00/pocketsphinx.js/)
- [Porcupine Wake Word](https://picovoice.ai/platform/porcupine/)

Example: "Hey Engineer, I have understeer in sector two"

## Cloud-Based Speech Services

For better accuracy and features, integrate cloud services:

### Google Cloud Speech-to-Text

```javascript
async function transcribeAudio(audioBlob) {
    const formData = new FormData();
    formData.append('audio', audioBlob);
    
    const response = await fetch('https://speech.googleapis.com/v1/speech:recognize', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${GOOGLE_CLOUD_API_KEY}`,
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            config: {
                encoding: 'WEBM_OPUS',
                sampleRateHertz: 48000,
                languageCode: 'en-US'
            },
            audio: {
                content: await audioBlob.arrayBuffer().then(buf => btoa(String.fromCharCode(...new Uint8Array(buf))))
            }
        })
    });
    
    const data = await response.json();
    return data.results[0].alternatives[0].transcript;
}
```

### OpenAI Whisper (Best Accuracy)

```javascript
async function transcribeWithWhisper(audioBlob) {
    const formData = new FormData();
    formData.append('file', audioBlob, 'audio.webm');
    formData.append('model', 'whisper-1');
    
    const response = await fetch('https://api.openai.com/v1/audio/transcriptions', {
        method: 'POST',
        headers: {
            'Authorization': `Bearer ${OPENAI_API_KEY}`
        },
        body: formData
    });
    
    const data = await response.json();
    return data.text;
}
```

## Troubleshooting

### Microphone Not Working

1. Check browser permissions (look for 🎤 icon in address bar)
2. Ensure HTTPS is enabled (required for speech recognition)
3. Try a different browser (Chrome recommended)

### Voice Not Speaking Responses

1. Check system volume
2. Toggle TTS button to ensure it's enabled (🔊)
3. Try `speechSynthesis.getVoices()` in console to check available voices

### Poor Recognition Accuracy

1. Use a headset/microphone instead of laptop mic
2. Reduce background noise
3. Speak clearly and at normal pace
4. Consider using Whisper API for better accuracy

## Racing Best Practices

1. **Use Push-to-Talk**: Activate only when needed to avoid false triggers
2. **Keep Questions Short**: "Fix understeer turn two" instead of long sentences
3. **Pit Straight Usage**: Ask questions on straight sections when you have time
4. **Quick Keywords**: "Tyre strategy" instead of "What is my tyre strategy?"
5. **Mute During Racing**: Enable voice responses only during practice/quali

## Performance Impact

Voice features have minimal performance impact:
- Speech Recognition: ~10MB RAM, <1% CPU
- Speech Synthesis: <5MB RAM, <1% CPU
- No network requests (when using Web Speech API)

For cloud services (Whisper, Google Cloud):
- Network latency: +200-500ms
- Higher accuracy
- Better noise handling

## Future Enhancements

Planned features:
- Voice activity detection (auto-detect when you're speaking)
- Custom wake word ("Hey Engineer...")
- Multi-language support
- Voice command macros ("Pit now", "Switch to softs")
- Integration with SimHub for in-game overlay voice responses

## Example Use Cases

### During Qualifying

```
You: "What's my best lap time?"
AI: "Your best lap is one minute twenty-three point four five six"
```

### During Race

```
You: "Analyze my tyre degradation"
AI: "Tyres are at sixty-two percent wear. Optimal pit window is lap eighteen to twenty"
```

### Setup Changes

```
You: "I have oversteer on exit, what should I change?"
AI: "Increase rear anti-roll bar by two clicks and increase on-throttle differential to seventy percent"
```

---

**Race safely and enjoy hands-free AI assistance! 🎤🏎️**
