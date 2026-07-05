export type UserRole = 'student' | 'manager';

export interface StudentUser {
  id: string;
  role: 'student';
  name: string;
  mobile: string;
}

export interface ManagerUser {
  id: string;
  role: 'manager';
  name: string;
  managerId: string;
}

export type User = StudentUser | ManagerUser;

export interface AuthResponse {
  success: boolean;
  data: {
    token: string;
    user: User;
  };
  message?: string;
}

export interface MeResponse {
  success: boolean;
  data: {
    user: User;
  };
  message?: string;
}
