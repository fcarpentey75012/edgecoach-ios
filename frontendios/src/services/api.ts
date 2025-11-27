/**
 * Service API pour EdgeCoach iOS
 * Adapté du frontend web pour React Native
 */

import axios, { AxiosInstance, AxiosError } from 'axios';
import AsyncStorage from '@react-native-async-storage/async-storage';

// Configuration API
// Note: Pour le simulateur iOS, localhost fonctionne
// Pour un appareil physique, utilisez l'IP de votre Mac (ex: 192.168.x.x)
const API_CONFIG = {
  BASE_URL: 'http://127.0.0.1:5002/api',
  TIMEOUT: 10000, // 10 secondes
  RETRY_ATTEMPTS: 3,
  RETRY_DELAY: 1000, // 1 seconde
  MAX_RETRY_DELAY: 5000, // 5 secondes max
};

// Types
interface ApiError extends Error {
  isNetworkError?: boolean;
  category?: string;
  reason?: string;
  userMessage?: string;
  response?: {
    status: number;
    data?: any;
  };
  code?: string;
}

// Créer l'instance axios
const apiClient: AxiosInstance = axios.create({
  baseURL: API_CONFIG.BASE_URL,
  timeout: API_CONFIG.TIMEOUT,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Détection d'erreur réseau
const isNetworkError = (error: AxiosError): boolean => {
  const networkErrorCodes = [
    'ECONNREFUSED',
    'ERR_NETWORK',
    'NETWORK_ERROR',
    'ENOTFOUND',
    'ECONNABORTED',
    'TIMEOUT',
  ];

  const networkErrorMessages = [
    'Network Error',
    'timeout',
    'connection refused',
  ];

  return (
    networkErrorCodes.includes(error.code || '') ||
    networkErrorMessages.some(msg =>
      error.message?.toLowerCase().includes(msg.toLowerCase())
    ) ||
    !error.response
  );
};

// Utilitaire de délai
const sleep = (ms: number): Promise<void> =>
  new Promise(resolve => setTimeout(resolve, ms));

// Retry avec exponential backoff
const retryWithExponentialBackoff = async <T>(
  fn: () => Promise<T>,
  maxRetries: number = API_CONFIG.RETRY_ATTEMPTS
): Promise<T> => {
  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      const axiosError = error as AxiosError;

      // Ne pas réessayer si ce n'est pas une erreur réseau
      if (!isNetworkError(axiosError)) {
        throw error;
      }

      // Ne pas réessayer sur la dernière tentative
      if (attempt === maxRetries) {
        throw error;
      }

      // Calculer le délai avec exponential backoff
      const delay = Math.min(
        API_CONFIG.RETRY_DELAY * Math.pow(2, attempt),
        API_CONFIG.MAX_RETRY_DELAY
      );

      console.log(
        `API request failed (attempt ${attempt + 1}/${maxRetries + 1}). Retrying in ${delay}ms...`
      );
      await sleep(delay);
    }
  }
  throw new Error('Max retries reached');
};

// Intercepteur de requête - ajouter le token d'authentification
apiClient.interceptors.request.use(
  async config => {
    try {
      const token = await AsyncStorage.getItem('authToken');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    } catch (error) {
      console.warn('Error getting auth token:', error);
    }

    if (__DEV__) {
      console.log(`[API] ${config.method?.toUpperCase()} ${config.url}`);
    }

    return config;
  },
  error => {
    console.error('API request error:', error);
    return Promise.reject(error);
  }
);

// Intercepteur de réponse - gestion des erreurs
apiClient.interceptors.response.use(
  response => response,
  (error: AxiosError) => {
    const apiError = error as ApiError;

    // Ne pas loguer les 404 car souvent attendus (ex: pas de logbook)
    if (__DEV__ && error.response?.status !== 404) {
      console.error('API response error:', error);
    }

    // Catégorisation des erreurs
    if (isNetworkError(error)) {
      apiError.isNetworkError = true;
      apiError.category = 'network';
      apiError.userMessage =
        'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      apiError.reason = 'network_unavailable';
    } else if (error.response?.status === 404) {
      apiError.userMessage = 'Ressource non trouvée.';
      apiError.category = 'not_found';
      apiError.reason = 'resource_not_found';
    } else if (error.response?.status && error.response.status >= 500) {
      apiError.userMessage = 'Erreur serveur. Veuillez réessayer plus tard.';
      apiError.category = 'server_error';
      apiError.reason = 'internal_server_error';
    } else if (error.response?.status === 401) {
      apiError.userMessage = 'Session expirée. Veuillez vous reconnecter.';
      apiError.category = 'auth_error';
      apiError.reason = 'unauthorized';
    } else if (error.response?.status === 403) {
      apiError.userMessage = "Accès refusé.";
      apiError.category = 'permission_error';
      apiError.reason = 'forbidden';
    } else {
      apiError.userMessage = 'Une erreur inattendue est survenue.';
      apiError.category = 'unknown';
      apiError.reason = 'unknown_error';
    }

    return Promise.reject(apiError);
  }
);

// Service API principal
class ApiService {
  private baseURL: string;

  constructor() {
    this.baseURL = API_CONFIG.BASE_URL;
  }

  // Configurer l'URL de base (pour les différents environnements)
  setBaseURL(url: string): void {
    this.baseURL = url;
    apiClient.defaults.baseURL = url;
  }

  // GET request
  async get<T>(endpoint: string, params: Record<string, any> = {}): Promise<T> {
    const response = await retryWithExponentialBackoff(() =>
      apiClient.get<T>(endpoint, { params })
    );
    return response.data;
  }

  // POST request
  async post<T>(endpoint: string, data: Record<string, any> = {}): Promise<T> {
    const response = await retryWithExponentialBackoff(() =>
      apiClient.post<T>(endpoint, data)
    );
    return response.data;
  }

  // PUT request
  async put<T>(endpoint: string, data: Record<string, any> = {}): Promise<T> {
    const response = await retryWithExponentialBackoff(() =>
      apiClient.put<T>(endpoint, data)
    );
    return response.data;
  }

  // DELETE request
  async delete<T>(endpoint: string): Promise<T> {
    const response = await retryWithExponentialBackoff(() =>
      apiClient.delete<T>(endpoint)
    );
    return response.data;
  }

  // Health check
  async healthCheck(): Promise<{ status: string; message: string }> {
    try {
      const response = await apiClient.get('/health', { timeout: 5000 });
      return {
        status: 'healthy',
        message: 'API server is responding',
      };
    } catch (error) {
      return {
        status: 'unhealthy',
        message: 'API server is not responding',
      };
    }
  }

  // Vérifier si l'API est disponible
  async isAvailable(): Promise<boolean> {
    try {
      const health = await this.healthCheck();
      return health.status === 'healthy';
    } catch {
      return false;
    }
  }

  // Obtenir l'URL de base
  getBaseUrl(): string {
    return this.baseURL;
  }
}

export const apiService = new ApiService();
export default apiService;
