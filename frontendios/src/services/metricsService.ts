/**
 * Service Metrics pour EdgeCoach iOS
 * Gestion des métriques d'entraînement (zones, FC, FTP, etc.)
 */

import apiService from './api';

// Types
export interface HeartRateZone {
  zone: number;
  name: string;
  min: number;
  max: number;
  pace?: string;
  color: string;
  description: string;
}

export interface PowerZone {
  zone: number;
  name: string;
  min: number;
  max: number;
  percentage: string;
  color: string;
  description: string;
}

export interface PaceZone {
  zone: number;
  name: string;
  pace: string;
  color: string;
  description: string;
}

export interface RunningZones {
  lactateThresholdHr: number;
  thresholdPace: string;
  heartRateZones: HeartRateZone[];
}

export interface CyclingZones {
  ftp: number;
  powerZones: PowerZone[];
}

export interface SwimmingZones {
  cssPace: string;
  paceZones: PaceZone[];
}

export interface SportsZones {
  running: RunningZones | null;
  cycling: CyclingZones | null;
  swimming: SwimmingZones | null;
}

export interface UserMetrics {
  id: string;
  userId: string;
  weight: number;
  restingHr: number;
  maxHr: number;
  lastUpdated: string;
  sportsZones: SportsZones;
}

export interface ApiMetrics {
  _id: string;
  user_id: string;
  weight_kg: number;
  resting_hr_bpm: number;
  max_hr_bpm: number;
  last_updated: string;
  sports_zones?: {
    running?: any;
    cycling?: any;
    swimming?: any;
  };
}

export interface MetricsResult {
  success: boolean;
  metrics?: UserMetrics;
  error?: string;
}

