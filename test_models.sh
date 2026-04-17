#!/bin/bash
API_KEY="${OPENAI_API_KEY:-}"  # Set via environment: export OPENAI_API_KEY=sk-...

# Create test audio
say -o /tmp/test_audio.aiff "Hello world" 2>/dev/null
afconvert -f m4af -d aac /tmp/test_audio.aiff /tmp/test_audio.m4a 2>/dev/null

echo "=== Test 1: gpt-4o-transcribe with prompt ==="
curl -s "https://api.openai.com/v1/audio/transcriptions" \
  -H "Authorization: Bearer $API_KEY" \
  -F "file=@/tmp/test_audio.m4a" \
  -F "model=gpt-4o-transcribe" \
  -F "prompt=Format nicely"
echo ""

echo ""
echo "=== Test 2: gpt-4o-transcribe WITHOUT prompt ==="
curl -s "https://api.openai.com/v1/audio/transcriptions" \
  -H "Authorization: Bearer $API_KEY" \
  -F "file=@/tmp/test_audio.m4a" \
  -F "model=gpt-4o-transcribe"
echo ""

echo ""
echo "=== Test 3: whisper-1 with prompt ==="
curl -s "https://api.openai.com/v1/audio/transcriptions" \
  -H "Authorization: Bearer $API_KEY" \
  -F "file=@/tmp/test_audio.m4a" \
  -F "model=whisper-1" \
  -F "prompt=Format nicely"
echo ""

# Cleanup
rm -f /tmp/test_audio.aiff /tmp/test_audio.m4a
