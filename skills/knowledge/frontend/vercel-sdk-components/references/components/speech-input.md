# Speech Input

- **Category**: Voice
- **Docs**: [https://elements.ai-sdk.dev/components/speech-input](https://elements.ai-sdk.dev/components/speech-input)
- **Install**: `npx ai-elements@latest add speech-input`

## Description

Voice-to-text input control for dictating messages to the AI.

## Tags

`speech, voice, dictation, microphone, stt, voice-to-text`

## Scenarios

### ✅ Good Fit

- Building voice agent interfaces
- Adding speech-to-text or text-to-speech to AI apps
- Creating voice-first AI experiences

### ❌ Bad Fit (with alternatives)

- Music players → Use a dedicated audio library
- Video conferencing → Use WebRTC-based solutions
- General media playback → Use HTML5 audio/video elements

## Testing Checklist

- [ ] Component renders correctly
- [ ] Works with browser media APIs (getUserMedia for mic, speechSynthesis for TTS)
- [ ] Handles permission denial gracefully
- [ ] Responsive layout
- [ ] Accessibility: keyboard and screen reader support
