/**
 * Returns today's date key in IST (Asia/Kolkata) as YYYY-MM-DD.
 */
export const getTodayDateKey = () => {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Kolkata',
  }).format(new Date());
};

/**
 * Generates a daily-resetting token: A001, A002, …
 */
export const formatTokenNumber = (sequence) => {
  const letter = 'A';
  return `${letter}${String(sequence).padStart(3, '0')}`;
};
