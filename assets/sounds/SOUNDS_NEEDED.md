# Sound Files Needed

To enable timer sounds, you need to add the following audio files to this directory:

## Required Files:

### 1. `tick.mp3`
- **Description**: A short, subtle tick sound for the countdown
- **Duration**: < 0.5 seconds (ideally 0.1-0.2 seconds)
- **Characteristics**: 
  - Soft, non-intrusive sound
  - Similar to a clock tick or soft click
  - Should not be jarring or distracting

### 2. `timer_complete.mp3`
- **Description**: A pleasant notification sound for when the timer completes
- **Duration**: 0.5-2 seconds
- **Characteristics**:
  - Pleasant, positive tone
  - Clear but not startling
  - Could be a chime, bell, or gentle notification sound

## Free Sound Resources:

1. **Freesound.org** (Creative Commons licenses)
   - Clock tick: https://freesound.org/search/?q=clock+tick
   - Notification: https://freesound.org/search/?q=notification+chime

2. **Zapsplat.com** (Free with account)
   - Clock sounds: https://www.zapsplat.com/sound-effect-category/clock-tick/
   - UI sounds: https://www.zapsplat.com/sound-effect-category/user-interface/

3. **Pixabay** (Royalty-free)
   - Sound effects: https://pixabay.com/sound-effects/search/tick/

## Implementation Notes:

- The timer will play the tick sound:
  - Every 5 seconds during normal countdown
  - Every second during the last 5 seconds
- The complete sound plays when any timer session ends
- Users can mute/unmute sounds with the volume button

## Testing:

After adding sounds, test with:
```bash
flutter run
```

The timer should now have audio feedback!