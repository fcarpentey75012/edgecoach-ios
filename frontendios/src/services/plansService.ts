/**
 * Service Plans pour EdgeCoach iOS
 * Gestion des plans d'entraînement et séances prévues
 */

import apiService from './api';

// Types
export interface PlannedActivity {
  id: string;
  date: string;
  sport: string;
  nom: string;
  duree: number; // en minutes
  volume?: number; // en mètres
  intensite?: string;
  type?: string;
  zone?: string;
  focus?: string;
  description?: string;
  educatifs?: string[];
}

export interface TrainingPlanData {
  _id: string;
  user_id: string;
  ia_answer: {
    activities_json: {
      plan: PlannedActivity[];
    };
  };
  created_at: string;
  updated_at?: string;
}

export interface PlannedSession {
  id: string;
  userId: string;
  date: string;
  type: 'planned';
  discipline: 'cyclisme' | 'course' | 'natation' | 'autre';
  name: string;
  title: string;
  estimatedDuration: string;
  estimatedDistance: string | null;
  targetPace: string | null;
  intensity: string | null;
  zone: string | null;
  focus: string | null;
  scheduledTime: string | null;
  timeOfDay: string | null;
  description: string | null;
  notes: string | null;
  coachInstructions: string | null;
  educatifs: string[];
  createdAt: string;
  updatedAt: string;
}

export interface PlansResult {
  success: boolean;
  sessions?: PlannedSession[];
  error?: string;
}

export interface UpdateSessionResult {
  success: boolean;
  error?: string;
}

class PlansService {
  /**
   * Récupérer le dernier plan d'entraînement
   */
  async getLastPlan(userId: string): Promise<PlansResult> {
    try {
      const response = await apiService.get<TrainingPlanData>('/plans/last', { user_id: userId });
      const sessions = this.convertPlanToSessions(response);

      return {
        success: true,
        sessions,
      };
    } catch (error: any) {
      // "Aucun plan" n'est pas une erreur critique
      if (error.message.includes('Aucun plan') || error.message.includes('No training plan')) {
        return {
          success: true,
          sessions: [],
        };
      }

      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Formater la distance selon la discipline
   */
  private formatDistance(volume: number | undefined, discipline: string): string | null {
    if (!volume) return null;

    const normalizedDiscipline = discipline?.toLowerCase();

    // Pour cyclisme et course, convertir en km
    if (normalizedDiscipline === 'cyclisme' || normalizedDiscipline === 'course') {
      const km = volume / 1000;
      return km % 1 === 0 ? `${km} km` : `${km.toFixed(1)} km`;
    }

    // Pour natation, garder en mètres
    return `${volume} m`;
  }

  /**
   * Formater la durée en HH:MM
   */
  private formatDuration(minutes: number): string {
    const hours = Math.floor(minutes / 60);
    const mins = minutes % 60;
    return hours > 0
      ? `${hours}:${mins.toString().padStart(2, '0')}`
      : `${mins}min`;
  }

  /**
   * Convertir un plan en sessions
   */
  convertPlanToSessions(planData: TrainingPlanData): PlannedSession[] {
    if (!planData?.ia_answer?.activities_json?.plan) {
      return [];
    }

    // Mapper les sports vers les disciplines
    const disciplineMap: Record<string, 'cyclisme' | 'course' | 'natation' | 'autre'> = {
      'Cyclisme': 'cyclisme',
      'Course à pied': 'course',
      'Natation': 'natation',
    };

    return planData.ia_answer.activities_json.plan.map(activity => {
      const discipline = disciplineMap[activity.sport] || 'autre';

      return {
        id: `plan_${activity.id}`,
        userId: planData.user_id,
        date: activity.date,
        type: 'planned' as const,
        discipline,
        name: activity.nom,
        title: activity.nom,
        estimatedDuration: this.formatDuration(activity.duree),
        estimatedDistance: this.formatDistance(activity.volume, discipline),
        targetPace: activity.intensite || null,
        intensity: activity.type || null,
        zone: activity.zone || null,
        focus: activity.focus || null,
        scheduledTime: null,
        timeOfDay: null,
        description: activity.description || null,
        notes: activity.focus || null,
        coachInstructions: activity.description || null,
        educatifs: activity.educatifs || [],
        createdAt: planData.created_at,
        updatedAt: planData.updated_at || planData.created_at,
      };
    });
  }

  /**
   * Obtenir les sessions prévues pour un mois donné
   */
  filterByMonth(sessions: PlannedSession[], year: number, month: number): PlannedSession[] {
    return sessions.filter(session => {
      const date = new Date(session.date);
      return date.getFullYear() === year && date.getMonth() === month;
    });
  }

  /**
   * Obtenir les sessions groupées par date
   */
  groupByDate(sessions: PlannedSession[]): Record<string, PlannedSession[]> {
    return sessions.reduce((groups, session) => {
      const date = session.date.split('T')[0];
      if (!groups[date]) {
        groups[date] = [];
      }
      groups[date].push(session);
      return groups;
    }, {} as Record<string, PlannedSession[]>);
  }

  /**
   * Mettre à jour le nom d'une séance prévue
   * @param userId - ID de l'utilisateur
   * @param sessionId - ID de la séance (format: plan_xxx)
   * @param newName - Nouveau nom de la séance
   */
  async updateSessionName(userId: string, sessionId: string, newName: string): Promise<UpdateSessionResult> {
    try {
      // Extraire l'ID original (enlever le préfixe "plan_")
      const originalId = sessionId.replace('plan_', '');

      await apiService.put('/plans/session/rename', {
        user_id: userId,
        session_id: originalId,
        new_name: newName,
      });

      return { success: true };
    } catch (error: any) {
      return {
        success: false,
        error: error.message || 'Erreur lors de la mise à jour du nom',
      };
    }
  }
}

export const plansService = new PlansService();
export default plansService;
