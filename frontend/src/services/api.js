const API_BASE_URL = 
  import.meta.env.VITE_API_BASE_URL ||
  import.meta.env.VITE_API_URL ||
  (typeof window !== 'undefined' && (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1')
    ? '' // use Vite proxy in dev
    : 'https://caresync-4dfr.onrender.com' // live backend in prod
  );

export function getAuthToken() {
  return localStorage.getItem('caresync_token') || sessionStorage.getItem('caresync_token');
}

export function setAuthToken(token, remember = true) {
  if (remember) {
    localStorage.setItem('caresync_token', token);
    sessionStorage.removeItem('caresync_token');
  } else {
    sessionStorage.setItem('caresync_token', token);
    localStorage.removeItem('caresync_token');
  }
}

export function clearAuthToken() {
  localStorage.removeItem('caresync_token');
  sessionStorage.removeItem('caresync_token');
  localStorage.removeItem('caresync_user');
  sessionStorage.removeItem('caresync_user');
}

export function getStoredUser() {
  const userStr = localStorage.getItem('caresync_user') || sessionStorage.getItem('caresync_user');
  if (!userStr) return null;
  try {
    return JSON.parse(userStr);
  } catch {
    return null;
  }
}

export function setStoredUser(user, remember = true) {
  const userStr = JSON.stringify(user);
  if (remember) {
    localStorage.setItem('caresync_user', userStr);
  } else {
    sessionStorage.setItem('caresync_user', userStr);
  }
}

async function request(endpoint, options = {}) {
  const token = getAuthToken();
  const url = `${API_BASE_URL}${endpoint}`;

  const headers = {
    'Accept': 'application/json, text/plain, */*',
    ...(options.headers || {}),
  };

  if (!(options.body instanceof FormData)) {
    headers['Content-Type'] = 'application/json';
  }

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  // AbortController with 40-second timeout for server cold-starts
  const controller = new AbortController();
  const timeoutMs = options.timeout || 40000;
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);

  const config = {
    ...options,
    headers,
    signal: controller.signal,
  };

  try {
    const response = await fetch(url, config);
    clearTimeout(timeoutId);

    // Handle file blob downloads
    if (options.responseType === 'blob') {
      if (!response.ok) {
        throw new Error(`Download failed with status ${response.status}`);
      }
      return await response.blob();
    }

    const data = await response.json().catch(() => ({}));

    if (!response.ok) {
      const errorMsg = data?.message || data?.error || `Request failed with status ${response.status}`;
      const err = new Error(errorMsg);
      err.status = response.status;
      err.data = data;
      throw err;
    }

    return data;
  } catch (error) {
    clearTimeout(timeoutId);

    if (error.name === 'AbortError') {
      const timeoutErr = new Error('Server took too long to respond. The backend may be starting up—please try again.');
      timeoutErr.status = 504;
      throw timeoutErr;
    }

    if (error instanceof TypeError && error.message.includes('fetch')) {
      const netErr = new Error('Unable to connect to CareSync server. Please check your network or try again in a moment.');
      netErr.status = 0;
      throw netErr;
    }

    if (error.status === 401 && !endpoint.includes('/api/auth/')) {
      clearAuthToken();
      if (typeof window !== 'undefined' && window.location.pathname !== '/login' && window.location.pathname !== '/') {
        window.location.href = '/login';
      }
    }
    throw error;
  }
}

export const authApi = {
  login: (credentials) => request('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify(credentials),
  }),
  register: (userData) => request('/api/auth/register', {
    method: 'POST',
    body: JSON.stringify(userData),
  }),
  forgotPassword: (data) => request('/api/auth/forgot-password', {
    method: 'POST',
    body: JSON.stringify(data),
  }),
  resetPassword: (data) => request('/api/auth/reset-password', {
    method: 'POST',
    body: JSON.stringify(data),
  }),
  getMe: () => request('/api/v1/users/me'),
};

export const medicinesApi = {
  getAll: () => request('/api/medicines'),
  getById: (id) => request(`/api/medicines/${id}`),
  create: (medicine) => request('/api/medicines', {
    method: 'POST',
    body: JSON.stringify(medicine),
  }),
  update: (id, medicine) => request(`/api/medicines/${id}`, {
    method: 'PUT',
    body: JSON.stringify(medicine),
  }),
  delete: (id) => request(`/api/medicines/${id}`, {
    method: 'DELETE',
  }),
};

export const remindersApi = {
  getToday: () => request('/api/reminders/today'),
  markTaken: (id) => request(`/api/reminders/${id}/taken`, { method: 'POST' }),
  markSkipped: (id) => request(`/api/reminders/${id}/skip`, { method: 'POST' }),
  snooze: (id, minutes) => request(`/api/reminders/${id}/snooze`, {
    method: 'POST',
    body: JSON.stringify({ minutes }),
  }),
};

export const appointmentsApi = {
  getAll: () => request('/api/appointments'),
  create: (data) => request('/api/appointments', {
    method: 'POST',
    body: JSON.stringify(data),
  }),
  delete: (id) => request(`/api/appointments/${id}`, {
    method: 'DELETE',
  }),
};

export const familyApi = {
  getAll: () => request('/api/family'),
  create: (data) => request('/api/family', {
    method: 'POST',
    body: JSON.stringify(data),
  }),
  delete: (id) => request(`/api/family/${id}`, {
    method: 'DELETE',
  }),
};

export const documentsApi = {
  getAll: () => request('/api/documents'),
  upload: (formData) => request('/api/documents', {
    method: 'POST',
    body: formData,
  }),
  download: (id) => request(`/api/documents/${id}/download`, {
    method: 'GET',
    responseType: 'blob',
  }),
  delete: (id) => request(`/api/documents/${id}`, {
    method: 'DELETE',
  }),
};

export const statsApi = {
  getDashboardStats: () => request('/api/v1/statistics/dashboard'),
};

export const adminApi = {
  getUsers: (page = 0, size = 20) => request(`/api/v1/admin/users?page=${page}&size=${size}`),
  getUserById: (id) => request(`/api/v1/admin/users/${id}`),
  createUser: (data) => request('/api/v1/admin/users', {
    method: 'POST',
    body: JSON.stringify(data),
  }),
  updateRole: (userId, role) => request(`/api/v1/admin/users/${userId}/role`, {
    method: 'PATCH',
    body: JSON.stringify({ role }),
  }),
  updateStatus: (userId, isActive) => request(`/api/v1/admin/users/${userId}/status`, {
    method: 'PATCH',
    body: JSON.stringify({ isActive }),
  }),
  getUserHealthcareOverview: (userId) => request(`/api/v1/admin/users/${userId}/healthcare-overview`),
  getUserMedicines: (userId) => request(`/api/v1/admin/users/${userId}/medicines`),
  getUserDocuments: (userId) => request(`/api/v1/admin/users/${userId}/documents`),
  getUserFamily: (userId) => request(`/api/v1/admin/users/${userId}/family`),
  getUserAppointments: (userId) => request(`/api/v1/admin/users/${userId}/appointments`),
  downloadUserDocument: (userId, docId) => request(`/api/v1/admin/users/${userId}/documents/${docId}/download`, {
    method: 'GET',
    responseType: 'blob',
  }),
};
