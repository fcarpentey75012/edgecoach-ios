/**
 * Service Activities pour EdgeCoach iOS
 * Gestion de l'historique des activités/séances effectuées
 */

import apiService from './api';

// Types
export interface ActivityZone {
  zone: number;
  time_seconds: number;
  percentage: number;
}

export interface ActivityFileData {
  records?: any[];
  laps?: any[];
  all_laps?: any[];
  distance?: number;
  duration?: number;
  ascent?: number;
  descent?: number;
  avg_speed?: number;
  max_speed?: number;
  hr_avg?: number;
  hr_max?: number;
  hr_min?: number;
  cadence_avg?: number;
  cadence_max?: number;
  calories?: number;
  start_time?: string;
  end_time?: string;
  altitude_avg?: number;
  altitude_min?: number;
  altitude_max?: number;
  tpx_ext_stats?: any;
}

export interface Activity {
  id: string;
  odometer_id?: string;
  user_id: string;
  date: string;
  type: 'completed';
  discipline: 'cyclisme' | 'course' | 'natation' | 'autre';
  name: string;
  title: string;

  // Données de la séance
  duration: string | null;
  distance: string | null;
  pace: string | null;
  avgWatt: number | null;
  maxWatt: number | null;
  rpe: number | null;
  feeling: string | null;

  // Métadonnées
  elevationGain: number | null;
  elevationLoss: number | null;
  loadFoster: number | null;
  loadCoggan: number | null;
  isCompetition: boolean;
  kilojoules: number | null;

  // Métriques physiques
  restHr: number | null;
  maxHr: number | null;
  normalizedPower: number | null;
  ftp: number | null;
  weight: number | null;

  // Zones
  zones: ActivityZone[] | null;

  // Fichier
  fileUrl: string | null;
  fileData: ActivityFileData | null;

  // Données de séance prévue (si existe)
  plannedName: string | null;
  plannedSport: string | null;
  plannedDescription: string | null;

  // Description et notes
  description: string | null;
  notes: string | null;
  coachInstructions: string | null;

  // Heure
  scheduledTime: string | null;
  timeOfDay: string | null;

  // Timestamps
  createdAt: string;
  updatedAt: string;
}

export interface ApiActivity {
  _id: string;
  nolio_id?: string;
  user_id: string;
  date_start: string;
  sport: string;
  name: string;
  duration: number;
  distance: number;
  avg_watt?: number;
  max_watt?: number;
  rpe?: number;
  feeling?: string;
  elevation_gain?: number;
  elevation_loss?: number;
  load_foster?: number;
  load_coggan?: number;
  is_competition?: boolean;
  kilojoules?: number;
  rest_hr_user?: number;
  max_hr_user?: number;
  np?: number;
  ftp?: number;
  weight?: number;
  zones?: any[];
  file_url?: string;
  file_datas?: any;
  planned_name?: string;
  planned_sport?: string;
  planned_description?: string;
  description?: string;
  hour_start?: string;
  cached_at?: string;
}

export interface ActivitiesResult {
  success: boolean;
  activities?: Activity[];
  error?: string;
}

