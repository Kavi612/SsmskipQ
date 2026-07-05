/** Short chime for manager new-order alerts — no external audio file needed. */
export const playNewOrderSound = () => {
  try {
    const ctx = new AudioContext();
    const now = ctx.currentTime;

    const playTone = (freq: number, start: number, duration: number) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = 'sine';
      osc.frequency.value = freq;
      gain.gain.setValueAtTime(0.0001, now + start);
      gain.gain.exponentialRampToValueAtTime(0.22, now + start + 0.02);
      gain.gain.exponentialRampToValueAtTime(0.0001, now + start + duration);
      osc.connect(gain);
      gain.connect(ctx.destination);
      osc.start(now + start);
      osc.stop(now + start + duration + 0.05);
    };

    playTone(880, 0, 0.12);
    playTone(1174.66, 0.14, 0.18);

    window.setTimeout(() => {
      void ctx.close();
    }, 500);
  } catch {
    // Audio may be blocked until user gesture — fail silently
  }
};
