/**
 * Returns current time in IST as minutes since midnight.
 */
export const getCurrentIstMinutes = () => {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Kolkata',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(new Date());

  const hour = Number(parts.find((p) => p.type === 'hour')?.value ?? 0);
  const minute = Number(parts.find((p) => p.type === 'minute')?.value ?? 0);
  return hour * 60 + minute;
};

export const timeToMinutes = (time) => {
  const [h, m] = time.split(':').map(Number);
  return h * 60 + m;
};

export const isWithinOrderingWindow = (openTime, closeTime) => {
  const now = getCurrentIstMinutes();
  const open = timeToMinutes(openTime);
  const close = timeToMinutes(closeTime);
  return now >= open && now < close;
};