class MetricsService {
  /**
   * Récupérer les métriques d'un utilisateur depuis l'API dédiée
   */
  async getMetrics(userId: string, forceRefresh: boolean = false): Promise<MetricsResult> {
    try {
      const params: Record<string, string> = { user_id: userId };
      if (forceRefresh) {
        params.refresh = 'true';
      }

      const response = await apiService.get<ApiMetrics>('/metrics', params);
      const metrics = this.convertApiToFrontend(response);

      return {
        success: true,
        metrics,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Forcer le rafraîchissement des métriques
   */
  async refreshMetrics(userId: string): Promise<MetricsResult> {
    return this.getMetrics(userId, true);
  }

  /**
   * Mettre à jour les métriques biométriques d'un utilisateur
   */
  async updateMetrics(userId: string, data: Partial<ApiMetrics>): Promise<MetricsResult> {
    try {
      const response = await apiService.put<ApiMetrics>('/metrics', { ...data, user_id: userId });
      const metrics = this.convertApiToFrontend(response);

      return {
        success: true,
        metrics,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Convertir les données API vers le format frontend
   */
  convertApiToFrontend(apiMetrics: ApiMetrics): UserMetrics {
    return {
      id: apiMetrics._id,
      userId: apiMetrics.user_id,
      weight: apiMetrics.weight_kg,
      restingHr: apiMetrics.resting_hr_bpm,
      maxHr: apiMetrics.max_hr_bpm,
      lastUpdated: apiMetrics.last_updated,
      sportsZones: {
        running: this.convertRunningZones(apiMetrics.sports_zones?.running),
        cycling: this.convertCyclingZones(apiMetrics.sports_zones?.cycling),
        swimming: this.convertSwimmingZones(apiMetrics.sports_zones?.swimming),
      },
    };
  }

  /**
   * Convertir les zones de course à pied
   */
  private convertRunningZones(runningData: any): RunningZones | null {
    if (!runningData) return null;

    return {
      lactateThresholdHr: runningData.lactate_threshold_hr_bpm,
      thresholdPace: runningData.threshold_pace_per_km,
      heartRateZones: [
        {
          zone: 1,
          name: 'Récupération active',
          min: runningData.zone_1?.min || 0,
          max: runningData.zone_1?.max || 0,
          pace: runningData.pace_zones?.zone_1 || '',
          color: '#10B981',
          description: 'Récupération et échauffement',
        },
        {
          zone: 2,
          name: 'Endurance fondamentale',
          min: runningData.zone_2?.min || 0,
          max: runningData.zone_2?.max || 0,
          pace: runningData.pace_zones?.zone_2 || '',
          color: '#3B82F6',
          description: 'Base aérobie',
        },
        {
          zone: 3,
          name: 'Endurance active',
          min: runningData.zone_3?.min || 0,
          max: runningData.zone_3?.max || 0,
          pace: runningData.pace_zones?.zone_3 || '',
          color: '#F59E0B',
          description: 'Tempo modéré',
        },
        {
          zone: 4,
          name: 'Seuil lactique',
          min: runningData.zone_4?.min || 0,
          max: runningData.zone_4?.max || 0,
          pace: runningData.pace_zones?.zone_4 || '',
          color: '#EF4444',
          description: 'Seuil anaérobie',
        },
        {
          zone: 5,
          name: 'VO2 Max',
          min: runningData.zone_5?.min || 0,
          max: runningData.zone_5?.max || 0,
          pace: runningData.pace_zones?.zone_5 || '',
          color: '#DC2626',
          description: 'Puissance aérobie maximale',
        },
        {
          zone: 6,
          name: 'Neuromusculaire',
          min: runningData.zone_6?.min || 0,
          max: runningData.zone_6?.max || 0,
          pace: runningData.pace_zones?.zone_6 || '',
          color: '#7C2D12',
          description: 'Vitesse maximale',
        },
      ],
    };
  }

  /**
   * Convertir les zones de cyclisme
   */
  private convertCyclingZones(cyclingData: any): CyclingZones | null {
    if (!cyclingData) return null;

    return {
      ftp: cyclingData.ftp_watts,
      powerZones: [
        {
          zone: 1,
          name: 'Récupération active',
          min: cyclingData.zone_1?.min || 0,
          max: cyclingData.zone_1?.max || 0,
          percentage: '< 55%',
          color: '#10B981',
          description: 'Récupération et échauffement',
        },
        {
          zone: 2,
          name: 'Endurance',
          min: cyclingData.zone_2?.min || 0,
          max: cyclingData.zone_2?.max || 0,
          percentage: '56-75%',
          color: '#3B82F6',
          description: 'Base aérobie',
        },
        {
          zone: 3,
          name: 'Tempo',
          min: cyclingData.zone_3?.min || 0,
          max: cyclingData.zone_3?.max || 0,
          percentage: '76-90%',
          color: '#F59E0B',
          description: 'Effort soutenu',
        },
        {
          zone: 4,
          name: 'Seuil lactique',
          min: cyclingData.zone_4?.min || 0,
          max: cyclingData.zone_4?.max || 0,
          percentage: '91-105%',
          color: '#EF4444',
          description: 'Seuil FTP',
        },
        {
          zone: 5,
          name: 'VO2 Max',
          min: cyclingData.zone_5?.min || 0,
          max: cyclingData.zone_5?.max || 0,
          percentage: '106-120%',
          color: '#DC2626',
          description: 'Puissance aérobie maximale',
        },
        {
          zone: 6,
          name: 'Neuromusculaire',
          min: cyclingData.zone_6?.min || 0,
          max: cyclingData.zone_6?.max || 0,
          percentage: '> 120%',
          color: '#7C2D12',
          description: 'Puissance maximale',
        },
      ],
    };
  }

  /**
   * Convertir les zones de natation
   */
  private convertSwimmingZones(swimmingData: any): SwimmingZones | null {
    if (!swimmingData) return null;

    return {
      cssPace: swimmingData.css_pace_per_100m,
      paceZones: [
        {
          zone: 1,
          name: 'Récupération',
          pace: swimmingData.zone_1 || '',
          color: '#10B981',
          description: 'Nage facile et technique',
        },
        {
          zone: 2,
          name: 'Endurance',
          pace: swimmingData.zone_2 || '',
          color: '#3B82F6',
          description: 'Base aérobie',
        },
        {
          zone: 3,
          name: 'Tempo',
          pace: swimmingData.zone_3 || '',
          color: '#F59E0B',
          description: 'Effort soutenu',
        },
        {
          zone: 4,
          name: 'Seuil',
          pace: swimmingData.zone_4 || '',
          color: '#EF4444',
          description: 'Seuil CSS',
        },
        {
          zone: 5,
          name: 'VO2 Max',
          pace: swimmingData.zone_5 || '',
          color: '#DC2626',
          description: 'Vitesse maximale',
        },
      ],
    };
  }

  /**
   * Obtenir les zones d'un sport spécifique
   */
  getZonesBySport(metrics: UserMetrics, sport: 'running' | 'cycling' | 'swimming'): HeartRateZone[] | PowerZone[] | PaceZone[] {
    if (!metrics?.sportsZones?.[sport]) return [];

    switch (sport) {
      case 'running':
        return metrics.sportsZones.running?.heartRateZones || [];
      case 'cycling':
        return metrics.sportsZones.cycling?.powerZones || [];
      case 'swimming':
        return metrics.sportsZones.swimming?.paceZones || [];
      default:
        return [];
    }
  }
}

export const metricsService = new MetricsService();
export default metricsService;