class ActivitiesService {
  /**
   * Récupérer l'historique des activités pour une période
   */
  async getHistory(
    userId: string,
    startDate: string,
    endDate: string,
    forceApiCall: boolean = false
  ): Promise<ActivitiesResult> {
    try {
      const params: Record<string, string> = {
        user_id: userId,
        start_date: startDate,
        end_date: endDate,
      };

      if (forceApiCall) {
        params.force_api_call = 'true';
      }

      const response = await apiService.get<ApiActivity[]>('/activities/history', params);
      const activities = response.map(activity => this.convertApiToFrontend(activity));

      return {
        success: true,
        activities,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Récupérer les activités d'un mois
   */
  async getMonthActivities(userId: string, year: number, month: number): Promise<ActivitiesResult> {
    const startDate = new Date(year, month, 1);
    const endDate = new Date(year, month + 1, 0);

    const startStr = startDate.toISOString().split('T')[0];
    const endStr = endDate.toISOString().split('T')[0];

    return this.getHistory(userId, startStr, endStr);
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
  private formatDuration(seconds: number | undefined): string | null {
    if (!seconds) return null;
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return hours > 0 ? `${hours}:${minutes.toString().padStart(2, '0')}` : `${minutes}min`;
  }

  /**
   * Convertir les données API vers le format frontend
   */
  convertApiToFrontend(apiActivity: ApiActivity): Activity {
    // Mapper les sports vers les disciplines
    const disciplineMap: Record<string, 'cyclisme' | 'course' | 'natation' | 'autre'> = {
      'Vélo - Route': 'cyclisme',
      'Vélo': 'cyclisme',
      'Vélo - Home Trainer': 'cyclisme',
      'Cycling': 'cyclisme',
      'Course à pied': 'course',
      'course à pied': 'course',
      'Running': 'course',
      'Natation': 'natation',
      'Swimming': 'natation',
    };

    const discipline = disciplineMap[apiActivity.sport] || 'autre';

    return {
      id: `history_${apiActivity.nolio_id || apiActivity._id}`,
      odometer_id: apiActivity._id,
      user_id: apiActivity.user_id,
      date: apiActivity.date_start,
      type: 'completed',
      discipline,
      name: apiActivity.name,
      title: apiActivity.name,

      // Données de la séance
      duration: this.formatDuration(apiActivity.duration),
      distance: this.formatDistance(apiActivity.distance ? apiActivity.distance * 1000 : undefined, discipline),
      pace: apiActivity.avg_watt ? `${apiActivity.avg_watt}W avg` : null,
      avgWatt: apiActivity.avg_watt || null,
      maxWatt: apiActivity.max_watt || null,
      rpe: apiActivity.rpe || null,
      feeling: apiActivity.feeling || null,

      // Métadonnées
      elevationGain: apiActivity.elevation_gain || null,
      elevationLoss: apiActivity.elevation_loss || null,
      loadFoster: apiActivity.load_foster || null,
      loadCoggan: apiActivity.load_coggan || null,
      isCompetition: apiActivity.is_competition || false,
      kilojoules: apiActivity.kilojoules || null,

      // Métriques physiques
      restHr: apiActivity.rest_hr_user || null,
      maxHr: apiActivity.max_hr_user || null,
      normalizedPower: apiActivity.np || null,
      ftp: apiActivity.ftp || null,
      weight: apiActivity.weight || null,

      // Zones
      zones: apiActivity.zones || null,

      // Fichier
      fileUrl: apiActivity.file_url || null,
      fileData: apiActivity.file_datas || null,

      // Données de séance prévue
      plannedName: apiActivity.planned_name || null,
      plannedSport: apiActivity.planned_sport || null,
      plannedDescription: apiActivity.planned_description || null,

      // Description et notes
      description: apiActivity.description || apiActivity.planned_description || null,
      notes: apiActivity.planned_description || null,
      coachInstructions: apiActivity.planned_description || null,

      // Heure
      scheduledTime: apiActivity.hour_start || null,
      timeOfDay: apiActivity.hour_start || null,

      // Timestamps
      createdAt: apiActivity.cached_at || new Date().toISOString(),
      updatedAt: apiActivity.cached_at || new Date().toISOString(),
    };
  }

  /**
   * Obtenir les activités groupées par date
   */
  groupByDate(activities: Activity[]): Record<string, Activity[]> {
    return activities.reduce((groups, activity) => {
      const date = activity.date.split('T')[0];
      if (!groups[date]) {
        groups[date] = [];
      }
      groups[date].push(activity);
      return groups;
    }, {} as Record<string, Activity[]>);
  }

  /**
   * Récupérer les données GPS détaillées (record_data) pour une activité
   * Utilise le paramètre records=true de l'API
   */
  async getActivityGPSData(
    userId: string,
    activityDate: string,
    forceReload: boolean = false
  ): Promise<{ success: boolean; recordData?: any[]; fileData?: any; error?: string }> {
    try {
      // Récupérer les données avec records=true
      // force_api_call=true pour s'assurer d'avoir les record_data
      const params: Record<string, string> = {
        user_id: userId,
        start_date: activityDate,
        end_date: activityDate,
        records: 'true',
        force_api_call: forceReload ? 'true' : 'false',
      };

      const response = await apiService.get<ApiActivity[]>('/activities/history', params);

      console.log('GPS API Response:', {
        activityCount: response?.length,
        firstActivity: response?.[0] ? {
          id: response[0]._id,
          hasFileDatas: !!response[0].file_datas,
          fileDatasKeys: response[0].file_datas ? Object.keys(response[0].file_datas) : [],
          hasRecordData: !!response[0].file_datas?.record_data,
          recordDataLength: response[0].file_datas?.record_data?.length,
        } : null,
      });

      if (response && response.length > 0) {
        const activity = response[0];
        // Les record_data sont dans file_datas.record_data ou file_datas.records
        const recordData = activity.file_datas?.record_data ||
                          activity.file_datas?.records ||
                          [];

        console.log('GPS recordData found:', recordData?.length || 0, 'points');
        console.log('GPS fileData keys:', activity.file_datas ? Object.keys(activity.file_datas) : []);
        console.log('GPS avg_speed_moving_kmh:', activity.file_datas?.avg_speed_moving_kmh);

        return {
          success: true,
          recordData,
          fileData: activity.file_datas, // Retourner aussi les fileData avec avg_speed_moving_kmh
        };
      }

      return {
        success: false,
        error: 'Aucune activité trouvée',
      };
    } catch (error: any) {
      console.error('Error fetching GPS data:', error);
      return {
        success: false,
        error: error.message || 'Erreur lors de la récupération des données GPS',
      };
    }
  }

  /**
   * Récupérer les données GPS pour une activité par son ID MongoDB
   */
  async getActivityGPSDataByMongoId(
    userId: string,
    mongoId: string,
    activityDate: string
  ): Promise<{ success: boolean; recordData?: any[]; error?: string }> {
    try {
      // Récupérer toutes les activités du jour avec records=true
      const result = await this.getActivityGPSData(userId, activityDate);

      if (!result.success) {
        return result;
      }

      // Si on a directement les données, les retourner
      if (result.recordData && result.recordData.length > 0) {
        return result;
      }

      return {
        success: false,
        error: 'Aucune donnée GPS trouvée pour cette activité',
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }
}

export const activitiesService = new ActivitiesService();
export default activitiesService;
