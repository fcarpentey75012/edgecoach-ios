/**
 * Service Dashboard pour EdgeCoach iOS
 * Gestion des données du tableau de bord (résumé hebdomadaire, etc.)
 */

import apiService from './api';

// Types pour le résumé hebdomadaire
export interface WeeklySummary {
  totalDuration: number; // en secondes
  totalDistance: number; // en mètres
  sessionsCount: number;
  totalElevation: number;
  totalCalories: number;
}

export interface DisciplineStats {
  count: number;
  duration: number; // en secondes
  distance: number; // en mètres
}

export interface ByDiscipline {
  cyclisme: DisciplineStats;
  course: DisciplineStats;
  natation: DisciplineStats;
  autre: DisciplineStats;
}

// Types pour les séances par discipline
export type DisciplineType = 'cyclisme' | 'course' | 'natation' | 'autre';

export interface SessionDetail {
  id: string;
  date: string;
  sport: string;
  discipline: DisciplineType;
  name: string;
  duration: number; // en secondes
  distance: number; // en mètres
  elevation: number;
  calories: number;
  avgHr: number | null;
  avgPower: number | null;
}

export interface SessionsByDisciplineData {
  weekStart: string;
  weekEnd: string;
  discipline: DisciplineType;
  sessions: SessionDetail[];
  count: number;
}

export interface SessionsByDisciplineResult {
  success: boolean;
  data?: SessionsByDisciplineData;
  error?: string;
}

export interface UpcomingSession {
  id: string;
  date: string;
  sport: string;
  name: string;
  duration: number; // en minutes
  distance: number | null; // en mètres
}

export interface WeekProgress {
  targetDuration: number; // en secondes
  achievedDuration: number; // en secondes
  percentage: number;
}

export interface WeeklySummaryData {
  weekStart: string;
  weekEnd: string;
  summary: WeeklySummary;
  byDiscipline: ByDiscipline;
  upcomingSessions: UpcomingSession[];
  weekProgress: WeekProgress;
}

// Type de réponse API
interface ApiWeeklySummaryResponse {
  status: string;
  data: {
    week_start: string;
    week_end: string;
    summary: {
      total_duration: number;
      total_distance: number;
      sessions_count: number;
      total_elevation: number;
      total_calories: number;
    };
    by_discipline: {
      cyclisme: { count: number; duration: number; distance: number };
      course: { count: number; duration: number; distance: number };
      natation: { count: number; duration: number; distance: number };
      autre: { count: number; duration: number; distance: number };
    };
    upcoming_sessions: Array<{
      id: string;
      date: string;
      sport: string;
      name: string;
      duration: number;
      distance: number | null;
    }>;
    week_progress: {
      target_duration: number;
      achieved_duration: number;
      percentage: number;
    };
  };
}

export interface WeeklySummaryResult {
  success: boolean;
  data?: WeeklySummaryData;
  error?: string;
}

class DashboardService {
  /**
   * Récupérer le résumé hebdomadaire pour le dashboard
   */
  async getWeeklySummary(userId: string, weekStart?: string): Promise<WeeklySummaryResult> {
    try {
      const params: Record<string, string> = { user_id: userId };
      if (weekStart) {
        params.week_start = weekStart;
      }

      const response = await apiService.get<ApiWeeklySummaryResponse>(
        '/dashboard/weekly-summary',
        params
      );

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
          data: this.getEmptyWeeklySummary(),
        };
      }

