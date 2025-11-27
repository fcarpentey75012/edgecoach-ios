/**
 * Service Wahoo OAuth pour EdgeCoach iOS
 * Gestion de l'intégration Wahoo (connexion, synchronisation)
 */

import { Linking } from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';
import apiService from './api';

// Configuration Wahoo
const WAHOO_CONFIG = {
  CLIENT_ID: 'aSnKputUgUtaCxtVlAImFyp-EyYQQoFUmBZnCyTC1lM',
  REDIRECT_URI: 'edgecoach://auth/wahoo/callback',
  SCOPES: 'email user_read workouts_read offline_data',
  AUTH_URL: 'https://api.wahooligan.com/oauth/authorize',
  TOKEN_URL: 'https://api.wahooligan.com/oauth/token',
  API_URL: 'https://api.wahooligan.com/v1',
};

// Types
export interface WahooTokens {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  token_type: string;
}

export interface WahooProfile {
  id: number;
  email: string;
  name: string;
  first_name?: string;
  last_name?: string;
  created_at?: string;
}

export interface WahooWorkout {
  id: number;
  name: string;
  sport: string;
  duration_seconds: number;
  distance_meters?: number;
  calories?: number;
  avg_heart_rate?: number;
  max_heart_rate?: number;
  created_at: string;
}

export interface WahooConnectionStatus {
  isConnected: boolean;
  profile?: WahooProfile;
  lastSync?: string;
  error?: string;
}

export interface WahooAuthResult {
  success: boolean;
  authUrl?: string;
  instructions?: string[];
  error?: string;
}

export interface WahooExchangeResult {
  success: boolean;
  tokens?: WahooTokens;
  profile?: WahooProfile;
  message?: string;
  error?: string;
}

class WahooService {
  private storageKeys = {
    STATE: 'wahoo_oauth_state',
    USER_ID: 'wahoo_oauth_user_id',
    TOKENS: 'wahoo_tokens',
    PROFILE: 'wahoo_profile',
  };

  /**
   * Générer l'URL d'autorisation Wahoo
   */
  generateAuthUrl(userId: string): string {
    const stateToken = `wahoo_${userId}_${Math.floor(Date.now() / 1000)}`;

    const params = new URLSearchParams({
      client_id: WAHOO_CONFIG.CLIENT_ID,
      redirect_uri: WAHOO_CONFIG.REDIRECT_URI,
      response_type: 'code',
      scope: WAHOO_CONFIG.SCOPES,
      state: stateToken,
    });

    // Stocker l'état pour vérification ultérieure
    AsyncStorage.setItem(this.storageKeys.STATE, stateToken);
    AsyncStorage.setItem(this.storageKeys.USER_ID, userId);

    return `${WAHOO_CONFIG.AUTH_URL}?${params.toString()}`;
  }

