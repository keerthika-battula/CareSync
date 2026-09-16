import React, { createContext, useContext, useState, useEffect } from 'react';
import {
  authApi,
  getAuthToken,
  setAuthToken,
  clearAuthToken,
  getStoredUser,
  setStoredUser
} from '../services/api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(getStoredUser());
  const [token, setToken] = useState(getAuthToken());
  const [isLoading, setIsLoading] = useState(true);

  const formatUser = (u) => {
    if (!u) return null;
    const computedName = [u.firstName, u.lastName].filter(Boolean).join(' ') || u.fullName || u.username || u.email || 'CareSync User';
    return {
      ...u,
      fullName: computedName,
      displayName: computedName,
    };
  };

  useEffect(() => {
    async function initAuth() {
      const storedToken = getAuthToken();
      if (storedToken) {
        try {
          const res = await authApi.getMe();
          const raw = res?.data || res;
          if (raw) {
            const formatted = formatUser(raw);
            setUser(formatted);
            setStoredUser(formatted);
          }
        } catch (err) {
          console.warn('Session verification failed:', err);
          clearAuthToken();
          setUser(null);
          setToken(null);
        }
      }
      setIsLoading(false);
    }
    initAuth();
  }, []);

  const login = async (email, password, remember = true) => {
    const response = await authApi.login({ email, password });
    const authData = response.data || response;
    const tokenStr = authData?.accessToken || authData?.token;
    const rawUser = authData?.user || authData;

    if (tokenStr) {
      const userObj = formatUser(rawUser);
      setAuthToken(tokenStr, remember);
      setStoredUser(userObj, remember);
      setToken(tokenStr);
      setUser(userObj);
      return authData;
    }
    throw new Error('Authentication failed: Missing access token in server response');
  };

  const register = async (userData) => {
    const response = await authApi.register(userData);
    const authData = response.data || response;
    const tokenStr = authData?.accessToken || authData?.token;
    const rawUser = authData?.user || authData;

    if (tokenStr) {
      const userObj = formatUser(rawUser);
      setAuthToken(tokenStr, true);
      setStoredUser(userObj, true);
      setToken(tokenStr);
      setUser(userObj);
      return authData;
    }
    return response;
  };

  const logout = () => {
    clearAuthToken();
    setUser(null);
    setToken(null);
    window.location.href = '/login';
  };

  const refreshUser = async () => {
    try {
      const res = await authApi.getMe();
      const raw = res?.data || res;
      if (raw) {
        const formatted = formatUser(raw);
        setUser(formatted);
        setStoredUser(formatted);
        return formatted;
      }
    } catch (e) {
      console.error('Failed to refresh user:', e);
    }
  };

  const updateUser = (newUserData) => {
    const formatted = formatUser({ ...user, ...newUserData });
    setUser(formatted);
    setStoredUser(formatted);
    return formatted;
  };

  const value = {
    user,
    token,
    isAuthenticated: !!token && !!user,
    isAdmin: user?.role === 'ADMIN',
    role: user?.role || 'USER',
    isLoading,
    login,
    register,
    logout,
    refreshUser,
    updateUser,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
