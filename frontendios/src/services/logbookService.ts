/**
 * Service Logbook pour EdgeCoach iOS
 * Gestion du carnet de bord d'entraînement (nutrition, hydratation, notes, météo, équipement)
 */

import { apiService } from './api';

// Types pour la nutrition
export interface NutritionItem {
  uniqueId: string;
  brand: string;
  name: string;
  type: string;
  calories: number;
  carbs: number;
  caffeine: number;
  timingMinutes?: number;
  timingFormatted?: string; // Format "0h30" pour l'API
  quantity: number;
}

export interface NutritionTotals {
  calories: number;
  carbs: number;
  caffeine: number;
}

export interface NutritionData {
  items: NutritionItem[];
  totals: NutritionTotals;
  timeline?: NutritionItem[];
}

// Types pour l'hydratation
export interface HydrationItem {
  id: string;
  name: string;
  content: string; // Type de contenu: 'water', 'electrolytes', 'isotonic', 'energy', 'bcaa'
  quantity: number;
  volume: number;
}

export interface HydrationData {
  items: HydrationItem[];
  totalVolume: number;
}

// Types pour la météo
export interface WeatherData {
  temperature?: string;
  conditions?: string;
}

// Types pour l'équipement de session
export interface SessionEquipment {
  bikes?: string;
  shoes?: string;
  wetsuits?: string;
  [key: string]: string | undefined;
}

// Type pour les données logbook complètes
export interface LogbookData {
  nutrition: NutritionData;
  hydration: HydrationData;
  notes: string;
  weather: WeatherData;
  equipment: SessionEquipment;
  effortRating?: number;
  perceivedEffort?: string;
}

// Type pour sauvegarder les données logbook
export interface SaveLogbookRequest {
  sessionId: string;
  mongoId: string;
  sessionDate?: string;
  sessionName?: string;
  timestamp?: string;
  logbook: Partial<LogbookData>;
}

// Type pour un document logbook complet
export interface LogbookDocument {
  _id?: string;
  user_id: string;
  session_id: string;
  mongo_id: string;
  session_date?: string;
  session_name?: string;
  timestamp?: string;
  created_at?: string;
  logbook_data: {
    sessionId: string;
    mongoId: string;
    logbook: LogbookData;
  };
}

// Résultats API
export interface LogbookResult {
  success: boolean;
  data?: LogbookDocument;
  error?: string;
}

export interface LogbookListResult {
  success: boolean;
  data?: LogbookDocument[];
  count?: number;
  error?: string;
}

export interface SaveLogbookResult {
  success: boolean;
  message?: string;
  formattedText?: string;
  error?: string;
}

/**
 * Service pour gérer le carnet de bord d'entraînement
 */
class LogbookService {
  /**
   * Récupérer tous les logbooks d'un utilisateur
   */
  async getAllLogbooks(userId: string): Promise<LogbookListResult> {
    try {
      const response = await apiService.get<{
        status: string;
        count: number;
        data: LogbookDocument[];
      }>('/logbook', { user_id: userId });

      return {
        success: true,
        data: response.data,
        count: response.count,
      };
    } catch (error: any) {
      console.error('Error fetching all logbooks:', error);

      // 404 = pas de logbooks, ce n'est pas une erreur
      if (error.response?.status === 404) {
        return {
          success: true,
          data: [],
          count: 0,
        };
      }

      return {
        success: false,
        error: error.userMessage || error.message || 'Erreur lors de la récupération des logbooks',
      };
    }
  }

  /**
   * Récupérer le logbook d'une session spécifique par mongoId
   */
  async getLogbookByMongoId(userId: string, mongoId: string): Promise<LogbookResult> {
    try {
      const response = await apiService.get<{
        status: string;
        count: number;
        data: LogbookDocument[];
      }>('/logbook', { user_id: userId, mongo_id: mongoId });

      if (response.data && response.data.length > 0) {
        return {
          success: true,
          data: response.data[0],
        };
      }

      // Pas de logbook trouvé - c'est normal, pas une erreur
      return {
        success: true,
        data: undefined,
      };
    } catch (error: any) {
      // 404 = pas de logbook trouvé, ce n'est PAS une erreur
      if (error.response?.status === 404) {
        // Silencieusement retourner success avec pas de data
        return {
          success: true,
          data: undefined,
        };
      }

      console.error('Error fetching logbook by mongoId:', error);
      return {
        success: false,
        error: error.userMessage || error.message || 'Erreur lors de la récupération du logbook',
      };
    }
  }