  /**
   * Démarrer le processus OAuth Wahoo
   */
  async startOAuth(userId: string): Promise<WahooAuthResult> {
    try {
      const authUrl = this.generateAuthUrl(userId);

      // Ouvrir l'URL dans le navigateur
      const canOpen = await Linking.canOpenURL(authUrl);
      if (!canOpen) {
        return {
          success: false,
          error: "Impossible d'ouvrir le navigateur pour l'authentification Wahoo",
        };
      }

      await Linking.openURL(authUrl);

      return {
        success: true,
        authUrl,
        instructions: [
          '1. Connectez-vous avec vos identifiants Wahoo',
          "2. Cliquez sur \"Autoriser\" pour EdgeCoach",
          "3. Vous serez redirigé vers l'application",
        ],
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Vérifier si une URL est un callback Wahoo valide
   */
  isWahooCallbackUrl(url: string): boolean {
    if (!url) return false;
    return url.startsWith('edgecoach://auth/wahoo/callback');
  }

  /**
   * Extraire le code d'autorisation d'une URL de callback
   */
  extractAuthCodeFromUrl(url: string): { code: string | null; state: string | null; error: string | null } {
    try {
      // Parser les query params manuellement (React Native n'a pas URL/URLSearchParams)
      const queryStart = url.indexOf('?');
      if (queryStart === -1) {
        return { code: null, state: null, error: null };
      }

      const queryString = url.substring(queryStart + 1);
      const params: Record<string, string> = {};

      queryString.split('&').forEach(pair => {
        const [key, value] = pair.split('=');
        if (key && value) {
          params[decodeURIComponent(key)] = decodeURIComponent(value);
        }
      });

      return {
        code: params['code'] || null,
        state: params['state'] || null,
        error: params['error'] || null,
      };
    } catch {
      return { code: null, state: null, error: null };
    }
  }

  /**
   * Gérer le callback OAuth (appelé quand l'app reçoit le deep link)
   */
  async handleCallback(callbackUrl: string): Promise<WahooExchangeResult> {
    try {
      const { code, state, error } = this.extractAuthCodeFromUrl(callbackUrl);

      if (error) {
        return {
          success: false,
          error: `Erreur OAuth: ${error}`,
        };
      }

      if (!code) {
        return {
          success: false,
          error: "Code d'autorisation non trouvé dans l'URL",
        };
      }

      // Vérifier l'état
      const storedState = await AsyncStorage.getItem(this.storageKeys.STATE);
      if (state !== storedState) {
        return {
          success: false,
          error: "État OAuth invalide. Veuillez réessayer.",
        };
      }

      // Récupérer l'ID utilisateur
      const userId = await AsyncStorage.getItem(this.storageKeys.USER_ID);
      if (!userId) {
        return {
          success: false,
          error: 'ID utilisateur non trouvé',
        };
      }

      // Échanger le code contre les tokens via le backend
      return this.exchangeCodeForTokens(code, userId);
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Échanger le code d'autorisation contre des tokens via le backend
   */
  async exchangeCodeForTokens(code: string, userId: string): Promise<WahooExchangeResult> {
    try {
      const response = await apiService.post<{
        access_token: string;
        refresh_token: string;
        expires_in: number;
        token_type: string;
        profile?: WahooProfile;
      }>('/auth/wahoo/exchange', {
        code,
        user_id: userId,
        redirect_uri: WAHOO_CONFIG.REDIRECT_URI,
      });

      const tokens: WahooTokens = {
        access_token: response.access_token,
        refresh_token: response.refresh_token,
        expires_in: response.expires_in,
        token_type: response.token_type,
      };

      // Stocker les tokens
      await AsyncStorage.setItem(this.storageKeys.TOKENS, JSON.stringify(tokens));

      // Si le profil est retourné, le stocker
      if (response.profile) {
        await AsyncStorage.setItem(this.storageKeys.PROFILE, JSON.stringify(response.profile));
      }

      // Nettoyer les données temporaires
      await AsyncStorage.removeItem(this.storageKeys.STATE);
      await AsyncStorage.removeItem(this.storageKeys.USER_ID);

      return {
        success: true,
        tokens,
        profile: response.profile,
        message: 'Connexion Wahoo établie avec succès!',
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Vérifier le statut de connexion Wahoo
   */
  async getConnectionStatus(userId: string): Promise<WahooConnectionStatus> {
    try {
      const response = await apiService.get<{
        connected: boolean;
        profile?: WahooProfile;
        last_sync?: string;
      }>(`/auth/wahoo/status`, { user_id: userId });

      return {
        isConnected: response.connected,
        profile: response.profile,
        lastSync: response.last_sync,
      };
    } catch (error: any) {
      // Essayer de lire depuis le stockage local
      const tokensStr = await AsyncStorage.getItem(this.storageKeys.TOKENS);
      const profileStr = await AsyncStorage.getItem(this.storageKeys.PROFILE);

      if (tokensStr) {
        return {
          isConnected: true,
          profile: profileStr ? JSON.parse(profileStr) : undefined,
        };
      }

      return {
        isConnected: false,
        error: error.message,
      };
    }
  }

  /**
   * Déconnecter Wahoo
   */
  async disconnect(userId: string): Promise<{ success: boolean; error?: string }> {
    try {
      await apiService.post<{ message: string }>('/auth/wahoo/disconnect', { user_id: userId });

      // Nettoyer le stockage local
      await AsyncStorage.removeItem(this.storageKeys.TOKENS);
      await AsyncStorage.removeItem(this.storageKeys.PROFILE);
      await AsyncStorage.removeItem(this.storageKeys.STATE);
      await AsyncStorage.removeItem(this.storageKeys.USER_ID);

      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Synchroniser les entraînements Wahoo
   */
  async syncWorkouts(userId: string): Promise<{ success: boolean; workouts?: WahooWorkout[]; error?: string }> {
    try {
      const response = await apiService.post<{ workouts: WahooWorkout[]; count: number }>(
        '/auth/wahoo/sync',
        { user_id: userId }
      );

      return {
        success: true,
        workouts: response.workouts,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Récupérer les entraînements récents
   */
  async getRecentWorkouts(
    userId: string,
    limit: number = 10
  ): Promise<{ success: boolean; workouts?: WahooWorkout[]; error?: string }> {
    try {
      const response = await apiService.get<{ workouts: WahooWorkout[] }>('/auth/wahoo/workouts', {
        user_id: userId,
        limit: limit.toString(),
      });

      return {
        success: true,
        workouts: response.workouts,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }
}

export const wahooService = new WahooService();
export default wahooService;
