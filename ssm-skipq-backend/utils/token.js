/**
 * Returns today's date key in IST (Asia/Kolkata) as YYYY-MM-DD.
 */
export const getTodayDateKey = () => {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Kolkata',
  }).format(new Date());
};

/**
 * Start of today (midnight) in IST, as a UTC Date for MongoDB queries.
 */
export const getTodayStartIst = () => {
  const dateKey = getTodayDateKey();
  return new Date(`${dateKey}T00:00:00+05:30`);
};

/**
 * Generates a daily-resetting token: A001, A002, …
 */
export const formatTokenNumber = (sequence) => {
  const letter = 'A';
  return `${letter}${String(sequence).padStart(3, '0')}`;
};
