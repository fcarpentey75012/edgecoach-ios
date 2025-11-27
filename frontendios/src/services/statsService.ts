/**
 * Service Stats pour EdgeCoach iOS
 * Gestion des statistiques d'entraînement par période (semaine, mois, année)
 */

import apiService from './api';

// Types
export type StatsPeriod = 'week' | 'month' | 'year';

export interface StatsSummary {
  totalDuration: number; // en secondes
  totalDistance: number; // en mètres
  totalCalories: number;
  sessionsCount: number;
}

export interface DisciplineStats {
  duration: number; // en secondes
  distance: number; // en mètres
  percentage: number;
}

export interface ByDisciplineStats {
  cyclisme: DisciplineStats;
  course: DisciplineStats;
  natation: DisciplineStats;
}

export interface PerformanceMetrics {
  ftp: number | null; // Watts
  maxHr: number | null; // bpm
  vma: number | null; // km/h
  css: string | null; // pace format "1:45/100m"
}

export interface EvolutionPoint {
  date: string; // YYYY-MM-DD
  duration: number; // en secondes
  distance: number; // en mètres
}

export interface StatsData {
  period: StatsPeriod;
  startDate: string;
  endDate: string;
  summary: StatsSummary;
  byDiscipline: ByDisciplineStats;
  performanceMetrics: PerformanceMetrics;
  evolution: EvolutionPoint[];
}

// Types API
interface ApiStatsResponse {
  status: string;
  data: {
    period: StatsPeriod;
    start_date: string;
    end_date: string;
    summary: {
      total_duration: number;
      total_distance: number;
      total_calories: number;
      sessions_count: number;
    };
    by_discipline: {
      cyclisme: { duration: number; distance: number; percentage: number };
      course: { duration: number; distance: number; percentage: number };
      natation: { duration: number; distance: number; percentage: number };
    };
    performance_metrics: {
      ftp: number | null;
      max_hr: number | null;
      vma: number | null;
      css: string | null;
    };
    evolution: Array<{
      date: string;
      duration: number;
      distance: number;
    }>;
  };
}

export interface StatsResult {
  success: boolean;
  data?: StatsData;
  error?: string;
}

class StatsService {
  /**
   * Récupérer les statistiques pour une période donnée
   */
  async getStats(
    userId: string,
    period: StatsPeriod = 'week',
    referenceDate?: string
  ): Promise<StatsResult> {
    try {
      const params: Record<string, string> = {
        user_id: userId,
        period,
      };

      if (referenceDate) {
        params.reference_date = referenceDate;
      }

      console.log(`[statsService] Calling /stats with params:`, params);
      const response = await apiService.get<ApiStatsResponse>('/stats', params);
      console.log(`[statsService] Response for period=${period}:`, {
        start: response.data.start_date,
        end: response.data.end_date,
        sessionsCount: response.data.summary.sessions_count,
        totalDuration: response.data.summary.total_duration,
      });
      const data = this.convertApiToFrontend(response.data);

      return {
        success: true,
        data,
      };
    } catch (error: any) {
      // Si l'endpoint n'existe pas encore, retourner des données vides
      if (error.response?.status === 404) {
        return {
          success: true,
          data: this.getEmptyStats(period),
        };
      }

      return {
        success: false,
        error: error.message || 'Erreur lors de la récupération des statistiques',
      };
    }
  }

  /**
   * Raccourci pour les stats hebdomadaires
   */
  async getWeeklyStats(userId: string): Promise<StatsResult> {
    return this.getStats(userId, 'week');
  }

  /**
   * Raccourci pour les stats mensuelles
   */
  async getMonthlyStats(userId: string): Promise<StatsResult> {
    return this.getStats(userId, 'month');
  }

  /**
   * Raccourci pour les stats annuelles
   */
  async getYearlyStats(userId: string): Promise<StatsResult> {
    return this.getStats(userId, 'year');
  }

