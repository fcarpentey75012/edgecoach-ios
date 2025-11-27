/**
 * Service User Metrics pour EdgeCoach iOS
 * Gestion des métriques personnelles utilisateur (poids, FC, objectifs, etc.)
 */

import apiService from './api';

// Types
export interface UserMetricsData {
  height: string;
  weight: string;
  weeklyVolume: string;
  primaryGoal: string;
  availableDays: string;
  preferredTrainingTime: string;
  equipment: string;
  medicalConditions: string;
  ftp: string;
  lthr: string;
  maxHr: string;
  restHr: string;
  vo2Max: string;
}

export interface ApiUserMetrics {
  height?: number;
  weight?: number;
  weekly_volume?: number;
  primary_goal?: string;
  available_days?: number;
  preferred_training_time?: string;
  equipment?: string;
  medical_conditions?: string;
  ftp?: number;
  lthr?: number;
  max_hr?: number;
  rest_hr?: number;
  vo2_max?: number;
}

export interface UserMetricsResult {
  success: boolean;
  metrics?: UserMetricsData;
  message?: string;
  error?: string;
}

export interface MetricsSummary {
  totalWorkouts: number;
  totalDistance: number;
  totalDuration: number;
  averageHeartRate: number;
  weeklyProgress: number;
}

export interface MetricsSummaryResult {
  success: boolean;
  summary?: MetricsSummary;
  error?: string;
}

class UserMetricsService {
  /**
   * Récupérer les métriques d'un utilisateur
   */
  async getMetrics(userId: string): Promise<UserMetricsResult> {
    try {
      const response = await apiService.get<ApiUserMetrics>(`/users/${userId}/metrics`);
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
   * Créer ou mettre à jour les métriques utilisateur
   */
  async updateMetrics(userId: string, metricsData: Partial<UserMetricsData>): Promise<UserMetricsResult> {
    try {
      // Convertir les données du format frontend vers le format API
      const apiData: ApiUserMetrics = {};

      if (metricsData.height) apiData.height = parseFloat(metricsData.height);
      if (metricsData.weight) apiData.weight = parseFloat(metricsData.weight);
      if (metricsData.weeklyVolume) apiData.weekly_volume = parseFloat(metricsData.weeklyVolume);
      if (metricsData.primaryGoal) apiData.primary_goal = metricsData.primaryGoal;
      if (metricsData.availableDays) apiData.available_days = parseInt(metricsData.availableDays, 10);
      if (metricsData.preferredTrainingTime) apiData.preferred_training_time = metricsData.preferredTrainingTime;
      if (metricsData.equipment) apiData.equipment = metricsData.equipment;
      if (metricsData.medicalConditions) apiData.medical_conditions = metricsData.medicalConditions;
      if (metricsData.ftp) apiData.ftp = parseFloat(metricsData.ftp);
      if (metricsData.lthr) apiData.lthr = parseInt(metricsData.lthr, 10);
      if (metricsData.maxHr) apiData.max_hr = parseInt(metricsData.maxHr, 10);
      if (metricsData.restHr) apiData.rest_hr = parseInt(metricsData.restHr, 10);
      if (metricsData.vo2Max) apiData.vo2_max = parseFloat(metricsData.vo2Max);

      const response = await apiService.put<{ metrics: ApiUserMetrics; message: string }>(
        `/users/${userId}/metrics`,
        apiData
      );

      return {
        success: true,
        metrics: this.convertApiToFrontend(response.metrics),
        message: response.message,
      };
    } catch (error: any) {
      return {
        success: false,
        error: error.message,
      };
    }
  }

  /**
   * Récupérer un résumé des métriques utilisateur
   */
  async getMetricsSummary(userId: string): Promise<MetricsSummaryResult> {
    try {
      const response = await apiService.get<MetricsSummary>(`/users/${userId}/metrics/summary`);

      return {
        success: true,
        summary: response,
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
  convertApiToFrontend(apiMetrics: ApiUserMetrics | undefined): UserMetricsData {
    if (!apiMetrics) {
      return {
        height: '',
        weight: '',
        weeklyVolume: '',
        primaryGoal: '',
        availableDays: '',
        preferredTrainingTime: '',
        equipment: '',
        medicalConditions: '',
        ftp: '',
        lthr: '',
        maxHr: '',
        restHr: '',
        vo2Max: '',
      };
    }

    return {
      height: apiMetrics.height ? apiMetrics.height.toString() : '',
      weight: apiMetrics.weight ? apiMetrics.weight.toString() : '',
      weeklyVolume: apiMetrics.weekly_volume ? apiMetrics.weekly_volume.toString() : '',
      primaryGoal: apiMetrics.primary_goal || '',
      availableDays: apiMetrics.available_days ? apiMetrics.available_days.toString() : '',
      preferredTrainingTime: apiMetrics.preferred_training_time || '',
      equipment: apiMetrics.equipment || '',
      medicalConditions: apiMetrics.medical_conditions || '',
      ftp: apiMetrics.ftp ? apiMetrics.ftp.toString() : '',
      lthr: apiMetrics.lthr ? apiMetrics.lthr.toString() : '',
      maxHr: apiMetrics.max_hr ? apiMetrics.max_hr.toString() : '',
      restHr: apiMetrics.rest_hr ? apiMetrics.rest_hr.toString() : '',
      vo2Max: apiMetrics.vo2_max ? apiMetrics.vo2_max.toString() : '',
    };
  }
}

export const userMetricsService = new UserMetricsService();
export default userMetricsService;