      return {
        success: false,
        error: error.message || 'Erreur lors de la récupération du résumé hebdomadaire',
      };
    }
  }

  /**
   * Convertir les données API vers le format frontend (camelCase)
   */
  private convertApiToFrontend(apiData: ApiWeeklySummaryResponse['data']): WeeklySummaryData {
    return {
      weekStart: apiData.week_start,
      weekEnd: apiData.week_end,
      summary: {
        totalDuration: apiData.summary.total_duration,
        totalDistance: apiData.summary.total_distance,
        sessionsCount: apiData.summary.sessions_count,
        totalElevation: apiData.summary.total_elevation,
        totalCalories: apiData.summary.total_calories,
      },
      byDiscipline: {
        cyclisme: apiData.by_discipline.cyclisme,
        course: apiData.by_discipline.course,
        natation: apiData.by_discipline.natation,
        autre: apiData.by_discipline.autre,
      },
      upcomingSessions: apiData.upcoming_sessions.map(session => ({
        id: session.id,
        date: session.date,
        sport: session.sport,
        name: session.name,
        duration: session.duration,
        distance: session.distance,
      })),
      weekProgress: {
        targetDuration: apiData.week_progress.target_duration,
        achievedDuration: apiData.week_progress.achieved_duration,
        percentage: apiData.week_progress.percentage,
      },
    };
  }

  /**
   * Retourner un résumé hebdomadaire vide (pour fallback)
   */
  getEmptyWeeklySummary(): WeeklySummaryData {
    const today = new Date();
    const dayOfWeek = today.getDay();
    const monday = new Date(today);
    monday.setDate(today.getDate() - (dayOfWeek === 0 ? 6 : dayOfWeek - 1));
    const sunday = new Date(monday);
    sunday.setDate(monday.getDate() + 6);

    return {
      weekStart: monday.toISOString().split('T')[0],
      weekEnd: sunday.toISOString().split('T')[0],
      summary: {
        totalDuration: 0,
        totalDistance: 0,
        sessionsCount: 0,
        totalElevation: 0,
        totalCalories: 0,
      },
      byDiscipline: {
        cyclisme: { count: 0, duration: 0, distance: 0 },
        course: { count: 0, duration: 0, distance: 0 },
        natation: { count: 0, duration: 0, distance: 0 },
        autre: { count: 0, duration: 0, distance: 0 },
      },
      upcomingSessions: [],
      weekProgress: {
        targetDuration: 0,
        achievedDuration: 0,
        percentage: 0,
      },
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
   * Récupérer les séances d'une discipline pour la semaine
   */
  async getSessionsByDiscipline(
    userId: string,
    discipline: DisciplineType,
    weekStart?: string
  ): Promise<SessionsByDisciplineResult> {
    try {
      const params: Record<string, string> = {
        user_id: userId,
        discipline,
      };
      if (weekStart) {
        params.week_start = weekStart;
      }

      const response = await apiService.get<{
        status: string;
        data: {
          week_start: string;
          week_end: string;
          discipline: DisciplineType;
          sessions: Array<{
            id: string;
            date: string;
            sport: string;
            discipline: DisciplineType;
            name: string;
            duration: number;
            distance: number;
            elevation: number;
            calories: number;
            avg_hr: number | null;
            avg_power: number | null;
          }>;
          count: number;
        };
      }>('/dashboard/sessions', params);

      return {
        success: true,
        data: {
          weekStart: response.data.week_start,
          weekEnd: response.data.week_end,
          discipline: response.data.discipline,
          sessions: response.data.sessions.map(s => ({
            id: s.id,
            date: s.date,
            sport: s.sport,
            discipline: s.discipline,
            name: s.name,
            duration: s.duration,
            distance: s.distance,
            elevation: s.elevation,
            calories: s.calories,
            avgHr: s.avg_hr,
            avgPower: s.avg_power,
          })),
          count: response.data.count,
        },
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Erreur lors de la récupération des séances',
      };
    }
  }

  /**
   * Obtenir le nom français de la discipline
   */
  getDisciplineName(discipline: DisciplineType): string {
    const names: Record<DisciplineType, string> = {
      cyclisme: 'Vélo',
      course: 'Course',
      natation: 'Natation',
      autre: 'Autre',
    };
    return names[discipline];
  }

  /**
   * Obtenir l'icône pour une discipline
   */
  getDisciplineIcon(discipline: DisciplineType): string {
    const icons: Record<DisciplineType, string> = {
      cyclisme: 'bicycle',
      course: 'walk',
      natation: 'water',
      autre: 'fitness',
    };
    return icons[discipline];
  }
}

export const dashboardService = new DashboardService();
export default dashboardService;