  /**
   * Récupérer le logbook d'une session spécifique par sessionId
   */
  async getLogbookBySessionId(userId: string, sessionId: string): Promise<LogbookResult> {
    try {
      const response = await apiService.get<{
        status: string;
        count: number;
        data: LogbookDocument[];
      }>('/logbook', { user_id: userId, session_id: sessionId });

      if (response.data && response.data.length > 0) {
        return {
          success: true,
          data: response.data[0],
        };
      }

      // Pas de logbook trouvé - c'est normal, pas une erreur
      return {
        success: true,
        data: undefined,
      };
    } catch (error: any) {
      // 404 = pas de logbook trouvé, ce n'est PAS une erreur
      if (error.response?.status === 404) {
        return {
          success: true,
          data: undefined,
        };
      }

      console.error('Error fetching logbook by sessionId:', error);
      return {
        success: false,
        error: error.userMessage || error.message || 'Erreur lors de la récupération du logbook',
      };
    }
  }

  /**
   * Sauvegarder les données du logbook pour une session
   */
  async saveLogbook(userId: string, data: SaveLogbookRequest): Promise<SaveLogbookResult> {
    try {
      const payload = {
        sessionId: data.sessionId,
        mongoId: data.mongoId,
        sessionDate: data.sessionDate,
        sessionName: data.sessionName,
        timestamp: data.timestamp || new Date().toISOString(),
        logbook: data.logbook,
      };

      const response = await apiService.post<{
        status: string;
        message: string;
        formatted_text?: string;
      }>(`/logbook?user_id=${userId}`, payload);

      return {
        success: true,
        message: response.message,
        formattedText: response.formatted_text,
      };
    } catch (error: any) {
      console.error('Error saving logbook:', error);
      return {
        success: false,
        error: error.userMessage || error.message || 'Erreur lors de la sauvegarde du logbook',
      };
    }
  }

  /**
   * Extraire les données logbook d'une session (helper)
   */
  extractLogbookData(session: any): LogbookData | null {
    const rawLogbook = session?.file_datas?.logbook || session?.fileData?.logbook;
    if (!rawLogbook) return null;

    // Si structure imbriquée { logbook: {...} }
    if (rawLogbook.logbook) {
      return rawLogbook.logbook;
    }

    // Si structure directe
    return rawLogbook;
  }

  /**
   * Créer un logbook vide avec des valeurs par défaut
   */
  createEmptyLogbook(): LogbookData {
    return {
      nutrition: {
        items: [],
        totals: { calories: 0, carbs: 0, caffeine: 0 },
        timeline: [],
      },
      hydration: {
        items: [],
        totalVolume: 0,
      },
      notes: '',
      weather: {
        temperature: '',
        conditions: '',
      },
      equipment: {},
    };
  }

  /**
   * Calculer les totaux nutritionnels à partir des items
   */
  calculateNutritionTotals(items: NutritionItem[]): NutritionTotals {
    return items.reduce(
      (totals, item) => ({
        calories: totals.calories + (item.calories * item.quantity),
        carbs: totals.carbs + (item.carbs * item.quantity),
        caffeine: totals.caffeine + (item.caffeine * item.quantity),
      }),
      { calories: 0, carbs: 0, caffeine: 0 }
    );
  }

  /**
   * Calculer le volume total d'hydratation
   */
  calculateHydrationTotal(items: HydrationItem[]): number {
    return items.reduce(
      (total, item) => total + (item.volume * item.quantity),
      0
    );
  }

  /**
   * Formater le timing en heures:minutes
   */
  formatTiming(timingMinutes: number): string {
    const hours = Math.floor(timingMinutes / 60);
    const minutes = timingMinutes % 60;
    return `${hours}h${minutes.toString().padStart(2, '0')}`;
  }
}

export const logbookService = new LogbookService();
export default logbookService;
