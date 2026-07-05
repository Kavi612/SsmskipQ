const MOBILE_REGEX = /^[6-9]\d{9}$/;
const NAME_REGEX = /^[A-Za-z ]+$/;

export const validateStudentName = (name: string): string | null => {
  const trimmed = name.trim();

  if (!trimmed) {
    return 'Name is required';
  }

  if (trimmed.length < 2) {
    return 'Name must be at least 2 characters';
  }

  if (!NAME_REGEX.test(trimmed)) {
    return 'Name can only contain letters and spaces';
  }

  return null;
};

export const validateStudentMobile = (mobile: string): string | null => {
  if (!mobile) {
    return 'Mobile number is required';
  }

  if (!/^[6-9]/.test(mobile)) {
    return 'Mobile number must start with 6, 7, 8, or 9';
  }

  if (mobile.length < 10) {
    return 'Mobile number must be exactly 10 digits';
  }

  if (!MOBILE_REGEX.test(mobile)) {
    return 'Enter a valid 10-digit mobile number';
  }

  return null;
};

export const getMobileErrorImmediate = (mobile: string): string | null => {
  if (!mobile) return null;

  if (!/^[6-9]/.test(mobile)) {
    return 'Mobile number must start with 6, 7, 8, or 9';
  }

  if (mobile.length < 10) {
    return 'Mobile number must be exactly 10 digits';
  }

  if (!MOBILE_REGEX.test(mobile)) {
    return 'Enter a valid 10-digit mobile number';
  }

  return null;
};

export const getNameErrorImmediate = (name: string): string | null => {
  const trimmed = name.trim();
  if (!trimmed) return null;

  if (trimmed.length < 2) {
    return 'Name must be at least 2 characters';
  }

  if (!NAME_REGEX.test(trimmed)) {
    return 'Name can only contain letters and spaces';
  }

  return null;
};
