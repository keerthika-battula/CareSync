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

  useEffect(() => {
    async function initAuth() {
      const storedToken = getAuthToken();
      if (storedToken) {
        try {
          const res = await authApi.getMe();
          if (res?.data) {
            setUser(res.data);
            setStoredUser(res.data);
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
    const authData = response.data;
    if (authData?.accessToken) {
      setAuthToken(authData.accessToken, remember);
      setStoredUser(authData.user, remember);
      setToken(authData.accessToken);
      setUser(authData.user);
      return authData;
    }
    throw new Error('Authentication failed: Missing access token');
  };

  const register = async (userData) => {
    const response = await authApi.register(userData);
    const authData = response.data;
    if (authData?.accessToken) {
      setAuthToken(authData.accessToken, true);
      setStoredUser(authData.user, true);
      setToken(authData.accessToken);
      setUser(authData.user);
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
      if (res?.data) {
        setUser(res.data);
        setStoredUser(res.data);
      }
    } catch (e) {
      console.error('Failed to refresh user:', e);
    }
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