  /**
   * Convertir les données API vers le format frontend (camelCase)
   */
  private convertApiToFrontend(apiData: ApiStatsResponse['data']): StatsData {
    return {
      period: apiData.period,
      startDate: apiData.start_date,
      endDate: apiData.end_date,
      summary: {
        totalDuration: apiData.summary.total_duration,
        totalDistance: apiData.summary.total_distance,
        totalCalories: apiData.summary.total_calories,
        sessionsCount: apiData.summary.sessions_count,
      },
      byDiscipline: {
        cyclisme: apiData.by_discipline.cyclisme,
        course: apiData.by_discipline.course,
        natation: apiData.by_discipline.natation,
      },
      performanceMetrics: {
        ftp: apiData.performance_metrics.ftp,
        maxHr: apiData.performance_metrics.max_hr,
        vma: apiData.performance_metrics.vma,
        css: apiData.performance_metrics.css,
      },
      evolution: apiData.evolution.map(point => ({
        date: point.date,
        duration: point.duration,
        distance: point.distance,
      })),
    };
  }

  /**
   * Retourner des stats vides (pour fallback)
   */
  getEmptyStats(period: StatsPeriod = 'week'): StatsData {
    const today = new Date();
    let startDate: Date;
    let endDate: Date;

    if (period === 'week') {
      const dayOfWeek = today.getDay();
      startDate = new Date(today);
      startDate.setDate(today.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1));
      endDate = new Date(startDate);
      endDate.setDate(startDate.getDate() + 6);
    } else if (period === 'month') {
      startDate = new Date(today.getFullYear(), today.getMonth(), 1);
      endDate = new Date(today.getFullYear(), today.getMonth() + 1, 0);
    } else {
      startDate = new Date(today.getFullYear(), 0, 1);
      endDate = new Date(today.getFullYear(), 11, 31);
    }

    return {
      period,
      startDate: startDate.toISOString().split('T')[0],
      endDate: endDate.toISOString().split('T')[0],
      summary: {
        totalDuration: 0,
        totalDistance: 0,
        totalCalories: 0,
        sessionsCount: 0,
      },
      byDiscipline: {
        cyclisme: { duration: 0, distance: 0, percentage: 0 },
        course: { duration: 0, distance: 0, percentage: 0 },
        natation: { duration: 0, distance: 0, percentage: 0 },
      },
      performanceMetrics: {
        ftp: null,
        maxHr: null,
        vma: null,
        css: null,
      },
      evolution: [],
    };
  }

  /**
   * Formater la durée en format lisible (ex: "2h30" ou "45min")
   */
  formatDuration(seconds: number): string {
    if (seconds === 0) return '0h';
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);

    if (hours > 0) {
      return minutes > 0 ? `${hours}h${minutes.toString().padStart(2, '0')}` : `${hours}h`;
    }
    return `${minutes}min`;
  }

  /**
   * Formater la distance en format lisible (ex: "45.5 km" ou "1500 m")
   */
  formatDistance(meters: number, discipline?: string): string {
    if (meters === 0) return '0 km';

    // Natation en mètres si < 10km
    if (discipline === 'natation' && meters < 10000) {
      return `${meters} m`;
    }

    // Autres sports en km
    const km = meters / 1000;
    return km % 1 === 0 ? `${km} km` : `${km.toFixed(1)} km`;
  }

  /**
   * Formater les calories
   */
  formatCalories(calories: number): string {
    if (calories === 0) return '0';
    if (calories >= 1000) {
      return `${(calories / 1000).toFixed(1)}k`;
    }
    return calories.toString();
  }

  /**
   * Obtenir le label de la période
   */
  getPeriodLabel(period: StatsPeriod): string {
    const labels: Record<StatsPeriod, string> = {
      week: 'Semaine',
      month: 'Mois',
      year: 'Année',
    };
    return labels[period];
  }
}

export const statsService = new StatsService();
export default statsService;
